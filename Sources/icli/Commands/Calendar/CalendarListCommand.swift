import Foundation

enum CalendarListCommand {
    static func run(format: OutputFormat) async throws {
        let store = CalendarsStore()
        try store.requestAccess()
        let calendars = await store.calendars()
        Output.printCalendars(calendars, format: format)
    }
}
