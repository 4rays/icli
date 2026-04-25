import Foundation

enum CalendarListCommand {
    static func run(format: OutputFormat) async throws {
        let calendars: [CalendarInfo] = try await AppClient.shared.send(.calendarList)
        Output.printCalendars(calendars, format: format)
    }
}
