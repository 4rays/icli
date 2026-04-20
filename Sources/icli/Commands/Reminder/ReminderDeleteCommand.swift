import Foundation

enum ReminderDeleteCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        let ids = args.positionals
        guard !ids.isEmpty else {
            throw ICLIError.missingArgument("id")
        }

        let store = RemindersStore()
        try store.requestAccess()
        let count = try await store.deleteReminders(ids: ids)

        switch format {
        case .human:
            print("Deleted \(count) reminder(s).")
        case .plain:
            print(count)
        case .json:
            let payload = ["deleted": count]
            let data = try! JSONEncoder().encode(payload)
            print(String(data: data, encoding: .utf8)!)
        }
    }
}
