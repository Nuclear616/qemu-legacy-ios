import Foundation

/// Persists a bookmark to the user's selected IPSW so Files-provider URLs
/// survive app relaunches without copying multi-gigabyte firmware into the app.
enum FirmwareSelectionStore {
    private static let bookmarkKey = "selectedIPSWBookmark"

    static func save(_ url: URL) throws {
        let bookmark = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
    }

    static func restore() -> URL? {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            guard FileManager.default.fileExists(atPath: url.path) else {
                UserDefaults.standard.removeObject(forKey: bookmarkKey)
                return nil
            }
            if isStale {
                try save(url)
            }
            return url
        } catch {
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
            return nil
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }
}
