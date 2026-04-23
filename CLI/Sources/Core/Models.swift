import Foundation

// MARK: - Errors

enum ICLIError: Error, LocalizedError {
    case accessDenied(String)
    case listNotFound(String)
    case reminderNotFound(String)
    case calendarNotFound(String)
    case eventNotFound(String)
    case missingArgument(String)
    case invalidArgument(String)
    case operationFailed(String)

    var errorDescription: String? {
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

// MARK: - Reminder models

enum ReminderPriority: String, Codable, CaseIterable, Sendable {
    case none, low, medium, high

    init(eventKitValue: Int) {
        switch eventKitValue {
        case 1...4: self = .high
        case 5: self = .medium
        case 6...9: self = .low
        default: self = .none
        }
    }

    var eventKitValue: Int {
        switch self {
        case .none: return 0
        case .high: return 1
        case .medium: return 5
        case .low: return 9
        }
    }
}

struct ReminderList: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let title: String
    let reminderCount: Int
    let overdueCount: Int
}

struct ReminderItem: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let title: String
    let notes: String?
    let isCompleted: Bool
    let completionDate: Date?
    let priority: ReminderPriority
    let dueDate: Date?
    let listID: String
    let listName: String
}

struct ReminderDraft: Sendable {
    let title: String
    let notes: String?
    let dueDate: Date?
    let priority: ReminderPriority
}

struct ReminderUpdate: Sendable {
    var title: String?
    var notes: String?
    var dueDate: Date??
    var priority: ReminderPriority?
    var listName: String?
    var isCompleted: Bool?
}

// MARK: - Calendar models

struct CalendarInfo: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let source: String
}

struct CalendarEvent: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let notes: String?
    let calendarID: String
    let calendarTitle: String
    let url: URL?
}

struct EventDraft: Sendable {
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarName: String?
    let location: String?
    let notes: String?
    let isAllDay: Bool
    let url: URL?
}
