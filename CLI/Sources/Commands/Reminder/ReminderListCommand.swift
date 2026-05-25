import Foundation

enum ReminderListCommand {
  static func run(args: ParsedArgs, format: OutputFormat) async throws {
    let listName = args.option("--list", "-l")
    let showCompleted = args.hasFlag("--completed", "-c")

    let items: [ReminderItem] = try await AppClient.shared.send(
      .reminderList,
      args: ReminderListArgs(listName: listName, includeCompleted: showCompleted)
    )
    Output.printReminders(items, format: format)
  }
}

enum ReminderListsCommand {
  static func run(format: OutputFormat) async throws {
    let lists: [ReminderList] = try await AppClient.shared.send(.reminderLists)
    Output.printReminderLists(lists, format: format)
  }
}
