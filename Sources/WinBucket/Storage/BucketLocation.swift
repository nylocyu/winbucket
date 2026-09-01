import AppKit

// Asks once (first launch) where the "Win Bucket" folder should live, then
// remembers the choice. Can be changed later via the status item's right-click menu.
@MainActor
enum BucketLocation {
    private static let defaultsKey = "WinBucketRootPath"

    static var rootURL: URL {
        if let path = UserDefaults.standard.string(forKey: defaultsKey) {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return promptForLocation()
    }

    static func setRoot(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: defaultsKey)
    }

    private static func promptForLocation() -> URL {
        let panel = NSOpenPanel()
        panel.title = "Win Bucket Speicherort"
        panel.message = "Wähle einen Ordner, in dem \"Win Bucket\" angelegt wird."
        panel.prompt = "Auswählen"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        let fallback = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Win Bucket", isDirectory: true)

        let chosenParent = panel.runModal() == .OK ? panel.url : nil
        let root = chosenParent?.appendingPathComponent("Win Bucket", isDirectory: true) ?? fallback

        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        UserDefaults.standard.set(root.path, forKey: defaultsKey)
        return root
    }
}
