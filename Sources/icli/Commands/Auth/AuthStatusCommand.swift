import EventKit
import Foundation

enum AuthStatusCommand {
    static func run(format: OutputFormat) {
        let remStatus = statusLabel(EKEventStore.authorizationStatus(for: .reminder))
        let calStatus = statusLabel(EKEventStore.authorizationStatus(for: .event))
        Output.printAuthStatus(reminders: remStatus, calendars: calStatus, format: format)
    }

    private static func statusLabel(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .fullAccess, .authorized: return "authorized"
        case .notDetermined: return "not-determined"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .writeOnly: return "write-only"
        @unknown default: return "unknown"
        }
    }
}
