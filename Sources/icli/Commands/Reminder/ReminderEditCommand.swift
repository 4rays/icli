import Foundation

enum ReminderEditCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        guard let id = args.positionals.first else {
            throw ICLIError.missingArgument("id")
        }

        let newTitle = args.option("--title", "-t")
        let newList = args.option("--list", "-l")
        let dueStr = args.option("--due", "-d")
        let newNotes = args.option("--notes", "-n")
        let priorityStr = args.option("--priority", "-p")

        var update = ReminderUpdate()
        if let t = newTitle { update.title = t }
        if let l = newList { update.listName = l }
        if let n = newNotes { update.notes = n }

        if let dueStr {
            if dueStr.lowercased() == "none" {
                update.dueDate = .some(nil)
            } else if let d = DateParsing.parseUserDate(dueStr) {
                update.dueDate = .some(d)
            } else {
                throw ICLIError.invalidArgument("Cannot parse date: \(dueStr)")
            }
        }

        if let pStr = priorityStr {
            guard let p = ReminderPriority(rawValue: pStr.lowercased()) else {
                throw ICLIError.invalidArgument("Priority must be: none, low, medium, high")
            }
            update.priority = p
        }

        let store = RemindersStore()
        try store.requestAccess()
        let item = try await store.updateReminder(id: id, update: update)

        switch format {
        case .human:
            print("Updated: \(item.title)  [\(item.listName)]")
        case .plain:
            print(item.id)
        case .json:
            Output.printReminders([item], format: format)
        }
    }
}
