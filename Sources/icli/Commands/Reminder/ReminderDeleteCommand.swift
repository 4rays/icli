import Foundation

enum ReminderDeleteCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        let ids = args.positionals
        guard !ids.isEmpty else {
            throw ICLIError.missingArgument("id")
        }

        let result: CountPayload = try await CompanionClient.shared.send(
            .reminderDelete,
            args: ReminderIDsArgs(ids: ids)
        )

        switch format {
        case .human:
            print("Deleted \(result.count) reminder(s).")
        case .plain:
            print(result.count)
        case .json:
            let payload = ["deleted": result.count]
            let data = try! JSONEncoder().encode(payload)
            print(String(data: data, encoding: .utf8)!)
        }
    }
}
