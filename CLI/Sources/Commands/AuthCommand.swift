import Foundation

enum PermissionCommand {
  static func run(args: [String], format: OutputFormat) async throws {
    if args.isEmpty || args.first == "--help" || args.first == "-h" {
      printHelp()
      return
    }

    var args = args
    let cmd = args.removeFirst()

    switch cmd {
    case "request":
      try await PermissionRequestCommand.run(args: ParsedArgs(args), format: format)
    case "reset":
      try PermissionResetCommand.run(format: format)
    default:
      throw ICLIError.operationFailed("Unknown permission command: \(cmd)")
    }
  }

  static func printHelp() {
    print(
      """
      USAGE: icli permission <command>

      COMMANDS:
        request   Request Reminders and/or Calendar permission
        reset     Reset all permissions (requires relaunch)

      OPTIONS for request:
        --reminders, --reminder   Request only Reminders access
        --calendars, --calendar   Request only Calendars access
        (default: request both)
      """)
  }
}
