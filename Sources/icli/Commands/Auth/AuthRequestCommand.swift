import Foundation

enum AuthRequestCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        let onlyReminders = args.hasFlag("--reminders")
        let onlyCalendars = args.hasFlag("--calendars")
        let requestBoth = !onlyReminders && !onlyCalendars

        let payload: AuthStatusPayload = try await CompanionClient.shared.send(
            .authRequest,
            args: AuthRequestArgs(
                reminders: requestBoth || onlyReminders,
                calendars: requestBoth || onlyCalendars
            )
        )

        Output.printAuthStatus(
            reminders: payload.reminders,
            calendars: payload.calendars,
            format: format
        )

        let failures = Set(["denied", "restricted", "write-only", "not-determined", "unknown"])
        if failures.contains(payload.reminders) || failures.contains(payload.calendars) {
            exit(1)
        }
    }
}
