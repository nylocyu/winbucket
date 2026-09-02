import Foundation

// Weekly reminder, disabled by default. Weekday follows the Calendar
// convention (1 = Sunday ... 7 = Saturday). 0 as the UserDefaults empty
// value never collides, since neither a valid weekday (1-7) nor any of the
// offered hours (8-18) is ever 0.
@MainActor
enum ReminderSettings {
    private static let enabledKey = "WinBucketReminderEnabled"
    private static let weekdayKey = "WinBucketReminderWeekday"
    private static let hourKey = "WinBucketReminderHour"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var weekday: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: weekdayKey)
            return stored == 0 ? 6 : stored
        }
        set { UserDefaults.standard.set(newValue, forKey: weekdayKey) }
    }

    static var hour: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: hourKey)
            return stored == 0 ? 16 : stored
        }
        set { UserDefaults.standard.set(newValue, forKey: hourKey) }
    }
}
