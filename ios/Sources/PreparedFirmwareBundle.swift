import Foundation

struct QEMUBootConfiguration {
    let machine: String
    let arguments: [String]
    let overlayDirectory: URL
    let startupLog: [String]
}

enum PreparedFirmwareBundleError: LocalizedError {
    case inaccessibleFolder
    case missingKBoot
    case missingNAND
    case emptyNAND
    case unsafeSymlink(String)
    case invalidManifest
    case unsupportedDevice(String)
    case firmwareVersionMismatch(expected: String, actual: String)
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .inaccessibleFolder:
            return "The selected folder could not be accessed."
        case .missingKBoot:
            return "kboot.bin was not found at the top level of the selected folder."
        case .missingNAND:
            return "The nand folder was not found beside kboot.bin."
        case .emptyNAND:
            return "The nand folder contains no files."
        case .unsafeSymlink(let path):
            return "The firmware folder contains an unsupported symbolic link: \(path)"
        case .invalidManifest:
            return "The Astra firmware metadata file is invalid or incomplete."
        case .unsupportedDevice(let board):
            return "This prepared bundle targets \(board), not the iPhone 4 GSM / n90ap engine."
        case .firmwareVersionMismatch(let expected, let actual):
            return "The selected iOS version is \(expected), but this prepared bundle contains iOS \(actual)."
        case .copyFailed(let message):
            return message
        }
    }
}

private struct PreparedFirmwareMetadata: Decodable {
    let schemaVersion: Int
    let deviceIdentifier: String
    let board: String
    let machine: String
    let version: String
    let build: String

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case deviceIdentifier = "device_identifier"
        case board, machine, version, build
    }
}

enum PreparedFirmwareBundleStore {
    static func importBundle(from source: URL) throws -> URL {
        let didStart = source.startAccessingSecurityScopedResource()
        defer {
            if didStart { source.stopAccessingSecurityScopedResource() }
        }

        let manager = FileManager.default
        var isDirectory: ObjCBool = false
        guard manager.fileExists(atPath: source.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw PreparedFirmwareBundleError.inaccessibleFolder
        }
        try validate(source)

        let support = try manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let parent = support.appendingPathComponent("PreparedFirmware", isDirectory: true)
        try manager.createDirectory(at: parent, withIntermediateDirectories: true)

        let destination = parent.appendingPathComponent("n90ap-device", isDirectory: true)
        let staging = parent.appendingPathComponent(".n90ap-device-staging-\(UUID().uuidString)", isDirectory: true)
        let backup = parent.appendingPathComponent(".n90ap-device-backup-\(UUID().uuidString)", isDirectory: true)
        do {
            try manager.copyItem(at: source, to: staging)
            try validate(staging)
            let hadPreviousBundle = manager.fileExists(atPath: destination.path)
            if hadPreviousBundle { try manager.moveItem(at: destination, to: backup) }
            do {
                try manager.moveItem(at: staging, to: destination)
            } catch {
                if hadPreviousBundle { try? manager.moveItem(at: backup, to: destination) }
                throw error
            }
            if hadPreviousBundle { try? manager.removeItem(at: backup) }
            return destination
        } catch {
            try? manager.removeItem(at: staging)
            throw PreparedFirmwareBundleError.copyFailed(error.localizedDescription)
        }
    }

