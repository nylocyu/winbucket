import UserNotifications

// ponytail: notification permission/delivery only works reliably from a
// built, signed .app bundle (Scripts/build_app.sh), not via `swift run` —
// same as LaunchAtLogin.swift.
@MainActor
final class ReminderScheduler: NSObject, @MainActor UNUserNotificationCenterDelegate {
    private static let identifier = "win-bucket-weekly-reminder"

    private let store: WinStore
    var onOpenBucket: (() -> Void)?

    init(store: WinStore) {
        self.store = store
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorizationIfNeeded(completion: @escaping @MainActor (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in completion(granted) }
        }
    }

    func updateSchedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        guard ReminderSettings.isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Win Bucket"
        content.body = "Added a win this week yet? 🎉"
        content.sound = .default

        var components = DateComponents()
        components.weekday = ReminderSettings.weekday
        components.hour = ReminderSettings.hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
        center.add(request)
    }

    private func hasWinThisWeek() -> Bool {
        store.wins.contains {
            Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(hasWinThisWeek() ? [] : [.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == Self.identifier {
            onOpenBucket?()
        }
        completionHandler()
    }
}
