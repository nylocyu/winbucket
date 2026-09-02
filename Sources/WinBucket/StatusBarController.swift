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
        (2, "Monday"), (3, "Tuesday"), (4, "Wednesday"), (5, "Thursday"),
        (6, "Friday"), (7, "Saturday"), (1, "Sunday")
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

        let openItem = NSMenuItem(title: "Open Folder", action: #selector(openFolder), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let changeItem = NSMenuItem(title: "Change Location…", action: #selector(changeLocation), keyEquivalent: "")
        changeItem.target = self
        menu.addItem(changeItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let reminderMenu = NSMenu()

        let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleReminderEnabled), keyEquivalent: "")
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
        let weekdayItem = NSMenuItem(title: "Weekday", action: nil, keyEquivalent: "")
        weekdayItem.submenu = weekdaySubmenu
        weekdayItem.isEnabled = ReminderSettings.isEnabled
        reminderMenu.addItem(weekdayItem)

        let hourSubmenu = NSMenu()
        for hour in Self.hourOptions {
            let item = NSMenuItem(title: "\(hour):00", action: #selector(selectHour(_:)), keyEquivalent: "")
            item.target = self
            item.tag = hour
            item.state = ReminderSettings.hour == hour ? .on : .off
            hourSubmenu.addItem(item)
        }
        let hourItem = NSMenuItem(title: "Time", action: nil, keyEquivalent: "")
        hourItem.submenu = hourSubmenu
        hourItem.isEnabled = ReminderSettings.isEnabled
        reminderMenu.addItem(hourItem)

        let reminderItem = NSMenuItem(title: "Reminders", action: nil, keyEquivalent: "")
        reminderItem.submenu = reminderMenu
        menu.addItem(reminderItem)

        menu.addItem(.separator())

        let onboardingItem = NSMenuItem(title: "Show Onboarding Again", action: #selector(resetOnboarding), keyEquivalent: "")
        onboardingItem.target = self
        menu.addItem(onboardingItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        NSMenu.popUpContextMenu(menu, with: event, for: dropView)
    }

    @objc private func openFolder() {
        NSWorkspace.shared.open(store.rootURL)
    }

    @objc private func changeLocation() {
        let panel = NSOpenPanel()
        panel.title = "New Location"
        panel.message = "Choose a folder to move \"Win Bucket\" into."
        panel.prompt = "Move"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let chosenParent = panel.url else { return }
        let newRoot = chosenParent.appendingPathComponent("Win Bucket", isDirectory: true)
        let oldRoot = store.rootURL

        guard !FileManager.default.fileExists(atPath: newRoot.path) else {
            let alert = NSAlert()
            alert.messageText = "Folder Already Exists"
            alert.informativeText = "There's already a \"Win Bucket\" folder in \"\(chosenParent.lastPathComponent)\". Please choose a different destination folder."
            alert.runModal()
            return
        }

        do {
            try FileManager.default.moveItem(at: oldRoot, to: newRoot)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Move Failed"
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
        alert.messageText = "Notifications Disabled"
        alert.informativeText = "Please enable notifications for \"Win Bucket\" in System Settings to receive reminders."
        alert.runModal()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
