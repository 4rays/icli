import Foundation

enum PermissionRequestCommand {
  static func run(args: ParsedArgs, format: OutputFormat) async throws {
    let onlyReminders = args.hasFlag("--reminders", "--reminder")
    let onlyCalendars = args.hasFlag("--calendars", "--calendar")
    let requestBoth = !onlyReminders && !onlyCalendars

    let payload: AuthStatusPayload = try await AppClient.shared.send(
      .authRequest,
      args: AuthRequestArgs(
        reminders: requestBoth || onlyReminders,
        calendars: requestBoth || onlyCalendars
      )
    )

    Output.printAuthStatus(payload, format: format)

    let failures: Set<AuthorizationStatus> = [
      .denied, .restricted, .writeOnly, .notDetermined, .unknown
    ]
    if failures.contains(payload.reminders) || failures.contains(payload.calendars) {
      exit(1)
    }
  }
}
