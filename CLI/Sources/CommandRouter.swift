import Foundation

enum CommandRouter {
  static func run() async {
    var args = Array(CommandLine.arguments.dropFirst())

    // Extract global --format / -f before routing
    let format =
      extractOption(&args, names: ["--format", "-f"])
      .flatMap { OutputFormat($0) } ?? .human

    // Handle top-level --help / -h / no args
    if args.isEmpty || args.first == "--help" || args.first == "-h" {
      printHelp()
      exit(0)
    }

    if args.first == "--version" || args.first == "-v" {
      print("icli 0.2.0")
      exit(0)
    }

    let group = args.removeFirst()

    do {
      switch group {
      case "reminder", "reminders", "r":
        try await ReminderCommand.run(args: args, format: format)
      case "calendar", "calendars", "cal", "c":
        try await CalendarCommand.run(args: args, format: format)
      case "permission", "p":
        try await PermissionCommand.run(args: args, format: format)
      case "status":
        try await StatusCommand.run(format: format)
      default:
        Output.printError("Unknown command: \(group)")
        printHelp()
        exit(1)
      }
    } catch {
      Output.printError(error.localizedDescription)
      exit(1)
    }
  }

  // MARK: - Private

  private static func extractOption(_ args: inout [String], names: [String]) -> String? {
    for name in names {
      if let idx = args.firstIndex(of: name), idx + 1 < args.count {
        let value = args[idx + 1]
        args.remove(at: idx + 1)
        args.remove(at: idx)
        return value
      }
    }
    return nil
  }

  static func printHelp() {
    print(
      """
      USAGE: icli <group> <command> [options]

      COMMANDS:
        reminder    Manage Apple Reminders
        calendar    Manage Apple Calendar events
        permission  Manage system permissions
        status      Show permission status

      OPTIONS:
        --format <fmt>   Output format: human (default), json, plain
        --version, -v    Print version
        --help, -h       Show help

      Run 'icli <group> --help' for group commands.
      """)
  }
}
