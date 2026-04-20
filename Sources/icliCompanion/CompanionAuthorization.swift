import AppKit
import EventKit
import Foundation

enum CompanionAuthorization {
    static func status() -> AuthStatusPayload {
        AuthStatusPayload(
            reminders: statusLabel(EKEventStore.authorizationStatus(for: .reminder)),
            calendars: statusLabel(EKEventStore.authorizationStatus(for: .event))
        )
    }

    @MainActor
    static func request(_ args: AuthRequestArgs) async throws -> AuthStatusPayload {
        var remindersStatus = "skipped"
        var calendarsStatus = "skipped"

        if args.reminders {
            remindersStatus = await requestReminders()
        }

        if args.calendars {
            calendarsStatus = await requestCalendars()
        }

        return AuthStatusPayload(reminders: remindersStatus, calendars: calendarsStatus)
    }

    @MainActor
    private static func requestReminders() async -> String {
        let before = EKEventStore.authorizationStatus(for: .reminder)
        guard before == .notDetermined else { return requestStatusLabel(before) }

        NSApp.activate(ignoringOtherApps: true)
        let store = EKEventStore()
        do {
            try await store.requestFullAccessToReminders()
        } catch {
            return statusLabel(EKEventStore.authorizationStatus(for: .reminder))
        }

        return requestResultLabel(EKEventStore.authorizationStatus(for: .reminder))
    }

    @MainActor
    private static func requestCalendars() async -> String {
        let before = EKEventStore.authorizationStatus(for: .event)
        guard before == .notDetermined else { return requestStatusLabel(before) }

        NSApp.activate(ignoringOtherApps: true)
        let store = EKEventStore()
        do {
            try await store.requestFullAccessToEvents()
        } catch {
            return statusLabel(EKEventStore.authorizationStatus(for: .event))
        }

        return requestResultLabel(EKEventStore.authorizationStatus(for: .event))
    }

    private static func requestStatusLabel(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .fullAccess, .authorized: return "already-granted"
        case .notDetermined: return "not-determined"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .writeOnly: return "write-only"
        @unknown default: return "unknown"
        }
    }

    private static func requestResultLabel(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .fullAccess, .authorized: return "granted"
        case .notDetermined: return "not-determined"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .writeOnly: return "write-only"
        @unknown default: return "unknown"
        }
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
