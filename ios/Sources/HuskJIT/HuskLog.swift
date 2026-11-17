import Foundation

/// Minimal logging adapter for the Project Astra JIT coordinator sources.
enum AstraLog {
    static func log(_ category: String, _ message: String) {
        NSLog("[ProjectAstra:%@] %@", category, message)
    }
}
