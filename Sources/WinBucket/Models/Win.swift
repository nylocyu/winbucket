import Foundation

struct Win: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    var note: String
    var attachmentFilename: String?
    var originalFilename: String?
    var deletedAt: Date?
    var link: String?

    init(note: String, attachmentFilename: String? = nil, originalFilename: String? = nil, link: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.note = note
        self.attachmentFilename = attachmentFilename
        self.originalFilename = originalFilename
        self.deletedAt = nil
        self.link = link
    }
}
