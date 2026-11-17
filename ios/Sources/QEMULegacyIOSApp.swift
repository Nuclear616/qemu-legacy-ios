import SwiftUI
import UniformTypeIdentifiers

@main
struct QEMULegacyIOSApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    @State private var firmwareURL: URL?
    @State private var showingImporter = false
    @State private var isStarting = false
    @State private var status = "Ready to configure the guest"
    @State private var showingEngineNotice = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer(minLength: 12)
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                VStack(spacing: 6) {
                    Text("iPhone 4 · GSM").font(.title2.bold())
                    Text("A4 · n90ap · iOS 7.1.2")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 18) {
                    Label("Wi-Fi", systemImage: "wifi")
                    Label("8 GiB NAND", systemImage: "internaldrive")
                    Label("512 MiB RAM", systemImage: "memorychip")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 10) {
                    Label("Guest firmware", systemImage: "doc.zipper")
                        .font(.headline)
                    Text(firmwareURL?.lastPathComponent ?? "No IPSW selected")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Choose iOS 7.1.2 IPSW", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    startEmulator()
                } label: {
                    Label(isStarting ? "Starting…" : "Start Emulator", systemImage: "power")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isStarting)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                    Text(status)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Spacer()
                Text("Experimental front end · Firmware is not included")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .navigationTitle("QEMU Legacy iOS")
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType(filenameExtension: "ipsw") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    firmwareURL = urls.first
                    status = firmwareURL == nil
                        ? "No firmware selected."
                        : "IPSW selected. The QEMU engine still needs to be integrated."
                case .failure(let error):
                    status = "Could not open firmware: \(error.localizedDescription)"
                }
            }
            .alert("Emulator engine not connected", isPresented: $showingEngineNotice) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The app UI and iPhone 4 device profile are present, but this IPA does not yet contain a runnable QEMU engine or A4 boot pipeline. Selecting an IPSW cannot start the guest yet.")
            }
        }
    }

    private func startEmulator() {
        guard firmwareURL != nil else {
            status = "Choose an iOS 7.1.2 IPSW first."
            showingImporter = true
            return
        }
        status = "Start requested. QEMU runtime is not bundled or connected yet."
        showingEngineNotice = true
    }
}
