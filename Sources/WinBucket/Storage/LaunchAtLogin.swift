import ServiceManagement

// ponytail: needs a proper .app bundle (Info.plist + bundle id) to register
// correctly — fails silently when run via `swift run`. Use Scripts/build_app.sh
// to test this. No error surfacing beyond that; SMAppService's own status
// reflects the real state either way.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("LaunchAtLogin: \(error)")
        }
    }
}
