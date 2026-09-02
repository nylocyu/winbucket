import SwiftUI

struct WinRowView: View {
    let win: Win
    let dateFormatter: DateFormatter
    let actionIcon: String
    var subtitle: String? = nil
    var aiAction: (() async -> Void)? = nil
    var onEdit: ((String, String) -> Void)? = nil
    let onAction: () -> Void

    @State private var isHovering = false
    @State private var isImproving = false
    @State private var isEditing = false
    @State private var editedNote = ""
    @State private var editedLink = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if isEditing {
                editForm
            } else {
                display
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
        .onHover { isHovering = $0 }
    }

    @ViewBuilder
    private var display: some View {
        HStack {
            Text(dateFormatter.string(from: win.timestamp))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            if isHovering, let aiAction {
                Button {
                    guard !isImproving else { return }
                    Task {
                        isImproving = true
                        await aiAction()
                        isImproving = false
                    }
                } label: {
                    if isImproving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "sparkles")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(isImproving)
            }
            if isHovering, onEdit != nil {
                Button {
                    editedNote = win.note
                    editedLink = win.link ?? ""
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            if isHovering {
                Button(action: onAction) {
                    Image(systemName: actionIcon)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        if !win.note.isEmpty {
            Text(win.note)
                .font(.callout)
        }
        if let link = win.link, let url = URL(string: link) {
            Link(destination: url) {
                Label(link, systemImage: "link")
                    .font(.caption2)
                    .lineLimit(1)
            }
            .foregroundStyle(.secondary)
        }
        if let originalFilename = win.originalFilename {
            Label(originalFilename, systemImage: "paperclip")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        if let subtitle {
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var editForm: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Note", text: $editedNote, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .font(.callout)
            TextField("Link (optional)", text: $editedLink)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
            HStack {
                Spacer()
                Button("Cancel") {
                    isEditing = false
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)

                Button("Save") {
                    onEdit?(editedNote, editedLink)
                    isEditing = false
                }
                .font(.caption)
            }
        }
    }
}
