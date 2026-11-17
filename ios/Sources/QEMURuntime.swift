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

@MainActor
final class QEMURuntime: ObservableObject {
    @Published private(set) var frame: CGImage?
    @Published private(set) var status = "QEMU runtime has not been started."
    @Published private(set) var hasAttemptedStart = false

    private var libraryHandle: UnsafeMutableRawPointer?
    private var frameFunction: QemuFrameFunction?
    private var touchFunction: QemuTouchFunction?
    private var didStart = false
    private var frameSerial: UInt64 = 0

    func start(configuration: QEMUBootConfiguration) {
        guard !didStart else {
            status = "QEMU can only be started once per app launch. Close and reopen Project Astra to start another VM."
            return
        }
        hasAttemptedStart = true

        guard let libraryURL = Bundle.main.privateFrameworksURL?
            .appendingPathComponent("libqemu-arm.dylib"),
              FileManager.default.fileExists(atPath: libraryURL.path) else {
            status = "QEMU engine is not bundled in this IPA yet. The app now has the runtime loader and display/input bridge, but the iOS ARM64 QEMU library still needs to be built and embedded."
            return
        }

        guard let handle = dlopen(libraryURL.path, RTLD_NOW | RTLD_LOCAL) else {
            let detail = dlerror().map { String(cString: $0) } ?? "unknown dynamic-loader error"
            status = "Could not load QEMU engine: \(detail)"
            return
        }
        libraryHandle = handle

        guard let mainSymbol = dlsym(handle, "qemu_ios_main"),
              let attachSymbol = dlsym(handle, "qemu_ios_ui_attach"),
              let frameSymbol = dlsym(handle, "qemu_ios_ui_frame"),
              let touchSymbol = dlsym(handle, "qemu_ios_ui_touch") else {
            status = "QEMU engine is missing one or more required iOS bridge symbols."
            dlclose(handle)
            libraryHandle = nil
            return
        }

        let qemuMain = unsafeBitCast(mainSymbol, to: QemuMainFunction.self)
        let attach = unsafeBitCast(attachSymbol, to: QemuAttachFunction.self)
        frameFunction = unsafeBitCast(frameSymbol, to: QemuFrameFunction.self)
        touchFunction = unsafeBitCast(touchSymbol, to: QemuTouchFunction.self)

        let callback: QemuFrameCallback = { opaque in
            guard let opaque else { return }
            let runtime = Unmanaged<QEMURuntime>.fromOpaque(opaque).takeUnretainedValue()
            DispatchQueue.main.async {
                runtime.refreshFrame()
            }
        }
        attach(callback, Unmanaged.passUnretained(self).toOpaque())

        didStart = true
        status = "Starting iPhone 4 QEMU machine…"
        DispatchQueue.global(qos: .userInitiated).async {
            let arguments = ["qemu-system-arm"] + configuration.arguments
            let allocated = arguments.map { strdup($0) }
            defer { allocated.forEach { if let value = $0 { free(value) } } }
            var argv: [UnsafeMutablePointer<CChar>?] = allocated
            let result = argv.withUnsafeMutableBufferPointer { buffer in
                qemuMain(Int32(buffer.count), buffer.baseAddress)
            }
            DispatchQueue.main.async {
                self.status = "QEMU stopped (exit code \(result)). Restart Project Astra before starting another VM."
            }
        }
    }

    func sendTouch(phase: Int32, x: Double, y: Double) {
        touchFunction?(0, phase, min(1, max(0, x)), min(1, max(0, y)))
    }

    private func refreshFrame() {
        guard let frameFunction else { return }
        var pixels: UnsafeRawPointer?
        var width: Int32 = 0
        var height: Int32 = 0
        guard frameFunction(&pixels, &width, &height, &frameSerial),
              let pixels, width > 0, height > 0 else { return }

        let byteCount = Int(width) * Int(height) * 4
        let data = Data(bytes: pixels, count: byteCount)
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
        status = "QEMU is running · \(width) × \(height)"
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
                    Text(runtime.status)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
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
