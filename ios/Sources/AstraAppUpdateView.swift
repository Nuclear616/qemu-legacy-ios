import CryptoKit
import Foundation
import SwiftUI

private struct AstraGitHubRelease: Decodable {
    struct Asset: Decodable {
        let name: String
        let browser_download_url: URL
        let size: Int
        let digest: String?
    }

    let tag_name: String
    let name: String
    let body: String?
    let html_url: URL
    let published_at: String?
    let assets: [Asset]
}

@MainActor
private final class AstraAppUpdateModel: ObservableObject {
    @Published private(set) var release: AstraGitHubRelease?
    @Published private(set) var downloadedIPAURL: URL?
    @Published private(set) var isChecking = false
    @Published private(set) var isDownloading = false
    @Published private(set) var message = "Check GitHub for a published Project Astra IPA."
    @Published private(set) var errorMessage: String?

    private let releasesURL = URL(string: "https://api.github.com/repos/Nuclear616/qemu-legacy-ios/releases?per_page=100")!
    private let ipaAssetName = "Project-Astra-unsigned.ipa"

    var installedVersion: String {
        Bundle.main.infoDictionary?["AstraAppVersion"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "Unknown"
    }

    var latestVersion: String? {
        guard let release else { return nil }
        if release.tag_name.hasPrefix("astra-v") {
            return release.tag_name.replacingOccurrences(of: "astra-v", with: "")
        }
        if release.tag_name.hasPrefix("ipa-build-") {
            return "Build #\(release.tag_name.replacingOccurrences(of: "ipa-build-", with: ""))"
        }
        return release.name
    }

    var updateAvailable: Bool {
        guard let release else { return false }
        if release.tag_name.hasPrefix("astra-v") {
            return release.tag_name.replacingOccurrences(of: "astra-v", with: "") != installedVersion
        }
        if release.tag_name.hasPrefix("ipa-build-") {
            let releaseBuild = release.tag_name.replacingOccurrences(of: "ipa-build-", with: "")
            let installedBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
            return releaseBuild != installedBuild
        }
        return false
    }

    func checkForUpdates() async {
        guard !isChecking else { return }
        isChecking = true
        errorMessage = nil
        message = "Checking Project Astra releases…"
        defer { isChecking = false }

        do {
            var request = URLRequest(url: releasesURL)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("Project-Astra-iOS-App", forHTTPHeaderField: "User-Agent")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw UpdateError.releaseLookupFailed
            }

            let releases = try JSONDecoder().decode([AstraGitHubRelease].self, from: data)
            guard let latest = releases
                .filter({ ($0.tag_name.hasPrefix("astra-v") || $0.tag_name.hasPrefix("ipa-build-")) && $0.assets.contains(where: { $0.name == ipaAssetName }) })
                .sorted(by: { ($0.published_at ?? "") > ($1.published_at ?? "") })
                .first else {
                release = nil
                message = "No Project Astra IPA release has been published yet."
                return
            }

            release = latest
            downloadedIPAURL = nil
            message = updateAvailable
                ? "A newer Project Astra release (\(latestVersion ?? "new")) is available."
                : "You're running the latest published Project Astra release."
        } catch {
            errorMessage = error.localizedDescription
            message = "Could not check for updates."
        }
    }

