import Foundation

enum ReminderListCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        let listName = args.option("--list", "-l")
        let showCompleted = args.hasFlag("--completed", "-c")

        let store = RemindersStore()
        try store.requestAccess()

        var items = try await store.reminders(in: listName)
        if !showCompleted {
            items = items.filter { !$0.isCompleted }
        }

        Output.printReminders(items, format: format)
    }
}

enum ReminderListsCommand {
    static func run(format: OutputFormat) async throws {
        let store = RemindersStore()
        try store.requestAccess()
        let lists = await store.lists()
        Output.printReminderLists(lists, format: format)
    }
}
