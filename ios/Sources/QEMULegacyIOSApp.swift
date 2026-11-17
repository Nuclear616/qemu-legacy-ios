import SwiftUI
import UniformTypeIdentifiers

@main
struct QEMULegacyIOSApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    @State private var firmwareURL: URL?
    @State private var showingImporter = false
    @State private var status = "Emulator engine not connected"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "iphone.gen3").font(.system(size: 58)).foregroundStyle(.secondary)
                Text("iPhone 4 · GSM").font(.title2.bold())
                Text("A4 · n90ap · iOS 7.1.2").font(.subheadline).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Guest firmware", systemImage: "doc.zipper").font(.headline)
                    Text(firmwareURL?.lastPathComponent ?? "No firmware selected").font(.footnote).foregroundStyle(.secondary).lineLimit(2)
                    Button("Choose IPSW") { showingImporter = true }.buttonStyle(.bordered)
                }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                Text(status).font(.footnote).foregroundStyle(.orange).frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    status = "Boot unavailable: A4 machine integration is not wired into this app yet."
                } label: {
                    Label("Start emulation", systemImage: "power").frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).disabled(firmwareURL == nil)
                Spacer()
                Text("Experimental front end. Firmware is not included.").font(.caption2).foregroundStyle(.secondary)
            }.padding().navigationTitle("QEMU Legacy iOS")
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [UTType(filenameExtension: "ipsw") ?? .data], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    firmwareURL = urls.first
                    status = "Firmware selected. Emulator engine integration pending."
                case .failure(let error): status = "Could not open firmware: \(error.localizedDescription)"
                }
            }
        }
    }
}