    func downloadLatestIPA() async {
        guard !isDownloading, let release,
              let asset = release.assets.first(where: { $0.name == ipaAssetName }) else { return }
        guard asset.browser_download_url.scheme == "https",
              asset.browser_download_url.host == "github.com" else {
            errorMessage = UpdateError.invalidDownloadURL.localizedDescription
            return
        }

        isDownloading = true
        errorMessage = nil
        message = "Downloading Project Astra IPA…"
        defer { isDownloading = false }

        do {
            let (temporaryURL, response) = try await URLSession.shared.download(from: asset.browser_download_url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw UpdateError.downloadFailed
            }

            let attributes = try FileManager.default.attributesOfItem(atPath: temporaryURL.path)
            let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
            guard fileSize > 4, asset.size <= 0 || fileSize == asset.size else {
                throw UpdateError.invalidIPA
            }

            let handle = try FileHandle(forReadingFrom: temporaryURL)
            let signature = try handle.read(upToCount: 4) ?? Data()
            try handle.close()
            guard signature.starts(with: [0x50, 0x4b]) else {
                throw UpdateError.invalidIPA
            }
            if let digest = asset.digest, digest.hasPrefix("sha256:") {
                let expected = String(digest.dropFirst("sha256:".count))
                let actual = try Self.sha256(of: temporaryURL)
                guard actual.caseInsensitiveCompare(expected) == .orderedSame else {
                    throw UpdateError.checksumMismatch
                }
            }

            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let updatesDirectory = documents.appendingPathComponent("Updates", isDirectory: true)
            try FileManager.default.createDirectory(at: updatesDirectory, withIntermediateDirectories: true)
            let safeVersion = (latestVersion ?? "latest").replacingOccurrences(of: "/", with: "-")
            let destination = updatesDirectory.appendingPathComponent("Project-Astra-\(safeVersion).ipa")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
            downloadedIPAURL = destination
            message = "Downloaded and checked the IPA archive. It still needs to be installed with a compatible signing tool."
        } catch {
            errorMessage = error.localizedDescription
            message = "The IPA download did not complete."
        }
    }

    private static func sha256(of fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private enum UpdateError: LocalizedError {
        case releaseLookupFailed
        case downloadFailed
        case invalidDownloadURL
        case invalidIPA

        var errorDescription: String? {
            switch self {
            case .releaseLookupFailed: return "GitHub did not return a valid releases response."
            case .downloadFailed: return "GitHub did not complete the IPA download."
            case .invalidDownloadURL: return "The release contains an unexpected download address."
            case .invalidIPA: return "The downloaded file does not match the published IPA asset."
            case .checksumMismatch: return "The downloaded IPA failed GitHub SHA-256 verification."
            }
        }
    }
}

struct AstraAppUpdateView: View {
    @StateObject private var model = AstraAppUpdateModel()

    var body: some View {
        Form {
            Section("Installed version") {
                LabeledContent("Project Astra", value: model.installedVersion)
                Text("Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("GitHub Releases") {
                if let release = model.release {
                    LabeledContent(release.tag_name.hasPrefix("ipa-build-") ? "Latest build" : "Latest version", value: model.latestVersion ?? release.tag_name)
                    if let published = release.published_at {
                        LabeledContent("Published", value: published.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: " UTC"))
                    }
                    if let notes = release.body, !notes.isEmpty {
                        Text(notes)
                            .font(.footnote)
                            .textSelection(.enabled)
                    }
                    Link(destination: release.html_url) {
                        Label("View release on GitHub", systemImage: "arrow.up.right.square")
                    }
                    if model.updateAvailable {
                        Button {
                            Task { await model.downloadLatestIPA() }
                        } label: {
                            Label(model.isDownloading ? "Downloading…" : "Download IPA update", systemImage: "arrow.down.circle")
                        }
                        .disabled(model.isDownloading)
                    } else {
                        Label("You're up to date", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Text(model.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task { await model.checkForUpdates() }
                } label: {
                    Label(model.isChecking ? "Checking…" : "Check for updates", systemImage: "arrow.clockwise")
                }
                .disabled(model.isChecking || model.isDownloading)
            }

            if let fileURL = model.downloadedIPAURL {
                Section("Downloaded update") {
                    ShareLink(item: fileURL) {
                        Label("Share or save IPA", systemImage: "square.and.arrow.up")
                    }
                    Text(fileURL.lastPathComponent)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Choose a compatible sideloading/signing app from the share sheet to install this unsigned IPA. Project Astra cannot install or replace itself directly.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text(model.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let error = model.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Status")
            }

            Section {
                Text("Updates are downloaded from this repository's GitHub Releases. Only Project Astra releases tagged astra-v… or ipa-build-… with the expected Project-Astra-unsigned.ipa asset are considered. Downloading does not install the update; iOS requires a compatible signing and installation method.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About updating")
            }
        }
        .navigationTitle("App Updates")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model.release == nil && model.errorMessage == nil {
                await model.checkForUpdates()
            }
        }
    }
}
