import EventKit
import Foundation

actor RemindersStore {
  private let eventStore = EKEventStore()
  private let calendar: Calendar

  init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  nonisolated func requestAccess() throws {
    guard AppAuthorization.isAuthorized(for: .reminder) else {
      throw ICLIError.accessDenied("Reminders")
    }
  }

  func lists() async -> [ReminderList] {
    let allReminders =
      (try? await fetchAllReminders(in: eventStore.calendars(for: .reminder))) ?? []
    let now = Date()
    let startOfToday = calendar.startOfDay(for: now)
    var counts: [String: (total: Int, overdue: Int)] = [:]
    for reminder in allReminders where !reminder.isCompleted {
      let entry = counts[reminder.listID] ?? (0, 0)
      let isOverdue = reminder.dueDate.map { $0 < startOfToday } ?? false
      counts[reminder.listID] = (entry.total + 1, entry.overdue + (isOverdue ? 1 : 0))
    }
    return eventStore.calendars(for: .reminder).map { calendar in
      let entry = counts[calendar.calendarIdentifier] ?? (0, 0)
      return ReminderList(
        id: calendar.calendarIdentifier,
        title: calendar.title,
        reminderCount: entry.total,
        overdueCount: entry.overdue
      )
    }
  }

  func defaultListName() -> String? {
    eventStore.defaultCalendarForNewReminders()?.title
  }

  func reminders(in listName: String? = nil, includeCompleted: Bool) async throws -> [ReminderItem]
  {
    let calendars: [EKCalendar]
    if let listName {
      calendars = eventStore.calendars(for: .reminder).filter { $0.title == listName }
      if calendars.isEmpty { throw ICLIError.listNotFound(listName) }
    } else {
      calendars = eventStore.calendars(for: .reminder)
    }

    let items = try await fetchAllReminders(in: calendars)
    if includeCompleted {
      return items
    }
    return items.filter { !$0.isCompleted }
  }

  func createReminder(_ draft: ReminderDraft, listName: String?) async throws -> ReminderItem {
    let calendar = try ekCalendar(named: listName)
    let reminder = EKReminder(eventStore: eventStore)
    reminder.title = draft.title
    reminder.notes = draft.notes
    reminder.calendar = calendar
    reminder.priority = draft.priority.eventKitValue
    if let due = draft.dueDate {
      reminder.dueDateComponents = self.calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: due)
    }
    try eventStore.save(reminder, commit: true)
    return makeItem(reminder)
  }

  func updateReminder(id: String, update: ReminderUpdate) async throws -> ReminderItem {
    let reminder = try ekReminder(withID: id)
    if let title = update.title { reminder.title = title }
    if let notes = update.notes { reminder.notes = notes }
    if update.clearDueDate {
      reminder.dueDateComponents = nil
    } else if let dueDate = update.dueDate {
      reminder.dueDateComponents = self.calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: dueDate)
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

  private func fetchAllReminders(in calendars: [EKCalendar]) async throws -> [ReminderItem] {
    struct RawData: Sendable {
      let id: String
      let title: String
      let listID: String
      let listName: String
      let notes: String?
      let isCompleted: Bool
      let completionDate: Date?
      let dueDate: Date?
      let priority: Int
    }

    let rawList = await withCheckedContinuation {
      (continuation: CheckedContinuation<[RawData], Never>) in
      let predicate = eventStore.predicateForReminders(in: calendars)
      eventStore.fetchReminders(matching: predicate) { reminders in
        let data = (reminders ?? []).map { reminder in
          RawData(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "",
            listID: reminder.calendar.calendarIdentifier,
            listName: reminder.calendar.title,
            notes: reminder.notes,
            isCompleted: reminder.isCompleted,
            completionDate: reminder.completionDate,
            dueDate: reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
            priority: Int(reminder.priority)
          )
        }
        continuation.resume(returning: data)
      }
    }

    return rawList.map { data in
      ReminderItem(
        id: data.id,
        title: data.title,
        notes: data.notes,
        isCompleted: data.isCompleted,
        completionDate: data.completionDate,
        priority: ReminderPriority(eventKitValue: data.priority),
        dueDate: data.dueDate,
        listID: data.listID,
        listName: data.listName
      )
    }
  }

  private func ekReminder(withID id: String) throws -> EKReminder {
    guard let item = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
      throw ICLIError.reminderNotFound(id)
    }
    return item
  }

  private func ekCalendar(named name: String?) throws -> EKCalendar {
    if let name {
      guard let calendar = eventStore.calendars(for: .reminder).first(where: { $0.title == name })
      else {
        throw ICLIError.listNotFound(name)
      }
      return calendar
    }

    guard let defaultCalendar = eventStore.defaultCalendarForNewReminders() else {
      throw ICLIError.operationFailed("No default list. Specify --list <name>.")
    }
    return defaultCalendar
  }

  private func makeItem(_ reminder: EKReminder) -> ReminderItem {
    ReminderItem(
      id: reminder.calendarItemIdentifier,
      title: reminder.title ?? "",
      notes: reminder.notes,
      isCompleted: reminder.isCompleted,
      completionDate: reminder.completionDate,
      priority: ReminderPriority(eventKitValue: Int(reminder.priority)),
      dueDate: reminder.dueDateComponents.flatMap { calendar.date(from: $0) },
      listID: reminder.calendar.calendarIdentifier,
      listName: reminder.calendar.title
    )
  }
}
