import Foundation

@MainActor
final class WinStore: ObservableObject {
    static let trashRetentionDays = 30

    @Published private var allWins: [Win] = []

    var wins: [Win] {
        allWins.filter { $0.deletedAt == nil }
    }

    var trashedWins: [Win] {
        allWins.filter { $0.deletedAt != nil }.sorted { $0.deletedAt! > $1.deletedAt! }
    }

    private(set) var rootURL: URL
    private var attachmentsDir: URL
    private var dataFile: URL

    init(rootURL: URL) {
        self.rootURL = rootURL
        attachmentsDir = rootURL.appendingPathComponent("Attachments", isDirectory: true)
        dataFile = rootURL.appendingPathComponent("wins.json")

        try? FileManager.default.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)
        load()
    }

    /// Repoints storage after the bucket folder has already been moved on disk.
    func relocate(to newRoot: URL) {
        rootURL = newRoot
        attachmentsDir = newRoot.appendingPathComponent("Attachments", isDirectory: true)
        dataFile = newRoot.appendingPathComponent("wins.json")
    }

    func addWin(note: String, sourceFileURL: URL?, link: String? = nil) {
        var attachmentFilename: String?
        var originalFilename: String?

        if let sourceFileURL {
            let ext = sourceFileURL.pathExtension
            let storedName = UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)")
            let destination = attachmentsDir.appendingPathComponent(storedName)
            if (try? FileManager.default.copyItem(at: sourceFileURL, to: destination)) != nil {
                attachmentFilename = storedName
                originalFilename = sourceFileURL.lastPathComponent
            }
        }

        allWins.insert(Win(note: note, attachmentFilename: attachmentFilename, originalFilename: originalFilename, link: link), at: 0)
        save()
    }

    func moveToTrash(_ win: Win) {
        guard let index = allWins.firstIndex(where: { $0.id == win.id }) else { return }
        allWins[index].deletedAt = Date()
        save()
    }

    func restore(_ win: Win) {
        guard let index = allWins.firstIndex(where: { $0.id == win.id }) else { return }
        allWins[index].deletedAt = nil
        save()
    }

    func updateNote(for win: Win, newNote: String) {
        guard let index = allWins.firstIndex(where: { $0.id == win.id }) else { return }
        allWins[index].note = newNote
        save()
    }

    func updateContent(for win: Win, note: String, link: String?) {
        guard let index = allWins.firstIndex(where: { $0.id == win.id }) else { return }
        allWins[index].note = note
        allWins[index].link = link
        save()
    }

    static func daysRemaining(for win: Win) -> Int? {
        guard let deletedAt = win.deletedAt else { return nil }
        let purgeDate = Calendar.current.date(byAdding: .day, value: trashRetentionDays, to: deletedAt) ?? deletedAt
        return max(Calendar.current.dateComponents([.day], from: Date(), to: purgeDate).day ?? 0, 0)
    }

    func attachmentURL(for win: Win) -> URL? {
        guard let name = win.attachmentFilename else { return nil }
        return attachmentsDir.appendingPathComponent(name)
    }

    private func load() {
        if let data = try? Data(contentsOf: dataFile) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            allWins = (try? decoder.decode([Win].self, from: data)) ?? []
        }
        purgeExpired()
    }

    private func purgeExpired() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -Self.trashRetentionDays, to: Date()) ?? .distantPast
        let expired = allWins.filter { ($0.deletedAt ?? .distantFuture) < cutoff }
        guard !expired.isEmpty else { return }

        for win in expired {
            if let name = win.attachmentFilename {
                try? FileManager.default.removeItem(at: attachmentsDir.appendingPathComponent(name))
            }
        }
        let expiredIDs = Set(expired.map(\.id))
        allWins.removeAll { expiredIDs.contains($0.id) }
        save()
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(allWins) else { return }
        try? data.write(to: dataFile, options: .atomic)
    }
}
