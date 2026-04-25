import Foundation

enum CalendarEventsCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        let startStr = args.option("--start", "-s")
        let endStr = args.option("--end", "-e")
        let calName = args.option("--calendar", "-c")

        let now = Date()
        let cal = Calendar.current

        let start: Date
        if let s = startStr {
            guard let d = DateParsing.parseUserDate(s) else {
                throw ICLIError.invalidArgument("Cannot parse start date: \(s)")
            }
            start = d
        } else {
            start = cal.startOfDay(for: now)
        }

        let end: Date
        if let e = endStr {
            guard let d = DateParsing.parseUserDate(e) else {
                throw ICLIError.invalidArgument("Cannot parse end date: \(e)")
            }
            end = d
        } else {
            end = cal.date(byAdding: .day, value: 7, to: start)!
        }

        let events: [CalendarEvent] = try await AppClient.shared.send(
            .calendarEvents,
            args: CalendarEventsArgs(start: start, end: end, calendarName: calName)
        )
        Output.printEvents(events, format: format)
    }
}
