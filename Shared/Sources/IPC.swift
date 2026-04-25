import Foundation

public enum AppOperation: String, Codable, Sendable {
    case appShowSettings = "app.showSettings"
    case authStatus = "auth.status"
    case authRequest = "auth.request"
    case reminderList = "reminder.list"
    case reminderLists = "reminder.lists"
    case reminderAdd = "reminder.add"
    case reminderEdit = "reminder.edit"
    case reminderComplete = "reminder.complete"
    case reminderDelete = "reminder.delete"
    case calendarList = "calendar.list"
    case calendarEvents = "calendar.events"
    case calendarAdd = "calendar.add"
    case calendarDelete = "calendar.delete"
}

public struct EmptyArgs: Codable, Sendable, Equatable {
    public init() {}
}

public struct AuthRequestArgs: Codable, Sendable, Equatable {
    public let reminders: Bool
    public let calendars: Bool

    public init(reminders: Bool, calendars: Bool) {
        self.reminders = reminders
        self.calendars = calendars
    }
}

public enum AuthorizationStatus: String, Codable, Sendable, Equatable, CustomStringConvertible {
    case authorized
    case notDetermined = "not-determined"
    case denied
    case restricted
    case writeOnly = "write-only"
    case skipped
    case unknown

    public var description: String { rawValue }
}

public struct AuthStatusPayload: Codable, Sendable, Equatable {
    public let reminders: AuthorizationStatus
    public let calendars: AuthorizationStatus
    public let app: AppDiagnostics?

    public init(
        reminders: AuthorizationStatus,
        calendars: AuthorizationStatus,
        app: AppDiagnostics? = nil
    ) {
        self.reminders = reminders
        self.calendars = calendars
        self.app = app
    }
}

public struct AppDiagnostics: Codable, Sendable, Equatable {
    public let processID: Int32
    public let bundleIdentifier: String?
    public let bundlePath: String?
    public let executablePath: String?

    public init(
        processID: Int32,
        bundleIdentifier: String?,
        bundlePath: String?,
        executablePath: String?
    ) {
        self.processID = processID
        self.bundleIdentifier = bundleIdentifier
        self.bundlePath = bundlePath
        self.executablePath = executablePath
    }
}

public struct ReminderListArgs: Codable, Sendable, Equatable {
    public let listName: String?
    public let includeCompleted: Bool

    public init(listName: String?, includeCompleted: Bool) {
        self.listName = listName
        self.includeCompleted = includeCompleted
    }
}

public struct ReminderAddArgs: Codable, Sendable, Equatable {
    public let draft: ReminderDraft
    public let listName: String?

    public init(draft: ReminderDraft, listName: String?) {
        self.draft = draft
        self.listName = listName
    }
}

public struct ReminderEditArgs: Codable, Sendable, Equatable {
    public let id: String
    public let update: ReminderUpdate

    public init(id: String, update: ReminderUpdate) {
        self.id = id
        self.update = update
    }
}

public struct ReminderIDsArgs: Codable, Sendable, Equatable {
    public let ids: [String]

    public init(ids: [String]) {
        self.ids = ids
    }
}

public struct CountPayload: Codable, Sendable, Equatable {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }
}

public struct CalendarEventsArgs: Codable, Sendable, Equatable {
    public let start: Date
    public let end: Date
    public let calendarName: String?

    public init(start: Date, end: Date, calendarName: String?) {
        self.start = start
        self.end = end
        self.calendarName = calendarName
    }
}

public struct CalendarAddArgs: Codable, Sendable, Equatable {
    public let draft: EventDraft

    public init(draft: EventDraft) {
        self.draft = draft
    }
}

public struct CalendarDeleteArgs: Codable, Sendable, Equatable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public struct AppRequestEnvelope: Codable, Sendable {
    public let id: String
    public let op: String
    public let args: JSONValue?

    public init(id: String, op: String, args: JSONValue?) {
        self.id = id
        self.op = op
        self.args = args
    }
}

public struct AppErrorPayload: Codable, Sendable {
    public let code: String
    public let message: String
    public let details: JSONValue?

    public init(code: String, message: String, details: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

public struct AppResponseEnvelope: Codable, Sendable {
    public let id: String
    public let ok: Bool
    public let result: JSONValue?
    public let error: AppErrorPayload?

    public init(id: String, ok: Bool, result: JSONValue?, error: AppErrorPayload?) {
        self.id = id
        self.ok = ok
        self.result = result
        self.error = error
    }
}

public enum AppErrorCode: String, Sendable {
    case unavailable = "unavailable"
    case permissionDenied = "permission_denied"
    case validationFailed = "validation_failed"
    case notFound = "not_found"
    case internalFailure = "internal_failure"
    case bootstrapFailure = "bootstrap_failure"
}

public enum AppPaths {
    public static let appBundleName = "iCLI.app"
    public static let socketFilename = "icli.sock"

    public static func supportDirectory(fileManager: FileManager = .default) -> URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("icli", isDirectory: true)
    }

    public static func socketPath(fileManager: FileManager = .default) -> String {
        supportDirectory(fileManager: fileManager)
            .appendingPathComponent(socketFilename, isDirectory: false)
            .path
    }
}

public enum AppCodec {
    public static func makeEncoder(pretty: Bool = false) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

public enum JSONValue: Codable, Sendable, Equatable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: DynamicCodingKey.self) {
            var object: [String: JSONValue] = [:]
            for key in container.allKeys {
                object[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
            }
            self = .object(object)
            return
        }

        if var arrayContainer = try? decoder.unkeyedContainer() {
            var values: [JSONValue] = []
            while !arrayContainer.isAtEnd {
                values.append(try arrayContainer.decode(JSONValue.self))
            }
            self = .array(values)
            return
        }

        let single = try decoder.singleValueContainer()
        if single.decodeNil() {
            self = .null
        } else if let bool = try? single.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? single.decode(Int.self) {
            self = .number(Double(int))
        } else if let double = try? single.decode(Double.self) {
            self = .number(double)
        } else if let string = try? single.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.dataCorruptedError(in: single, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .object(let object):
            var container = encoder.container(keyedBy: DynamicCodingKey.self)
            for (key, value) in object {
                try container.encode(value, forKey: DynamicCodingKey(stringValue: key)!)
            }
        case .array(let array):
            var container = encoder.unkeyedContainer()
            for value in array {
                try container.encode(value)
            }
        case .string(let string):
            var container = encoder.singleValueContainer()
            try container.encode(string)
        case .number(let number):
            var container = encoder.singleValueContainer()
            try container.encode(number)
        case .bool(let bool):
            var container = encoder.singleValueContainer()
            try container.encode(bool)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }

    public static func encode<T: Encodable>(_ value: T) throws -> JSONValue {
        let data = try AppCodec.makeEncoder().encode(value)
        return try AppCodec.makeDecoder().decode(JSONValue.self, from: data)
    }

    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let data = try AppCodec.makeEncoder().encode(self)
        return try AppCodec.makeDecoder().decode(T.self, from: data)
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
