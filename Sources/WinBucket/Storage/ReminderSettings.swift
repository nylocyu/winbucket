import Foundation

// Standardmäßig deaktivierte, wöchentliche Erinnerung. Weekday folgt der
// Calendar-Konvention (1 = Sonntag ... 7 = Samstag). 0 als UserDefaults-
// Leerwert kollidiert nicht, da weder ein gültiger Wochentag (1-7) noch eine
// der angebotenen Uhrzeiten (8-18) je 0 ist.
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
