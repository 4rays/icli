import Foundation

enum AuthStatusCommand {
    static func run(format: OutputFormat) async throws {
        let payload: AuthStatusPayload = try await CompanionClient.shared.send(.authStatus)
        Output.printAuthStatus(
            reminders: payload.reminders,
            calendars: payload.calendars,
            format: format
        )
    }
}
