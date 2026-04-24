import AppKit
import EventKit
import Foundation

enum CompanionAuthorization {
    @MainActor
    static func status() -> AuthStatusPayload {
        payload(
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

        return payload(reminders: remindersStatus, calendars: calendarsStatus)
    }

    @MainActor
    private static func requestReminders() async -> String {
        let before = EKEventStore.authorizationStatus(for: .reminder)
        guard before == .notDetermined else { return statusLabel(before) }

        NSApp.activate(ignoringOtherApps: true)
        let store = EKEventStore()
        do {
            let granted = try await store.requestFullAccessToReminders()
            if granted {
                return "authorized"
            }
        } catch {
            return statusLabel(EKEventStore.authorizationStatus(for: .reminder))
        }

        return statusLabel(EKEventStore.authorizationStatus(for: .reminder))
    }

    @MainActor
    private static func requestCalendars() async -> String {
        let before = EKEventStore.authorizationStatus(for: .event)
        guard before == .notDetermined else { return statusLabel(before) }

        NSApp.activate(ignoringOtherApps: true)
        let store = EKEventStore()
        do {
            let granted = try await store.requestFullAccessToEvents()
            if granted {
                return "authorized"
            }
        } catch {
            return statusLabel(EKEventStore.authorizationStatus(for: .event))
        }

        return statusLabel(EKEventStore.authorizationStatus(for: .event))
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

    private static func payload(reminders: String, calendars: String) -> AuthStatusPayload {
        AuthStatusPayload(
            reminders: reminders,
            calendars: calendars,
            companion: CompanionDiagnostics(
                processID: ProcessInfo.processInfo.processIdentifier,
                bundleIdentifier: Bundle.main.bundleIdentifier,
                bundlePath: Bundle.main.bundleURL.path,
                executablePath: Bundle.main.executableURL?.path
            )
        )
    }
}
