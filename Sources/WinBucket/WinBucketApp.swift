import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var reminderScheduler: ReminderScheduler?
    private let store = WinStore(rootURL: BucketLocation.rootURL)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let scheduler = ReminderScheduler(store: store)
        scheduler.updateSchedule()
        reminderScheduler = scheduler
        statusBarController = StatusBarController(store: store, reminderScheduler: scheduler)
    }
}

@main
struct WinBucketApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
