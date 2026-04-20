import Foundation

enum CalendarAddCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        let titleFlag = args.option("--title", "-t")
        let titlePos = args.positionals.first
        guard let title = titleFlag ?? titlePos, !title.isEmpty else {
            throw ICLIError.missingArgument("title")
        }

        guard let startStr = args.option("--start", "-s") else {
            throw ICLIError.missingArgument("--start")
        }
        guard let endStr = args.option("--end", "-e") else {
            throw ICLIError.missingArgument("--end")
        }

        guard let startDate = DateParsing.parseUserDate(startStr) else {
            throw ICLIError.invalidArgument("Cannot parse start date: \(startStr)")
        }
        guard let endDate = DateParsing.parseUserDate(endStr) else {
            throw ICLIError.invalidArgument("Cannot parse end date: \(endStr)")
        }

        let calName = args.option("--calendar", "-c")
        let location = args.option("--location")
        let notes = args.option("--notes", "-n")
        let urlStr = args.option("--url")
        let isAllDay = args.hasFlag("--all-day", "--allday")

        let url = urlStr.flatMap { URL(string: $0) }

        let draft = EventDraft(
            title: title,
            startDate: startDate,
            endDate: endDate,
            calendarName: calName,
            location: location,
            notes: notes,
            isAllDay: isAllDay,
            url: url
        )

        let event: CalendarEvent = try await CompanionClient.shared.send(
            .calendarAdd,
            args: CalendarAddArgs(draft: draft)
        )

        switch format {
        case .human:
            let dateStr = event.isAllDay
                ? DateParsing.formatDate(event.startDate)
                : DateParsing.formatDisplay(event.startDate)
            print("Added: \(event.title)  \(dateStr)  [\(event.calendarTitle)]")
        case .plain:
            print(event.id)
        case .json:
            Output.printEvents([event], format: format)
        }
    }
}
