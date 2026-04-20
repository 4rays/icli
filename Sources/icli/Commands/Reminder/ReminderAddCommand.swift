import Foundation

enum ReminderAddCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        // Title: first positional or --title flag
        let titleFlag = args.option("--title", "-t")
        let titlePos = args.positionals.first
        guard let title = titleFlag ?? titlePos, !title.isEmpty else {
            throw ICLIError.missingArgument("title")
        }

        let listFlag = args.option("--list", "-l")
        let dueStr = args.option("--due", "-d")
        let notes = args.option("--notes", "-n")
        let priorityStr = args.option("--priority", "-p")

        let dueDate: Date?
        if let dueStr {
            guard let d = DateParsing.parseUserDate(dueStr) else {
                throw ICLIError.invalidArgument("Cannot parse date: \(dueStr)")
            }
            dueDate = d
        } else {
            dueDate = nil
        }

        let priority: ReminderPriority
        if let pStr = priorityStr {
            guard let p = ReminderPriority(rawValue: pStr.lowercased()) else {
                throw ICLIError.invalidArgument("Priority must be: none, low, medium, high")
            }
            priority = p
        } else {
            priority = .none
        }

        let draft = ReminderDraft(title: title, notes: notes, dueDate: dueDate, priority: priority)
        let item: ReminderItem = try await CompanionClient.shared.send(
            .reminderAdd,
            args: ReminderAddArgs(draft: draft, listName: listFlag)
        )

        switch format {
        case .human:
            print("Added: \(item.title)  [\(item.listName)]")
            if let due = item.dueDate { print("  Due: \(DateParsing.formatDisplay(due))") }
        case .plain:
            print(item.id)
        case .json:
            Output.printReminders([item], format: format)
        }
    }
}
