import Foundation

public enum ICLIError: Error, LocalizedError, Sendable {
  case accessDenied(String)
  case listNotFound(String)
  case reminderNotFound(String)
  case calendarNotFound(String)
  case eventNotFound(String)
  case missingArgument(String)
  case invalidArgument(String)
  case operationFailed(String)

  public var errorDescription: String? {
    switch self {
    case .accessDenied(let svc):
      return "\(svc) access denied. Run 'icli auth request' to grant permission."
    case .listNotFound(let name):
      return "Reminder list not found: \(name)"
    case .reminderNotFound(let id):
      return "Reminder not found: \(id)"
    case .calendarNotFound(let name):
      return "Calendar not found: \(name)"
    case .eventNotFound(let id):
      return "Event not found: \(id)"
    case .missingArgument(let name):
      return "Missing required argument: \(name)"
    case .invalidArgument(let msg):
      return "Invalid argument: \(msg)"
    case .operationFailed(let msg):
      return msg
    }
  }
}

public enum ReminderPriority: String, Codable, CaseIterable, Sendable, Equatable {
  case none, low, medium, high

  public init(eventKitValue: Int) {
    switch eventKitValue {
    case 1...4: self = .high
    case 5: self = .medium
    case 6...9: self = .low
    default: self = .none
    }
  }

  public var eventKitValue: Int {
    switch self {
    case .none: return 0
    case .high: return 1
    case .medium: return 5
    case .low: return 9
    }
  }
}

public struct ReminderList: Identifiable, Codable, Sendable, Equatable {
  public let id: String
  public let title: String
  public let reminderCount: Int
  public let overdueCount: Int

  public init(id: String, title: String, reminderCount: Int, overdueCount: Int) {
    self.id = id
    self.title = title
    self.reminderCount = reminderCount
    self.overdueCount = overdueCount
  }
}

public struct ReminderItem: Identifiable, Codable, Sendable, Equatable {
  public let id: String
  public let title: String
  public let notes: String?
  public let isCompleted: Bool
  public let completionDate: Date?
  public let priority: ReminderPriority
  public let dueDate: Date?
  public let listID: String
  public let listName: String
  public let url: URL?
  public let location: String?

  public init(
    id: String,
    title: String,
    notes: String?,
    isCompleted: Bool,
    completionDate: Date?,
    priority: ReminderPriority,
    dueDate: Date?,
    listID: String,
    listName: String,
    url: URL? = nil,
    location: String? = nil
  ) {
    self.id = id
    self.title = title
    self.notes = notes
    self.isCompleted = isCompleted
    self.completionDate = completionDate
    self.priority = priority
    self.dueDate = dueDate
    self.listID = listID
    self.listName = listName
    self.url = url
    self.location = location
  }
}

public struct ReminderDraft: Codable, Sendable, Equatable {
  public let title: String
  public let notes: String?
  public let dueDate: Date?
  public let priority: ReminderPriority
  public let url: URL?
  public let location: String?

  public init(
    title: String,
    notes: String?,
    dueDate: Date?,
    priority: ReminderPriority,
    url: URL? = nil,
    location: String? = nil
  ) {
    self.title = title
    self.notes = notes
    self.dueDate = dueDate
    self.priority = priority
    self.url = url
    self.location = location
  }
}

public struct ReminderUpdate: Codable, Sendable, Equatable {
  public var title: String?
  public var notes: String?
  public var dueDate: Date?
  public var clearDueDate: Bool
  public var priority: ReminderPriority?
  public var listName: String?
  public var isCompleted: Bool?
  public var url: URL?
  public var clearURL: Bool
  public var location: String?
  public var clearLocation: Bool

  public init(
    title: String? = nil,
    notes: String? = nil,
    dueDate: Date? = nil,
    clearDueDate: Bool = false,
    priority: ReminderPriority? = nil,
    listName: String? = nil,
    isCompleted: Bool? = nil,
    url: URL? = nil,
    clearURL: Bool = false,
    location: String? = nil,
    clearLocation: Bool = false
  ) {
    self.title = title
    self.notes = notes
    self.dueDate = dueDate
    self.clearDueDate = clearDueDate
    self.priority = priority
    self.listName = listName
    self.isCompleted = isCompleted
    self.url = url
    self.clearURL = clearURL
    self.location = location
    self.clearLocation = clearLocation
  }
}

public struct CalendarInfo: Identifiable, Codable, Sendable, Equatable {
  public let id: String
  public let title: String
  public let source: String

  public init(id: String, title: String, source: String) {
    self.id = id
    self.title = title
    self.source = source
  }
}

public struct CalendarEvent: Identifiable, Codable, Sendable, Equatable {
  public let id: String
  public let title: String
  public let startDate: Date
  public let endDate: Date
  public let isAllDay: Bool
  public let location: String?
  public let notes: String?
  public let calendarID: String
  public let calendarTitle: String
  public let url: URL?

  public init(
    id: String,
    title: String,
    startDate: Date,
    endDate: Date,
    isAllDay: Bool,
    location: String?,
    notes: String?,
    calendarID: String,
    calendarTitle: String,
    url: URL?
  ) {
    self.id = id
    self.title = title
    self.startDate = startDate
    self.endDate = endDate
    self.isAllDay = isAllDay
    self.location = location
    self.notes = notes
    self.calendarID = calendarID
    self.calendarTitle = calendarTitle
    self.url = url
  }
}

public struct EventDraft: Codable, Sendable, Equatable {
  public let title: String
  public let startDate: Date
  public let endDate: Date
  public let calendarName: String?
  public let location: String?
  public let notes: String?
  public let isAllDay: Bool
  public let url: URL?

  public init(
    title: String,
    startDate: Date,
    endDate: Date,
    calendarName: String?,
    location: String?,
    notes: String?,
    isAllDay: Bool,
    url: URL?
  ) {
    self.title = title
    self.startDate = startDate
    self.endDate = endDate
    self.calendarName = calendarName
    self.location = location
    self.notes = notes
    self.isAllDay = isAllDay
    self.url = url
  }
}
