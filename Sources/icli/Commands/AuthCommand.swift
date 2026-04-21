import Foundation

enum AuthCommand {
    static func run(args: [String], format: OutputFormat) async throws {
        if args.isEmpty || args.first == "--help" || args.first == "-h" {
            printHelp(); return
        }

        var args = args
        let cmd = args.removeFirst()

        switch cmd {
        case "request":
            try await AuthRequestCommand.run(args: ParsedArgs(args), format: format)
        case "status":
            try await AuthStatusCommand.run(format: format)
        default:
            throw ICLIError.operationFailed("Unknown auth command: \(cmd)")
        }
    }

    static func printHelp() {
        print("""
        USAGE: icli auth <command>

        COMMANDS:
          request   Request Reminders and/or Calendar permission
          status    Show current authorization status

        OPTIONS for request:
          --reminders, --reminder   Request only Reminders access
          --calendars, --calendar   Request only Calendars access
          (default: request both)
        """)
    }
}
