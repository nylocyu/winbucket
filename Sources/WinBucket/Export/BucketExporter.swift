import Foundation

enum ExportError: Error {
    case zipFailed
}

enum BucketExporter {
    @MainActor
    static func exportZip(wins: [Win], store: WinStore, to destinationZipURL: URL) throws {
        let fm = FileManager.default

        let dateStamp: String = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()

        let tempDir = fm.temporaryDirectory.appendingPathComponent("WinBucket-Export-\(dateStamp)", isDirectory: true)
        let attachmentsExportDir = tempDir.appendingPathComponent("Attachments", isDirectory: true)
        try? fm.removeItem(at: tempDir)
        try fm.createDirectory(at: attachmentsExportDir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var usedNames = Set<String>()
        var lines = ["# Win Bucket", ""]

        for win in wins.sorted(by: { $0.timestamp < $1.timestamp }) {
            lines.append("## \(formatter.string(from: win.timestamp))")
            if !win.note.isEmpty {
                lines.append(win.note)
            }
            if let sourceURL = store.attachmentURL(for: win), let originalName = win.originalFilename {
                let uniqueName = uniqueFilename(originalName, used: &usedNames)
                try? fm.copyItem(at: sourceURL, to: attachmentsExportDir.appendingPathComponent(uniqueName))
                lines.append("*Attachment: [\(originalName)](Attachments/\(uniqueName))*")
            }
            if let link = win.link {
                lines.append("*Link: [\(link)](\(link))*")
            }
            lines.append("")
        }

        let markdownURL = tempDir.appendingPathComponent("WinBucket.md")
        try lines.joined(separator: "\n").write(to: markdownURL, atomically: true, encoding: .utf8)

        try zip(directory: tempDir, to: destinationZipURL)
        try? fm.removeItem(at: tempDir)
    }

    private static func uniqueFilename(_ name: String, used: inout Set<String>) -> String {
        guard used.contains(name) else {
            used.insert(name)
            return name
        }
        let ext = (name as NSString).pathExtension
        let base = (name as NSString).deletingPathExtension
        var index = 2
        var candidate = "\(base)-\(index).\(ext)"
        while used.contains(candidate) {
            index += 1
            candidate = "\(base)-\(index).\(ext)"
        }
        used.insert(candidate)
        return candidate
    }

    private static func zip(directory: URL, to destination: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--norsrc", "--keepParent", directory.path, destination.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw ExportError.zipFailed }
    }
}
