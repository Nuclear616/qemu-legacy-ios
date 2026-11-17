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
        case .copyFailed(let message):
            return message
        }
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
        if manager.fileExists(atPath: destination.path) {
            try manager.removeItem(at: destination)
        }
        do {
            try manager.copyItem(at: source, to: destination)
            try validate(destination)
            return destination
        } catch {
            if manager.fileExists(atPath: destination.path) {
                try? manager.removeItem(at: destination)
            }
            throw PreparedFirmwareBundleError.copyFailed(error.localizedDescription)
        }
    }

    static func makeBootConfiguration(bundleURL: URL, storageGiB: Int, installJailbreak: Bool = false) throws -> QEMUBootConfiguration {
        try validate(bundleURL)
        let manager = FileManager.default
        let overlay = bundleURL.appendingPathComponent("qemu-overlay", isDirectory: true)
        try manager.createDirectory(at: overlay, withIntermediateDirectories: true)
        var startupLog = ["Prepared firmware bundle validated", "Persistent filesystem overlay created"]
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
        guard manager.fileExists(atPath: folder.appendingPathComponent("kboot.bin").path) else {
            throw PreparedFirmwareBundleError.missingKBoot
        }

        let nand = folder.appendingPathComponent("nand", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard manager.fileExists(atPath: nand.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw PreparedFirmwareBundleError.missingNAND
        }

        let enumerator = manager.enumerator(at: nand, includingPropertiesForKeys: [.isRegularFileKey])
        var hasFile = false
        while let item = enumerator?.nextObject() as? URL {
            if (try? item.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                hasFile = true
                break
            }
        }
        guard hasFile else { throw PreparedFirmwareBundleError.emptyNAND }
    }
}
