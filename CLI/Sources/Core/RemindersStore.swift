import EventKit
import Foundation

actor RemindersStore {
    private let eventStore = EKEventStore()
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    nonisolated func requestAccess() throws {
        switch Self.authorizationStatus() {
        case .fullAccess, .authorized:
            break
        default:
            throw ICLIError.accessDenied("Reminders. Run 'icli auth request' first")
        }
    }

    static func authorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .reminder)
    }

    func lists() async -> [ReminderList] {
        let allReminders = (try? await fetchAllReminders(in: eventStore.calendars(for: .reminder))) ?? []
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        var counts: [String: (total: Int, overdue: Int)] = [:]
        for r in allReminders where !r.isCompleted {
            let entry = counts[r.listID] ?? (0, 0)
            let isOverdue = r.dueDate.map { $0 < startOfToday } ?? false
            counts[r.listID] = (entry.total + 1, entry.overdue + (isOverdue ? 1 : 0))
        }
        return eventStore.calendars(for: .reminder).map { cal in
            let entry = counts[cal.calendarIdentifier] ?? (0, 0)
            return ReminderList(id: cal.calendarIdentifier, title: cal.title,
                                reminderCount: entry.total, overdueCount: entry.overdue)
        }
    }

    func defaultListName() -> String? {
        eventStore.defaultCalendarForNewReminders()?.title
    }

    func reminders(in listName: String? = nil) async throws -> [ReminderItem] {
        let calendars: [EKCalendar]
        if let listName {
            calendars = eventStore.calendars(for: .reminder).filter { $0.title == listName }
            if calendars.isEmpty { throw ICLIError.listNotFound(listName) }
        } else {
            calendars = eventStore.calendars(for: .reminder)
        }
        return try await fetchAllReminders(in: calendars)
    }

    func createReminder(_ draft: ReminderDraft, listName: String) async throws -> ReminderItem {
        let cal = try ekCalendar(named: listName)
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = draft.title
        reminder.notes = draft.notes
        reminder.calendar = cal
        reminder.priority = draft.priority.eventKitValue
        if let due = draft.dueDate {
            reminder.dueDateComponents = self.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        }
        try eventStore.save(reminder, commit: true)
        return makeItem(reminder)
    }

    func updateReminder(id: String, update: ReminderUpdate) async throws -> ReminderItem {
        let reminder = try ekReminder(withID: id)
        if let title = update.title { reminder.title = title }
        if let notes = update.notes { reminder.notes = notes }
        if let dueUpdate = update.dueDate {
            reminder.dueDateComponents = dueUpdate.map {
                self.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: $0)
            }
        }
        if let priority = update.priority { reminder.priority = priority.eventKitValue }
        if let listName = update.listName { reminder.calendar = try ekCalendar(named: listName) }
        if let completed = update.isCompleted { reminder.isCompleted = completed }
        try eventStore.save(reminder, commit: true)
        return makeItem(reminder)
    }

    func completeReminders(ids: [String]) async throws -> Int {
        var count = 0
        for id in ids {
            let reminder = try ekReminder(withID: id)
            reminder.isCompleted = true
            try eventStore.save(reminder, commit: true)
            count += 1
        }
        return count
    }

    func deleteReminders(ids: [String]) async throws -> Int {
        var count = 0
        for id in ids {
            let reminder = try ekReminder(withID: id)
            try eventStore.remove(reminder, commit: true)
            count += 1
        }
        return count
    }

    // MARK: - Private

    private func fetchAllReminders(in calendars: [EKCalendar]) async throws -> [ReminderItem] {
        struct RawData: Sendable {
            let id, title, listID, listName: String
            let notes: String?
            let isCompleted: Bool
            let completionDate, dueDate: Date?
            let priority: Int
        }

        let rawList = await withCheckedContinuation { (cont: CheckedContinuation<[RawData], Never>) in
            let pred = eventStore.predicateForReminders(in: calendars)
            eventStore.fetchReminders(matching: pred) { reminders in
                let data = (reminders ?? []).map { r in
                    RawData(
                        id: r.calendarItemIdentifier,
                        title: r.title ?? "",
                        listID: r.calendar.calendarIdentifier,
                        listName: r.calendar.title,
                        notes: r.notes,
                        isCompleted: r.isCompleted,
                        completionDate: r.completionDate,
                        dueDate: r.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
                        priority: Int(r.priority)
                    )
                }
                cont.resume(returning: data)
            }
        }

        return rawList.map { d in
            ReminderItem(id: d.id, title: d.title, notes: d.notes,
                         isCompleted: d.isCompleted, completionDate: d.completionDate,
                         priority: ReminderPriority(eventKitValue: d.priority),
                         dueDate: d.dueDate, listID: d.listID, listName: d.listName)
        }
    }

    private func ekReminder(withID id: String) throws -> EKReminder {
        guard let item = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ICLIError.reminderNotFound(id)
        }
        return item
    }

    private func ekCalendar(named name: String) throws -> EKCalendar {
        guard let cal = eventStore.calendars(for: .reminder).first(where: { $0.title == name }) else {
            throw ICLIError.listNotFound(name)
        }
        return cal
    }

    private func makeItem(_ r: EKReminder) -> ReminderItem {
        ReminderItem(
            id: r.calendarItemIdentifier,
            title: r.title ?? "",
            notes: r.notes,
            isCompleted: r.isCompleted,
            completionDate: r.completionDate,
            priority: ReminderPriority(eventKitValue: Int(r.priority)),
            dueDate: r.dueDateComponents.flatMap { calendar.date(from: $0) },
            listID: r.calendar.calendarIdentifier,
            listName: r.calendar.title
        )
    }
}
