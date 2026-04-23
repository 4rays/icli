import Foundation

enum CalendarCommand {
    static func run(args: [String], format: OutputFormat) async throws {
        if args.isEmpty || args.first == "--help" || args.first == "-h" {
            printHelp(); return
        }

        var args = args
        let cmd = args.removeFirst()
        let parsed = ParsedArgs(args)

        switch cmd {
        case "list", "ls":
            try await CalendarListCommand.run(format: format)
        case "events":
            try await CalendarEventsCommand.run(args: parsed, format: format)
        case "add":
            try await CalendarAddCommand.run(args: parsed, format: format)
        case "delete", "rm", "remove":
            try await CalendarDeleteCommand.run(args: parsed, format: format)
        default:
            throw ICLIError.operationFailed("Unknown calendar command: \(cmd)")
        }
    }

    static func printHelp() {
        print("""
        USAGE: icli calendar <command> [options]

        COMMANDS:
          list      List available calendars
          events    List events in a date range
          add       Create a calendar event
          delete    Delete a calendar event

        events options:
          --start <date>      Start date (default: today)
          --end <date>        End date (default: +7 days from start)
          --calendar <name>   Filter by calendar name

        add options:
          <title>             Event title (positional or --title)
          --start <datetime>  Start date/time (required)
          --end <datetime>    End date/time (required)
          --calendar <name>   Target calendar
          --location <text>   Location
          --notes <text>      Notes
          --url <url>         URL
          --all-day           All-day event

        delete:
          <id>   Event ID (from 'icli calendar events --format json')
        """)
    }
}
