import SwiftUI
import Foundation

private struct IPSWDeviceResponse: Decodable {
    let identifier: String
    let firmwares: [IPSWFirmware]
}

private struct IPSWFirmware: Decodable, Identifiable {
    let identifier: String?
    let version: String
    let buildID: String
    let url: URL
    let filesize: Int64?
    let signed: Bool?

    var id: String { buildID }

    enum CodingKeys: String, CodingKey {
        case identifier, version, url, filesize, signed
        case buildID = "buildid"
    }
}

struct IPSWFirmwareBrowserView: View {
    let selectedVersion: String
    let onDownloaded: (URL, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var firmwares: [IPSWFirmware] = []
    @State private var selectedBuildID: String?
    @State private var isLoading = false
    @State private var isDownloading = false
    @State private var errorMessage: String?
    @State private var statusMessage = "Loading firmware catalog…"

    private let deviceIdentifier = "iPhone3,1"
    private let apiURL = URL(string: "https://api.ipsw.me/v4/device/iPhone3,1?type=ipsw")!

    private var selectedFirmware: IPSWFirmware? {
        firmwares.first { $0.buildID == selectedBuildID }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && firmwares.isEmpty {
                    ProgressView(statusMessage)
                } else if firmwares.isEmpty {
                    ContentUnavailableView(
                        "No firmware catalog",
                        systemImage: "wifi.exclamationmark",
                        description: Text(errorMessage ?? "Could not load IPSW.me.")
                    )
                } else {
                    List {
                        Section {
                            Text("Showing IPSW files for iPhone 4 GSM (iPhone3,1). Signing status comes from IPSW.me and can change.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Section("Available firmware") {
                            ForEach(firmwares) { firmware in
                                Button {
                                    selectedBuildID = firmware.buildID
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: selectedBuildID == firmware.buildID ? "largecircle.fill.circle" : "circle")
                                            .foregroundStyle(selectedBuildID == firmware.buildID ? Color.accentColor : Color.secondary)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("iOS \(firmware.version)")
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text("Build \(firmware.buildID)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            HStack(spacing: 8) {
                                                if let signed = firmware.signed {
                                                    Label(signed ? "Signed" : "Unsigned", systemImage: signed ? "checkmark.seal" : "exclamationmark.triangle")
                                                        .foregroundStyle(signed ? Color.green : Color.orange)
                                                } else {
                                                    Text("Signing status unknown")
                                                }
                                                if let bytes = firmware.filesize {
                                                    Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                                                }
                                            }
                                            .font(.caption2)
                                        }
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Download IPSW")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadFirmware() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading || isDownloading)
                    .accessibilityLabel("Refresh firmware list")
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    if isDownloading {
                        ProgressView(statusMessage)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button {
                        Task { await downloadSelectedFirmware() }
                    } label: {
                        Label(isDownloading ? "Downloading…" : "Download Selected IPSW", systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedFirmware == nil || isDownloading)
                }
                .padding()
                .background(.bar)
            }
            .task {
                await loadFirmware()
            }
        }
    }

    @MainActor
    private func loadFirmware() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        statusMessage = "Contacting IPSW.me…"
        defer { isLoading = false }

        do {
            var request = URLRequest(url: apiURL)
            request.timeoutInterval = 30
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw FirmwareError.badResponse
            }
            let decoded = try JSONDecoder().decode(IPSWDeviceResponse.self, from: data)
            guard decoded.identifier == deviceIdentifier else {
                throw FirmwareError.wrongDevice
            }
            firmwares = decoded.firmwares.sorted { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
            if let match = firmwares.first(where: { $0.version == selectedVersion }) {
                selectedBuildID = match.buildID
            } else {
                selectedBuildID = firmwares.first?.buildID
            }
            statusMessage = "Loaded \(firmwares.count) firmware entries."
            if firmwares.isEmpty {
                errorMessage = "IPSW.me returned no IPSW files for this device."
            }
        } catch {
            errorMessage = "Could not load firmware: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func downloadSelectedFirmware() async {
        guard let firmware = selectedFirmware else { return }
        guard firmware.url.scheme?.lowercased() == "https",
              firmware.url.pathExtension.lowercased() == "ipsw" else {
            errorMessage = "IPSW.me returned an unexpected download URL."
            return
        }

        isDownloading = true
        errorMessage = nil
        statusMessage = "Downloading iOS \(firmware.version)…"
        defer { isDownloading = false }

        do {
            let (temporaryURL, response) = try await URLSession.shared.download(from: firmware.url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw FirmwareError.downloadFailed
            }
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destination = documents.appendingPathComponent("iPhone3,1_iOS_\(firmware.version)_\(firmware.buildID).ipsw")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
            statusMessage = "Download complete."
            onDownloaded(destination, firmware.version)
            dismiss()
        } catch {
            errorMessage = "Download failed: \(error.localizedDescription)"
        }
    }
}

private enum FirmwareError: LocalizedError {
    case badResponse
    case wrongDevice
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .badResponse: return "IPSW.me returned an unsuccessful response."
        case .wrongDevice: return "The firmware catalog did not match iPhone3,1."
        case .downloadFailed: return "Apple's firmware server did not complete the download."
        }
    }
}
