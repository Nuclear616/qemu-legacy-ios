import Foundation

/// Project Astra logging adapter for the built-in StikJIT coordinator.
enum AstraLog {
    static func log(_ category: String, _ message: String) {
        NSLog("[ProjectAstra:%@] %@", category, message)
    }
}
