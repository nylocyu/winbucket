import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let dropView: StatusItemDropView
    private let popover = NSPopover()
    private let store: WinStore

    init(store: WinStore) {
        self.store = store
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let thickness = NSStatusBar.system.thickness
        dropView = StatusItemDropView(frame: NSRect(x: 0, y: 0, width: thickness, height: thickness))
        super.init()

        statusItem.view = dropView
        dropView.onClick = { [weak self] in self?.togglePopover() }
        dropView.onRightClick = { [weak self] event in self?.showSettingsMenu(with: event) }
        dropView.onHoverOpen = { [weak self] in self?.openPopover() }
        dropView.onDirectDrop = { [weak self] url in
            guard let self else { return }
            store.addWin(note: "", sourceFileURL: url)
            self.openPopover()
        }

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: BucketView(store: store))
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        guard !popover.isShown else { return }
        popover.show(relativeTo: dropView.bounds, of: dropView, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    // MARK: - Settings menu

    private func showSettingsMenu(with event: NSEvent) {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Ordner öffnen", action: #selector(openFolder), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let changeItem = NSMenuItem(title: "Speicherort ändern…", action: #selector(changeLocation), keyEquivalent: "")
        changeItem.target = self
        menu.addItem(changeItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Beim Login starten", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Beenden", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        NSMenu.popUpContextMenu(menu, with: event, for: dropView)
    }

    @objc private func openFolder() {
        NSWorkspace.shared.open(store.rootURL)
    }

    @objc private func changeLocation() {
        let panel = NSOpenPanel()
        panel.title = "Neuer Speicherort"
        panel.message = "Wähle einen Ordner, in den \"Win Bucket\" verschoben wird."
        panel.prompt = "Verschieben"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let chosenParent = panel.url else { return }
        let newRoot = chosenParent.appendingPathComponent("Win Bucket", isDirectory: true)
        let oldRoot = store.rootURL

        guard !FileManager.default.fileExists(atPath: newRoot.path) else {
            let alert = NSAlert()
            alert.messageText = "Ordner existiert bereits"
            alert.informativeText = "In \"\(chosenParent.lastPathComponent)\" gibt es bereits einen \"Win Bucket\"-Ordner. Bitte einen anderen Zielordner wählen."
            alert.runModal()
            return
        }

        do {
            try FileManager.default.moveItem(at: oldRoot, to: newRoot)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Verschieben fehlgeschlagen"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            return
        }

        BucketLocation.setRoot(newRoot)
        store.relocate(to: newRoot)
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
