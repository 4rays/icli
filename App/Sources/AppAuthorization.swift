import AppKit
import EventKit
import Foundation

enum AppAuthorization {
    // EKEventStore.authorizationStatus(for:) returns stale notDetermined in-process on
    // macOS 26 beta after a grant. Cache the last known good result so both the UI and
    // the IPC handler report the correct status.
    nonisolated(unsafe) private static var cachedReminders: AuthorizationStatus?
    nonisolated(unsafe) private static var cachedCalendars: AuthorizationStatus?

    @MainActor
    static func status() -> AuthStatusPayload {
        let live = (
            reminders: statusLabel(EKEventStore.authorizationStatus(for: .reminder)),
            calendars: statusLabel(EKEventStore.authorizationStatus(for: .event))
        )
        return payload(
            reminders: resolve(live: live.reminders, cached: cachedReminders),
            calendars: resolve(live: live.calendars, cached: cachedCalendars)
        )
    }

    @MainActor
    static func request(_ args: AuthRequestArgs) async throws -> AuthStatusPayload {
        var remindersStatus = AuthorizationStatus.skipped
        var calendarsStatus = AuthorizationStatus.skipped

        if args.reminders {
            remindersStatus = await requestReminders()
            if remindersStatus != .notDetermined && remindersStatus != .skipped {
                cachedReminders = remindersStatus
            }
        }

        if args.calendars {
            calendarsStatus = await requestCalendars()
            if calendarsStatus != .notDetermined && calendarsStatus != .skipped {
                cachedCalendars = calendarsStatus
            }
        }

        return payload(reminders: remindersStatus, calendars: calendarsStatus)
    }

    @MainActor
    private static func requestReminders() async -> AuthorizationStatus {
        let before = EKEventStore.authorizationStatus(for: .reminder)
        guard before == .notDetermined else { return statusLabel(before) }

        NSApp.activate(ignoringOtherApps: true)
        let store = EKEventStore()
        do {
            let granted = try await store.requestFullAccessToReminders()
            if granted { return .authorized }
        } catch {}

        return statusLabel(EKEventStore.authorizationStatus(for: .reminder))
    }

    @MainActor
    private static func requestCalendars() async -> AuthorizationStatus {
        let before = EKEventStore.authorizationStatus(for: .event)
        guard before == .notDetermined else { return statusLabel(before) }

        NSApp.activate(ignoringOtherApps: true)
        let store = EKEventStore()
        do {
            let granted = try await store.requestFullAccessToEvents()
            if granted { return .authorized }
        } catch {}

        return statusLabel(EKEventStore.authorizationStatus(for: .event))
    }

    // Prefer the live value unless it's a stale notDetermined contradicting a cached grant.
    // Permissions can't regress from a known state back to notDetermined in TCC.
    private static func resolve(live: AuthorizationStatus, cached: AuthorizationStatus?) -> AuthorizationStatus {
        guard live == .notDetermined, let cached, cached != .notDetermined else { return live }
        return cached
    }

    private static func statusLabel(_ status: EKAuthorizationStatus) -> AuthorizationStatus {
        switch status {
        case .fullAccess, .authorized: return .authorized
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        case .writeOnly: return .writeOnly
        @unknown default: return .unknown
        }
    }

    private static func payload(reminders: AuthorizationStatus, calendars: AuthorizationStatus) -> AuthStatusPayload {
        AuthStatusPayload(
            reminders: reminders,
            calendars: calendars,
            app: AppDiagnostics(
                processID: ProcessInfo.processInfo.processIdentifier,
                bundleIdentifier: Bundle.main.bundleIdentifier,
                bundlePath: Bundle.main.bundleURL.path,
                executablePath: Bundle.main.executableURL?.path
            )
        )
    }
}
