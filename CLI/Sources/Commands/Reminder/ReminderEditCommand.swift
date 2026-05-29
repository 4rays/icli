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
    let urlStr = args.option("--url", "-u")

    var update = ReminderUpdate()
    if let t = newTitle { update.title = t }
    if let l = newList { update.listName = l }
    if let n = newNotes { update.notes = n }

    if let dueStr {
      if dueStr.lowercased() == "none" {
        update.clearDueDate = true
      } else if let d = DateParsing.parseUserDate(dueStr) {
        update.dueDate = d
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

    if let urlStr {
      if urlStr.lowercased() == "none" {
        update.clearURL = true
      } else if let u = URL(string: urlStr) {
        update.url = u
      } else {
        throw ICLIError.invalidArgument("Cannot parse URL: \(urlStr)")
      }
    }


    let item: ReminderItem = try await AppClient.shared.send(
      .reminderEdit,
      args: ReminderEditArgs(id: id, update: update)
    )

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
