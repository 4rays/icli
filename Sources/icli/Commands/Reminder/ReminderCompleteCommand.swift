import Foundation

enum ReminderCompleteCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        let ids = args.positionals
        guard !ids.isEmpty else {
            throw ICLIError.missingArgument("id")
        }

        let store = RemindersStore()
        try store.requestAccess()
        let count = try await store.completeReminders(ids: ids)

        switch format {
        case .human:
            print("Completed \(count) reminder(s).")
        case .plain:
            print(count)
        case .json:
            Output.printReminders([], format: .json)
        }
    }
}
