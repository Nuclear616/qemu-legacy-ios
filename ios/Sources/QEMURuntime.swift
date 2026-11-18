import SwiftUI
import Combine
import CoreGraphics
import Darwin

private typealias QemuFrameCallback = @convention(c) (UnsafeMutableRawPointer?) -> Void
private typealias QemuMainFunction = @convention(c) (
    Int32,
    UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32
private typealias QemuAttachFunction = @convention(c) (QemuFrameCallback?, UnsafeMutableRawPointer?) -> Void
private typealias QemuFrameFunction = @convention(c) (
    UnsafeMutablePointer<UnsafeRawPointer?>,
    UnsafeMutablePointer<Int32>,
    UnsafeMutablePointer<Int32>,
    UnsafeMutablePointer<UInt64>
) -> Bool
private typealias QemuTouchFunction = @convention(c) (Int32, Int32, Double, Double) -> Void
private typealias QemuButtonFunction = @convention(c) (Int32, Bool) -> Void
private typealias QemuStatusFunction = @convention(c) () -> Bool

// The C bridge's ring-buffer pointer is valid for only a few guest frames.
// Copy it on the QEMU callback thread before handing work to the main queue.
private final class QEMUFrameCallbackState {
    private let frameFunction: QemuFrameFunction
    private var serial: UInt64 = 0
    private let deliver: @MainActor (Data, Int32, Int32) -> Void

    init(frameFunction: QemuFrameFunction, deliver: @escaping @MainActor (Data, Int32, Int32) -> Void) {
        self.frameFunction = frameFunction
        self.deliver = deliver
    }

    func captureLatestFrame() {
        var pixels: UnsafeRawPointer?
        var width: Int32 = 0
        var height: Int32 = 0
        guard frameFunction(&pixels, &width, &height, &serial),
              let pixels, width > 0, height > 0 else { return }
        let byteCount = Int(width) * Int(height) * 4
        guard byteCount > 0, byteCount <= 256 * 1024 * 1024 else { return }
        let copiedPixels = Data(bytes: pixels, count: byteCount)
        DispatchQueue.main.async { [deliver] in
            deliver(copiedPixels, width, height)
        }
    }
}

@MainActor
final class QEMURuntime: ObservableObject {
    @Published private(set) var frame: CGImage?
    @Published private(set) var status = "QEMU runtime has not been started."
    @Published private(set) var hasAttemptedStart = false
    @Published private(set) var hasReceivedFrame = false
    @Published private(set) var bootStatus = "Waiting to start…"
    @Published private(set) var startupLog: [String] = []

    private var libraryHandle: UnsafeMutableRawPointer?
    private var frameFunction: QemuFrameFunction?
    private var touchFunction: QemuTouchFunction?
    private var buttonFunction: QemuButtonFunction?
    private var readyFunction: QemuStatusFunction?
    private var storageFailedFunction: QemuStatusFunction?
    private var guestShutdownFunction: QemuStatusFunction?
    private var healthTimer: DispatchSourceTimer?
    private var frameCallbackState: QEMUFrameCallbackState?
    private var didStart = false

    func start(configuration: QEMUBootConfiguration) {
        guard !didStart else {
            status = "QEMU can only be started once per app launch. Close and reopen Project Astra to start another VM."
            return
        }
        hasAttemptedStart = true
        hasReceivedFrame = false
        startupLog = configuration.startupLog
        bootStatus = "Loading the iOS ARM64 QEMU engine…"
        status = bootStatus

        guard let libraryURL = Bundle.main.privateFrameworksURL?
            .appendingPathComponent("libqemu-arm.dylib"),
              FileManager.default.fileExists(atPath: libraryURL.path) else {
            status = "QEMU engine is not bundled in this IPA yet. The app now has the runtime loader and display/input bridge, but the iOS ARM64 QEMU library still needs to be built and embedded."
            bootStatus = status
            return
        }

        guard let handle = dlopen(libraryURL.path, RTLD_NOW | RTLD_LOCAL) else {
            let detail = dlerror().map { String(cString: $0) } ?? "unknown dynamic-loader error"
            status = "Could not load QEMU engine: \(detail)"
            bootStatus = status
            return
        }
        libraryHandle = handle
        startupLog.append("iOS ARM64 QEMU engine loaded")
        bootStatus = "Connecting the virtual display and hardware controls…"
        status = bootStatus

        guard let mainSymbol = dlsym(handle, "qemu_ios_main"),
              let attachSymbol = dlsym(handle, "qemu_ios_ui_attach"),
              let frameSymbol = dlsym(handle, "qemu_ios_ui_frame"),
              let touchSymbol = dlsym(handle, "qemu_ios_ui_touch"),
              let buttonSymbol = dlsym(handle, "qemu_ios_ui_button"),
              let readySymbol = dlsym(handle, "qemu_ios_ui_ready"),
              let storageFailedSymbol = dlsym(handle, "qemu_ios_ui_storage_failed"),
              let guestShutdownSymbol = dlsym(handle, "qemu_ios_ui_guest_shutdown_confirmed") else {
            status = "QEMU engine is missing one or more required iOS bridge symbols."
            bootStatus = status
            dlclose(handle)
            libraryHandle = nil
            return
        }

        let qemuMain = unsafeBitCast(mainSymbol, to: QemuMainFunction.self)
        let attach = unsafeBitCast(attachSymbol, to: QemuAttachFunction.self)
        frameFunction = unsafeBitCast(frameSymbol, to: QemuFrameFunction.self)
        touchFunction = unsafeBitCast(touchSymbol, to: QemuTouchFunction.self)
        buttonFunction = unsafeBitCast(buttonSymbol, to: QemuButtonFunction.self)
        readyFunction = unsafeBitCast(readySymbol, to: QemuStatusFunction.self)
        storageFailedFunction = unsafeBitCast(storageFailedSymbol, to: QemuStatusFunction.self)
        guestShutdownFunction = unsafeBitCast(guestShutdownSymbol, to: QemuStatusFunction.self)

        guard let frameFunction else {
            status = "QEMU frame API is unavailable."
            bootStatus = status
            return
        }
        let frameState = QEMUFrameCallbackState(frameFunction: frameFunction) { [weak self] data, width, height in
            self?.refreshFrame(data: data, width: width, height: height)
        }
        frameCallbackState = frameState
        let callback: QemuFrameCallback = { opaque in
            guard let opaque else { return }
            let state = Unmanaged<QEMUFrameCallbackState>.fromOpaque(opaque).takeUnretainedValue()
            state.captureLatestFrame()
        }
        attach(callback, Unmanaged.passUnretained(frameState).toOpaque())
        startHealthPolling()

        didStart = true
        startupLog.append("Virtual display and hardware controls connected")
        startupLog.append("iPhone bootloader started")
        bootStatus = "Starting the virtual iPhone and bootloader…"
        status = bootStatus
        DispatchQueue.global(qos: .userInitiated).async {
            let arguments = ["qemu-system-arm"] + configuration.arguments
            let allocated = arguments.map { strdup($0) }
            defer { allocated.forEach { if let value = $0 { free(value) } } }
            var argv: [UnsafeMutablePointer<CChar>?] = allocated
            let result = argv.withUnsafeMutableBufferPointer { buffer in
                qemuMain(Int32(buffer.count), buffer.baseAddress)
            }
            DispatchQueue.main.async {
                self.healthTimer?.cancel()
                self.healthTimer = nil
                self.bootStatus = "QEMU stopped (exit code \(result))."
                self.status = "QEMU stopped (exit code \(result)). Restart Project Astra before starting another VM."
            }
        }
    }

    private func startHealthPolling() {
        healthTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + .milliseconds(250), repeating: .milliseconds(500))
        timer.setEventHandler { [weak self] in
            Task { @MainActor in self?.pollRuntimeHealth() }
        }
        healthTimer = timer
        timer.resume()
    }

    private func pollRuntimeHealth() {
        if storageFailedFunction?() == true {
            bootStatus = "Guest storage I/O failed."
            status = "QEMU reported a NAND/storage I/O failure. Stop testing this firmware bundle and check the import and NAND files."
            return
        }
        if guestShutdownFunction?() == true {
            bootStatus = "Guest shut down normally."
            status = "The emulated iPhone confirmed its power-off sequence."
            return
        }
        if readyFunction?() == true && !hasReceivedFrame {
            bootStatus = "QEMU initialized · waiting for the guest display"
            status = bootStatus
        }
    }

    func pressButton(_ button: Int32) {
        guard let buttonFunction else { return }
        buttonFunction(button, true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.buttonFunction?(button, false)
        }
    }

    func sendTouch(phase: Int32, x: Double, y: Double) {
        touchFunction?(0, phase, min(1, max(0, x)), min(1, max(0, y)))
    }

    private func refreshFrame(data: Data, width: Int32, height: Int32) {
        guard width > 0, height > 0 else { return }
        let byteCount = Int(width) * Int(height) * 4
        guard data.count == byteCount else { return }

        // Keep the Apple boot splash until a genuinely lit guest frame arrives.
        if !hasReceivedFrame {
            let bytes = data.withUnsafeBytes { $0.bindMemory(to: UInt8.self) }
            var litSamples = 0
            for offset in stride(from: 0, to: byteCount, by: 256) {
                if bytes[offset] > 24 || bytes[offset + 1] > 24 || bytes[offset + 2] > 24 {
                    litSamples += 1
                }
            }
            if litSamples * 64 <= (Int(width) * Int(height)) / 100 {
                return
            }
        }
        guard let provider = CGDataProvider(data: data as CFData) else { return }
        let bitmapInfo = CGBitmapInfo(rawValue:
            CGImageAlphaInfo.premultipliedFirst.rawValue |
            CGBitmapInfo.byteOrder32Little.rawValue
        )
        frame = CGImage(
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: Int(width) * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
        hasReceivedFrame = true
        bootStatus = "Guest display active · iOS startup is in progress"
        status = "Guest display active · \(width) × \(height)"
    }
}


struct EmulatorPopupView: View {
    @ObservedObject var runtime: QEMURuntime

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Project Astra")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                hardwareButton("Power", systemImage: "power", id: 1)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            QEMUDisplayView(runtime: runtime)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 12)

            HStack(alignment: .center) {
                hardwareButton("Volume Up", systemImage: "speaker.plus.fill", id: 2)
                Spacer(minLength: 12)
                hardwareButton("Home", systemImage: "house.fill", id: 0)
                Spacer(minLength: 12)
                hardwareButton("Volume Down", systemImage: "speaker.minus.fill", id: 3)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private func hardwareButton(_ title: String, systemImage: String, id: Int32) -> some View {
        Button {
            runtime.pressButton(id)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .frame(width: 54, height: 54)
                .background(.thinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(.secondary.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct QEMUDisplayView: View {
    @ObservedObject var runtime: QEMURuntime
    @State private var isTouching = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                if let frame = runtime.frame {
                    Image(decorative: frame, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 18) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 68, weight: .regular))
                            .foregroundStyle(.white)
                        ProgressView()
                            .tint(.white)
                        Text(runtime.bootStatus)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(Array(runtime.startupLog.enumerated()), id: \.offset) { entry in
                                Text("• " + entry.element)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.65))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.horizontal, 22)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = Double(value.location.x / max(geometry.size.width, 1))
                        let y = Double(value.location.y / max(geometry.size.height, 1))
                        runtime.sendTouch(phase: isTouching ? 1 : 0, x: x, y: y)
                        isTouching = true
                    }
                    .onEnded { value in
                        let x = Double(value.location.x / max(geometry.size.width, 1))
                        let y = Double(value.location.y / max(geometry.size.height, 1))
                        runtime.sendTouch(phase: 2, x: x, y: y)
                        isTouching = false
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityLabel("Emulated iPhone display")
    }
}