    static func restoreImportedBundle() -> URL? {
        let manager = FileManager.default
        guard let support = try? manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return nil }
        let bundle = support
            .appendingPathComponent("PreparedFirmware", isDirectory: true)
            .appendingPathComponent("n90ap-device", isDirectory: true)
        guard manager.fileExists(atPath: bundle.path) else { return nil }
        do {
            try validate(bundle)
            return bundle
        } catch {
            return nil
        }
    }

    static func makeBootConfiguration(bundleURL: URL, storageGiB: Int, expectedIOSVersion: String, installJailbreak: Bool = false) throws -> QEMUBootConfiguration {
        try validate(bundleURL)
        let manager = FileManager.default
        let overlay = bundleURL.appendingPathComponent("qemu-overlay", isDirectory: true)
        try manager.createDirectory(at: overlay, withIntermediateDirectories: true)
        var startupLog = ["Prepared firmware bundle validated", "Persistent filesystem overlay created"]
        if let metadata = try loadMetadata(in: bundleURL) {
            guard metadata.version == expectedIOSVersion else {
                throw PreparedFirmwareBundleError.firmwareVersionMismatch(expected: expectedIOSVersion, actual: metadata.version)
            }
            startupLog.append("Verified iPhone3,1 / n90ap iOS \(metadata.version) build \(metadata.build)")
        } else {
            startupLog.append("Legacy bundle has no Astra metadata; firmware version could not be verified")
        }
        if installJailbreak {
            startupLog.append("Jailbreak requested — no guest jailbreak installer is integrated, so it was skipped")
        } else {
            startupLog.append("Jailbreak installation disabled in settings")
        }

        let kboot = bundleURL.appendingPathComponent("kboot.bin").path
        let nand = bundleURL.appendingPathComponent("nand", isDirectory: true).path
        let arguments = [
            "-M", "iPhone-4,kboot=\(kboot),nand=\(nand),nand-overlay=\(overlay.path),nor-rw=\(overlay.appendingPathComponent("nor.bin").path)",
            "-display", "none",
            "-serial", "stdio"
        ]
        // The NAND geometry in a prepared bundle is authoritative. Resizing it
        // safely requires regenerating the NAND images, not changing a UI value.
        _ = storageGiB
        return QEMUBootConfiguration(machine: "iPhone-4 (n90ap)", arguments: arguments, overlayDirectory: overlay, startupLog: startupLog)
    }

    private static func validate(_ folder: URL) throws {
        let manager = FileManager.default
        let kbootURL = folder.appendingPathComponent("kboot.bin")
        guard (try? kbootURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]).isRegularFile) == true,
              (try? kbootURL.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true else {
            throw PreparedFirmwareBundleError.missingKBoot
        }

        let nand = folder.appendingPathComponent("nand", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard manager.fileExists(atPath: nand.path, isDirectory: &isDirectory), isDirectory.boolValue,
              (try? nand.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true else {
            throw PreparedFirmwareBundleError.missingNAND
        }

        let enumerator = manager.enumerator(at: nand, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey])
        var hasFile = false
        while let item = enumerator?.nextObject() as? URL {
            let values = try item.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            if values.isSymbolicLink == true { throw PreparedFirmwareBundleError.unsafeSymlink(item.lastPathComponent) }
            if values.isRegularFile == true { hasFile = true }
        }
        guard hasFile else { throw PreparedFirmwareBundleError.emptyNAND }
        if let metadata = try loadMetadata(in: folder) {
            guard metadata.schemaVersion == 1 else {
                throw PreparedFirmwareBundleError.invalidManifest
            }
            guard metadata.deviceIdentifier == "iPhone3,1",
                  metadata.board == "n90ap",
                  metadata.machine == "iPhone-4" else {
                throw PreparedFirmwareBundleError.unsupportedDevice(metadata.board)
            }
            guard !metadata.version.isEmpty, !metadata.build.isEmpty else {
                throw PreparedFirmwareBundleError.invalidManifest
            }
        }
    }

    private static func loadMetadata(in folder: URL) throws -> PreparedFirmwareMetadata? {
        let url = folder.appendingPathComponent("astra-firmware.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard (try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]).isRegularFile) == true,
              (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true else {
            throw PreparedFirmwareBundleError.invalidManifest
        }
        do {
            return try JSONDecoder().decode(PreparedFirmwareMetadata.self, from: Data(contentsOf: url))
        } catch {
            throw PreparedFirmwareBundleError.invalidManifest
        }
    }
}
