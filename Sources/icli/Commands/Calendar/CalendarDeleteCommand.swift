import Foundation

enum CalendarDeleteCommand {
    static func run(args: ParsedArgs, format: OutputFormat) async throws {
        guard let id = args.positionals.first else {
            throw ICLIError.missingArgument("id")
        }

        let store = CalendarsStore()
        try store.requestAccess()
        try await store.deleteEvent(id: id)

        switch format {
        case .human:
            print("Deleted event.")
        case .plain:
            print("1")
        case .json:
            let data = try! JSONEncoder().encode(["deleted": 1])
            print(String(data: data, encoding: .utf8)!)
        }
    }
}
