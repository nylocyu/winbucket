import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let dropView: StatusItemDropView
    private let popover = NSPopover()
    private let store: WinStore
    private let reminderScheduler: ReminderScheduler

    private static let weekdayOptions: [(value: Int, name: String)] = [
        (2, "Montag"), (3, "Dienstag"), (4, "Mittwoch"), (5, "Donnerstag"),
        (6, "Freitag"), (7, "Samstag"), (1, "Sonntag")
    ]
    private static let hourOptions = Array(8...18)

    init(store: WinStore, reminderScheduler: ReminderScheduler) {
        self.store = store
        self.reminderScheduler = reminderScheduler
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
        reminderScheduler.onOpenBucket = { [weak self] in self?.openPopover() }

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

        let reminderMenu = NSMenu()

        let enabledItem = NSMenuItem(title: "Aktiviert", action: #selector(toggleReminderEnabled), keyEquivalent: "")
        enabledItem.target = self
        enabledItem.state = ReminderSettings.isEnabled ? .on : .off
        reminderMenu.addItem(enabledItem)

        reminderMenu.addItem(.separator())

        let weekdaySubmenu = NSMenu()
        for option in Self.weekdayOptions {
            let item = NSMenuItem(title: option.name, action: #selector(selectWeekday(_:)), keyEquivalent: "")
            item.target = self
            item.tag = option.value
            item.state = ReminderSettings.weekday == option.value ? .on : .off
            weekdaySubmenu.addItem(item)
        }
        let weekdayItem = NSMenuItem(title: "Wochentag", action: nil, keyEquivalent: "")
        weekdayItem.submenu = weekdaySubmenu
        reminderMenu.addItem(weekdayItem)

        let hourSubmenu = NSMenu()
        for hour in Self.hourOptions {
            let item = NSMenuItem(title: "\(hour):00 Uhr", action: #selector(selectHour(_:)), keyEquivalent: "")
            item.target = self
            item.tag = hour
            item.state = ReminderSettings.hour == hour ? .on : .off
            hourSubmenu.addItem(item)
        }
        let hourItem = NSMenuItem(title: "Uhrzeit", action: nil, keyEquivalent: "")
        hourItem.submenu = hourSubmenu
        reminderMenu.addItem(hourItem)

        let reminderItem = NSMenuItem(title: "Erinnerungen", action: nil, keyEquivalent: "")
        reminderItem.submenu = reminderMenu
        menu.addItem(reminderItem)

        menu.addItem(.separator())

        let onboardingItem = NSMenuItem(title: "Einführung erneut anzeigen", action: #selector(resetOnboarding), keyEquivalent: "")
        onboardingItem.target = self
        menu.addItem(onboardingItem)

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

    @objc private func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: OnboardingView.hasSeenOnboardingKey)
        openPopover()
    }

    @objc private func toggleReminderEnabled() {
        if ReminderSettings.isEnabled {
            ReminderSettings.isEnabled = false
            reminderScheduler.updateSchedule()
            return
        }

        reminderScheduler.requestAuthorizationIfNeeded { [weak self] granted in
            guard let self else { return }
            if granted {
                ReminderSettings.isEnabled = true
                self.reminderScheduler.updateSchedule()
            } else {
                ReminderSettings.isEnabled = false
                self.showNotificationPermissionDeniedAlert()
            }
        }
    }

    @objc private func selectWeekday(_ sender: NSMenuItem) {
        ReminderSettings.weekday = sender.tag
        reminderScheduler.updateSchedule()
    }

    @objc private func selectHour(_ sender: NSMenuItem) {
        ReminderSettings.hour = sender.tag
        reminderScheduler.updateSchedule()
    }

    private func showNotificationPermissionDeniedAlert() {
        let alert = NSAlert()
        alert.messageText = "Benachrichtigungen deaktiviert"
        alert.informativeText = "Bitte aktiviere Benachrichtigungen für \"Win Bucket\" in den Systemeinstellungen, um Erinnerungen zu erhalten."
        alert.runModal()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
