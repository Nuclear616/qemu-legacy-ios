import Foundation
import UIKit

/// Small Project Astra adapter for Husk's built-in StikJIT helper.
/// The helper runs the bundled husk-jit.js script against this process.
enum JITBootstrap {
    private static let csDebugged: UInt32 = 0x10000000

    @_silgen_name("csops")
    private static func csops(_ pid: Int32, _ operation: Int32,
                              _ address: UnsafeMutableRawPointer?, _ size: Int) -> Int32

    static var debuggedFlag: Bool {
        var flags: UInt32 = 0
        let result = withUnsafeMutableBytes(of: &flags) { bytes in
            csops(getpid(), 0, bytes.baseAddress, bytes.count)
        }
        return result == 0 && (flags & csDebugged) != 0
    }

    static var ready: Bool { debuggedFlag }

    static var isStikDebugInstalled: Bool {
        URL(string: "stikjit://").map(UIApplication.shared.canOpenURL) ?? false
    }

    static var isInstalledWithTrollStore: Bool {
        let container = Bundle.main.bundleURL.deletingLastPathComponent()
        return ["_TrollStore", "_TrollStoreLite"].contains {
            FileManager.default.fileExists(atPath: container.appendingPathComponent($0).path)
        }
    }

    static var isTrollStoreInstalled: Bool { isInstalledWithTrollStore }
    static var isJailbroken: Bool { FileManager.default.fileExists(atPath: "/var/jb") }

    static var scriptBase64: String? {
        guard let url = Bundle.main.url(forResource: "husk-jit", withExtension: "js"),
              let script = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return Data(script.utf8).base64EncodedString()
    }

    @MainActor
    static func requestAttach() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier,
              let script = scriptBase64,
              var components = URLComponents(string: "stikjit://enable-jit") else { return false }
        components.queryItems = [
            URLQueryItem(name: "bundle-id", value: bundleID),
            URLQueryItem(name: "pid", value: String(getpid())),
            URLQueryItem(name: "script-data", value: script)
        ]
        guard let url = components.url else { return false }
        UIApplication.shared.open(url)
        return true
    }

    @MainActor
    static func requestTrollStoreAttach() -> Bool {
        guard isInstalledWithTrollStore,
              let url = URL(string: "apple-magnifier://enable-jit?bundle-id=\(Bundle.main.bundleIdentifier ?? "")") else {
            return false
        }
        UIApplication.shared.open(url)
        return true
    }
}
