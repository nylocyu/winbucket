import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BucketView: View {
    enum Tab { case active, trash }

    @ObservedObject var store: WinStore
    @State private var note: String = ""
    @State private var link: String = ""
    @State private var pendingFileURL: URL?
    @State private var selectedTab: Tab = .active

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let fileDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Win Bucket")
                    .font(.headline)
                Spacer()
                Button(action: toggleTab) {
                    Text(selectedTab == .active ? "Gelöscht" : "Zurück")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Button("Exportieren", action: exportZip)
                    .disabled(store.wins.isEmpty)
            }

            if selectedTab == .active {
                DropZoneView(pendingFileURL: $pendingFileURL)

                TextField("Notiz: was war's, warum wichtig?", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)

                TextField("Link (optional)", text: $link)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Spacer()
                    Button("Win speichern") {
                        addWin()
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(
                        note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && pendingFileURL == nil
                            && link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }

            Divider()

            switch selectedTab {
            case .active:
                if store.wins.isEmpty {
                    Text("Noch keine Wins gesammelt.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(store.wins) { win in
                                WinRowView(
                                    win: win,
                                    dateFormatter: Self.dateFormatter,
                                    actionIcon: "trash",
                                    aiAction: (TextImprover.isAvailable && !win.note.isEmpty) ? { await improveNote(for: win) } : nil,
                                    onEdit: { newNote, newLink in editWin(win, note: newNote, link: newLink) }
                                ) {
                                    store.moveToTrash(win)
                                }
                            }
                        }
                    }
                }
            case .trash:
                if store.trashedWins.isEmpty {
                    Text("Papierkorb ist leer.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(store.trashedWins) { win in
                                WinRowView(
                                    win: win,
                                    dateFormatter: Self.dateFormatter,
                                    actionIcon: "arrow.uturn.backward",
                                    subtitle: trashSubtitle(for: win)
                                ) {
                                    store.restore(win)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 320, height: 460)
    }

    private func toggleTab() {
        selectedTab = selectedTab == .active ? .trash : .active
    }

    private func trashSubtitle(for win: Win) -> String {
        let days = WinStore.daysRemaining(for: win) ?? 0
        return days <= 0 ? "Wird in Kürze endgültig gelöscht" : "Wird in \(days) Tag\(days == 1 ? "" : "en") endgültig gelöscht"
    }

    private func improveNote(for win: Win) async {
        guard let improved = try? await TextImprover.expand(note: win.note) else { return }
        store.updateNote(for: win, newNote: improved)
    }

    private func addWin() {
        store.addWin(note: note.trimmingCharacters(in: .whitespacesAndNewlines), sourceFileURL: pendingFileURL, link: normalizedLink(link))
        note = ""
        link = ""
        pendingFileURL = nil
    }

    private func editWin(_ win: Win, note: String, link: String) {
        store.updateContent(for: win, note: note.trimmingCharacters(in: .whitespacesAndNewlines), link: normalizedLink(link))
    }

    private func normalizedLink(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { return trimmed }
        return "https://\(trimmed)"
    }

    private func exportZip() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "WinBucket-Export-\(Self.fileDateFormatter.string(from: Date())).zip"
        panel.allowedContentTypes = [UTType(filenameExtension: "zip") ?? .archive]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? BucketExporter.exportZip(wins: store.wins, store: store, to: url)
        }
    }
}
