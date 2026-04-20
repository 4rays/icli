import EventKit
import Foundation

enum AuthRequestCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        let onlyReminders = args.hasFlag("--reminders")
        let onlyCalendars = args.hasFlag("--calendars")
        let both = !onlyReminders && !onlyCalendars

        var remStatus = "skipped"
        var calStatus = "skipped"
        var needsManual = false

        if both || onlyReminders {
            let (status, manual) = await requestReminders()
            remStatus = status
            if manual { needsManual = true }
        }
        if both || onlyCalendars {
            let (status, manual) = await requestCalendars()
            calStatus = status
            if manual { needsManual = true }
        }

        Output.printAuthStatus(reminders: remStatus, calendars: calStatus, format: format)

        if needsManual {
            print("")
            print("The permission dialog could not be shown automatically.")
            print("Grant access manually:")
            print("  System Settings → Privacy & Security → Reminders → add icli")
            print("  System Settings → Privacy & Security → Calendars → add icli")
            openSystemSettings()
        }

        let denied = remStatus == "denied" || calStatus == "denied"
        let manual = remStatus == "needs-manual" || calStatus == "needs-manual"
        if denied || manual { exit(1) }
    }

    @MainActor
    private static func requestReminders() async -> (String, Bool) {
        let before = EKEventStore.authorizationStatus(for: .reminder)
        guard before == .notDetermined else { return (statusLabel(before), false) }

        let store = EKEventStore()
        let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            store.requestFullAccessToReminders { g, _ in cont.resume(returning: g) }
        }

        let after = EKEventStore.authorizationStatus(for: .reminder)
        if after == .notDetermined {
            return ("needs-manual", true)
        }
        return (granted ? "granted" : "denied", false)
    }

    @MainActor
    private static func requestCalendars() async -> (String, Bool) {
        let before = EKEventStore.authorizationStatus(for: .event)
        guard before == .notDetermined else { return (statusLabel(before), false) }

        let store = EKEventStore()
        let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            store.requestFullAccessToEvents { g, _ in cont.resume(returning: g) }
        }

        let after = EKEventStore.authorizationStatus(for: .event)
        if after == .notDetermined {
            return ("needs-manual", true)
        }
        return (granted ? "granted" : "denied", false)
    }

    private static func openSystemSettings() {
        let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        proc.arguments = [url]
        try? proc.run()
    }

    private static func statusLabel(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .fullAccess, .authorized: return "already-granted"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .writeOnly: return "write-only"
        case .notDetermined: return "not-determined"
        @unknown default: return "unknown"
        }
    }
}
