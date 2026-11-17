import Foundation

/// Minimal logging adapter for the upstream Husk JIT coordinator sources.
enum HuskLog {
    static func log(_ category: String, _ message: String) {
        NSLog("[ProjectAstra:%@] %@", category, message)
    }
}
