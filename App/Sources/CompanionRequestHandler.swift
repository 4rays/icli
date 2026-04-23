import Foundation

final class CompanionRequestHandler: @unchecked Sendable {
    private let remindersStore = RemindersStore()
    private let calendarsStore = CalendarsStore()

    func handle(_ request: CompanionRequestEnvelope) async -> CompanionResponseEnvelope {
        do {
            guard let operation = CompanionOperation(rawValue: request.op) else {
                throw ICLIError.invalidArgument("Unknown companion operation: \(request.op)")
            }

            switch operation {
            case .appShowSettings:
                await MainActor.run {
                    CompanionSettingsWindowController.shared.show()
                }
                return try success(request, EmptyArgs())
            case .authStatus:
                let result = await CompanionAuthorization.status()
                return try success(request, result)
            case .authRequest:
                let args = try decodeArgs(request, as: AuthRequestArgs.self)
                let result = try await CompanionAuthorization.request(args)
                return try success(request, result)
            case .reminderList:
                let args = try decodeArgs(request, as: ReminderListArgs.self)
                try remindersStore.requestAccess()
                let items = try await remindersStore.reminders(in: args.listName, includeCompleted: args.includeCompleted)
                return try success(request, items)
            case .reminderLists:
                try remindersStore.requestAccess()
                let lists = await remindersStore.lists()
                return try success(request, lists)
            case .reminderAdd:
                let args = try decodeArgs(request, as: ReminderAddArgs.self)
                try remindersStore.requestAccess()
                let item = try await remindersStore.createReminder(args.draft, listName: args.listName)
                return try success(request, item)
            case .reminderEdit:
                let args = try decodeArgs(request, as: ReminderEditArgs.self)
                try remindersStore.requestAccess()
                let item = try await remindersStore.updateReminder(id: args.id, update: args.update)
                return try success(request, item)
            case .reminderComplete:
                let args = try decodeArgs(request, as: ReminderIDsArgs.self)
                try remindersStore.requestAccess()
                let count = try await remindersStore.completeReminders(ids: args.ids)
                return try success(request, CountPayload(count: count))
            case .reminderDelete:
                let args = try decodeArgs(request, as: ReminderIDsArgs.self)
                try remindersStore.requestAccess()
                let count = try await remindersStore.deleteReminders(ids: args.ids)
                return try success(request, CountPayload(count: count))
            case .calendarList:
                try calendarsStore.requestAccess()
                let calendars = await calendarsStore.calendars()
                return try success(request, calendars)
            case .calendarEvents:
                let args = try decodeArgs(request, as: CalendarEventsArgs.self)
                try calendarsStore.requestAccess()
                let events = try await calendarsStore.events(
                    start: args.start,
                    end: args.end,
                    calendarName: args.calendarName
                )
                return try success(request, events)
            case .calendarAdd:
                let args = try decodeArgs(request, as: CalendarAddArgs.self)
                try calendarsStore.requestAccess()
                let event = try await calendarsStore.createEvent(args.draft)
                return try success(request, event)
            case .calendarDelete:
                let args = try decodeArgs(request, as: CalendarDeleteArgs.self)
                try calendarsStore.requestAccess()
                try await calendarsStore.deleteEvent(id: args.id)
                return try success(request, CountPayload(count: 1))
            }
        } catch {
            return failure(request, error: error)
        }
    }

    private func decodeArgs<T: Decodable>(_ request: CompanionRequestEnvelope, as type: T.Type) throws -> T {
        if T.self == EmptyArgs.self, request.args == nil {
            return EmptyArgs() as! T
        }

        guard let args = request.args else {
            throw ICLIError.missingArgument("args")
        }
        return try args.decode(T.self)
    }

    private func success<T: Encodable>(
        _ request: CompanionRequestEnvelope,
        _ result: T
    ) throws -> CompanionResponseEnvelope {
        CompanionResponseEnvelope(
            id: request.id,
            ok: true,
            result: try JSONValue.encode(result),
            error: nil
        )
    }

    private func failure(_ request: CompanionRequestEnvelope, error: Error) -> CompanionResponseEnvelope {
        let payload: CompanionErrorPayload

        if let icliError = error as? ICLIError {
            switch icliError {
            case .accessDenied:
                payload = CompanionErrorPayload(
                    code: CompanionErrorCode.permissionDenied.rawValue,
                    message: icliError.localizedDescription
                )
            case .listNotFound, .reminderNotFound, .calendarNotFound, .eventNotFound:
                payload = CompanionErrorPayload(
                    code: CompanionErrorCode.notFound.rawValue,
                    message: icliError.localizedDescription
                )
            case .missingArgument, .invalidArgument:
                payload = CompanionErrorPayload(
                    code: CompanionErrorCode.validationFailed.rawValue,
                    message: icliError.localizedDescription
                )
            case .operationFailed:
                payload = CompanionErrorPayload(
                    code: CompanionErrorCode.internalFailure.rawValue,
                    message: icliError.localizedDescription
                )
            }
        } else {
            payload = CompanionErrorPayload(
                code: CompanionErrorCode.internalFailure.rawValue,
                message: error.localizedDescription
            )
        }

        return CompanionResponseEnvelope(
            id: request.id,
            ok: false,
            result: nil,
            error: payload
        )
    }
}
