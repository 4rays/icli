import Foundation

enum ReminderCommand {
  static func run(args: [String], format: OutputFormat) async throws {
    if args.isEmpty || args.first == "--help" || args.first == "-h" {
      printHelp()
      return
    }

    var args = args
    let cmd = args.removeFirst()
    let parsed = ParsedArgs(args)

    switch cmd {
    case "list", "ls":
      try await ReminderListCommand.run(args: parsed, format: format)
    case "lists":
      try await ReminderListsCommand.run(format: format)
    case "add":
      try await ReminderAddCommand.run(args: parsed, format: format)
    case "complete", "done":
      try await ReminderCompleteCommand.run(args: parsed, format: format)
    case "delete", "rm", "remove":
      try await ReminderDeleteCommand.run(args: parsed, format: format)
    case "edit":
      try await ReminderEditCommand.run(args: parsed, format: format)
    default:
      throw ICLIError.operationFailed("Unknown reminder command: \(cmd)")
    }
  }

  static func printHelp() {
    print(
      """
      USAGE: icli reminder <command> [options]

      COMMANDS:
        list      List incomplete reminders
        lists     List reminder lists with counts
        add       Add a reminder
        complete  Mark reminder(s) as complete
        delete    Delete reminder(s)
        edit      Edit a reminder

      list options:
        --list <name>   Filter by list name
        --completed     Include completed reminders

      add options:
        <title>                    Reminder title (positional or --title)
        --list <name>              Target list (default list if omitted)
        --due <date>               Due date (today, tomorrow, YYYY-MM-DD, etc.)
        --notes <text>             Notes
        --priority none|low|medium|high

      complete / delete:
        <id>...   One or more reminder IDs

      edit options:
        <id>           Reminder ID
        --title <t>    New title
        --list <name>  Move to list
        --due <date>   New due date (use 'none' to clear)
        --notes <t>    New notes
        --priority <p>
      """)
  }
}
