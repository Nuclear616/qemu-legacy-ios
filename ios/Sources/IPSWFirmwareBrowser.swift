import SwiftUI
import Foundation\nimport CryptoKit

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
    let signed: Bool?\n    let sha1sum: String?

    var id: String { buildID }

    enum CodingKeys: String, CodingKey {
        case identifier, version, url, filesize, signed, sha1sum
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
    @State private var downloadedBytes: Int64 = 0
    @State private var totalDownloadBytes: Int64 = 0
    @State private var downloadFraction: Double = 0
    @State private var estimatedSecondsRemaining: Double?

    let deviceIdentifier: String

    private var apiURL: URL {
        URL(string: "https://api.ipsw.me/v4/device/\(deviceIdentifier)?type=ipsw")!
    }

    private var deviceDisplayName: String {
        switch deviceIdentifier {
        case "iPhone1,1": return "iPhone 2G"\n        case "iPhone1,2": return "iPhone 3G"
        case "iPhone4,1": return "iPhone 4S"
        default: return "iPhone 4 GSM"
        }
    }

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
                            Text("Showing IPSW files for \(deviceDisplayName) (\(deviceIdentifier)). Signing status comes from IPSW.me and can change.")
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
                        VStack(alignment: .leading, spacing: 7) {
                            Text(statusMessage)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if totalDownloadBytes > 0 {
                                ProgressView(value: downloadFraction, total: 1)
                                    .progressViewStyle(.linear)
                                HStack {
                                    Text("\(Int(downloadFraction * 100))% • \(ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)) of \(ByteCountFormatter.string(fromByteCount: totalDownloadBytes, countStyle: .file))")
                                    Spacer()
                                    if let remaining = estimatedSecondsRemaining {
                                        Text(remainingTimeText(remaining))
                                    }
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            } else {
                                ProgressView()
                                Text(ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file) + " downloaded • waiting for file size")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
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


    private static func verifySHA1(file: URL, expected: String) throws {\n        let handle = try FileHandle(forReadingFrom: file)\n        defer { try? handle.close() }\n        var hasher = Insecure.SHA1()\n        while true {\n            let chunk = try handle.read(upToCount: 4 * 1024 * 1024) ?? Data()\n            if chunk.isEmpty { break }\n            hasher.update(data: chunk)\n        }\n        let actual = hasher.finalize().map { String(format: "%02x", $0) }.joined()\n        guard actual.caseInsensitiveCompare(expected) == .orderedSame else {\n            try? FileManager.default.removeItem(at: file)\n            throw FirmwareError.checksumMismatch\n        }\n    }\n\n    private func remainingTimeText(_ seconds: Double) -> String {
        let value = max(0, Int(seconds.rounded(.up)))
        if value < 60 { return "\(value)s left" }
        return "\(value / 60)m \(value % 60)s left"
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
                throw FirmwareError.wrongDevice(deviceIdentifier)
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
        downloadedBytes = 0
        totalDownloadBytes = firmware.filesize ?? 0
        downloadFraction = 0
        estimatedSecondsRemaining = nil
        statusMessage = "Downloading iOS \(firmware.version)…"
        defer { isDownloading = false }

        do {
            let downloader = IPSWDownloadDelegate(expectedBytes: firmware.filesize ?? 0) { written, expected, remaining in
                self.downloadedBytes = written
                if expected > 0 { self.totalDownloadBytes = expected }
                let denominator = expected > 0 ? expected : self.totalDownloadBytes
                self.downloadFraction = denominator > 0
                    ? min(1, Double(written) / Double(denominator))
                    : 0
                self.estimatedSecondsRemaining = remaining
            }
            let (temporaryURL, response) = try await downloader.download(from: firmware.url)
            guard (200..<300).contains(response.statusCode) else {
                throw FirmwareError.downloadFailed
            }
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destination = documents.appendingPathComponent("\(deviceIdentifier)_iOS_\(firmware.version)_\(firmware.buildID).ipsw")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
            downloadFraction = 1
            estimatedSecondsRemaining = 0
            statusMessage = "Download complete."
            onDownloaded(destination, firmware.version)
            dismiss()
        } catch {
            errorMessage = "Download failed: \(error.localizedDescription)"
        }
    }
}


private final class IPSWDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    typealias DownloadResult = (URL, HTTPURLResponse)

    private var continuation: CheckedContinuation<DownloadResult, Error>?
    private var session: URLSession?
    private let startedAt = Date()
    private let expectedBytes: Int64
    private let onProgress: @MainActor @Sendable (Int64, Int64, Double?) -> Void
    private var didFinish = false

    init(expectedBytes: Int64, onProgress: @escaping @MainActor @Sendable (Int64, Int64, Double?) -> Void) {
        self.expectedBytes = expectedBytes
        self.onProgress = onProgress
    }

    func download(from url: URL) async throws -> DownloadResult {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let configuration = URLSessionConfiguration.default
            configuration.waitsForConnectivity = true
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            self.session = session
            session.downloadTask(with: url).resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let expected = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : expectedBytes
        let elapsed = max(0.1, Date().timeIntervalSince(startedAt))
        let speed = Double(totalBytesWritten) / elapsed
        let remaining = expected > 0 && speed > 0
            ? Double(max(0, expected - totalBytesWritten)) / speed
            : nil
        Task { @MainActor [onProgress] in
            onProgress(totalBytesWritten, expected, remaining)
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let response = downloadTask.response as? HTTPURLResponse else {
            finish(.failure(FirmwareError.downloadFailed))
            return
        }
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("astra-\(UUID().uuidString).ipsw")
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            finish(.success((destination, response)))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            finish(.failure(error))
        } else if !didFinish {
            finish(.failure(FirmwareError.downloadFailed))
        }
    }

    private func finish(_ result: Result<DownloadResult, Error>) {
        guard !didFinish else { return }
        didFinish = true
        let continuation = self.continuation
        self.continuation = nil
        session?.finishTasksAndInvalidate()
        self.session = nil
        continuation?.resume(with: result)
    }
}

private enum FirmwareError: LocalizedError {
    case badResponse
    case wrongDevice(String)
    case downloadFailed\n    case missingChecksum\n    case checksumMismatch

    var errorDescription: String? {
        switch self {
        case .badResponse: return "IPSW.me returned an unsuccessful response."
        case .wrongDevice(let identifier): return "The firmware catalog did not match \(identifier)."
        case .downloadFailed: return "Apple's firmware server did not complete the download."\n        case .missingChecksum: return "IPSW.me did not provide a SHA-1 checksum, so the download cannot be verified."\n        case .checksumMismatch: return "The downloaded IPSW failed SHA-1 verification and was discarded."
        }
    }
}
