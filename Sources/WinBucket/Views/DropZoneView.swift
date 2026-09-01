import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Binding var pendingFileURL: URL?
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: pendingFileURL == nil ? "tray.and.arrow.down" : "checkmark.circle")
                .font(.system(size: 22))
            Text(pendingFileURL?.lastPathComponent ?? "Datei, Screenshot oder Ordner hierher ziehen")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.4))
        )
        .background(isTargeted ? Color.accentColor.opacity(0.08) : .clear)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url {
                    DispatchQueue.main.async { pendingFileURL = url }
                }
            }
            return true
        }
    }
}
