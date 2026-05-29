import Foundation

enum OutputFormat: String {
  case human, json, plain

  init?(_ raw: String) {
    self.init(rawValue: raw.lowercased())
  }
}

enum Output {
  // MARK: - Reminders

  static func printReminders(_ items: [ReminderItem], format: OutputFormat) {
    switch format {
    case .human:
      if items.isEmpty {
        print("No reminders found.")
        return
      }
      let now = Date()
      for item in items {
        let check = item.isCompleted ? "x" : "-"
        var line = "\(check) \(item.title)  [\(item.listName)]"
        if let due = item.dueDate {
          let tag = !item.isCompleted && due < now ? " ⚠ overdue" : ""
          line += "  due \(DateParsing.formatDisplay(due))\(tag)"
        }
        if item.priority != .none { line += "  (\(item.priority.rawValue))" }
        if let loc = item.location, !loc.isEmpty { line += "  📍 \(loc)" }
        if let url = item.url { line += "  🔗 \(url.absoluteString)" }
        print(line)
      }
    case .plain:
      for item in items {
        let due = item.dueDate.map { isoString($0) } ?? ""
        let completed = item.completionDate.map { isoString($0) } ?? ""
        print(
          [
            item.id, item.listName, item.isCompleted ? "1" : "0",
            item.priority.rawValue, due, completed, item.title
          ]
          .joined(separator: "\t"))
      }
    case .json:
      printJSON(items)
    }
  }

  static func printReminderLists(_ lists: [ReminderList], format: OutputFormat) {
    switch format {
    case .human:
      if lists.isEmpty {
        print("No reminder lists found.")
        return
      }
      for list in lists.sorted(by: { $0.title < $1.title }) {
        var line = list.title
        if list.reminderCount > 0 {
          line += "  \(list.reminderCount) reminder(s)"
          if list.overdueCount > 0 { line += ", \(list.overdueCount) overdue" }
        }
        print(line)
      }
    case .plain:
      for list in lists.sorted(by: { $0.title < $1.title }) {
        print(
          [
            list.id, list.title,
            String(list.reminderCount), String(list.overdueCount)
          ]
          .joined(separator: "\t"))
      }
    case .json:
      printJSON(lists)
    }
  }

  // MARK: - Calendars

  static func printCalendars(_ calendars: [CalendarInfo], format: OutputFormat) {
    switch format {
    case .human:
      if calendars.isEmpty {
        print("No calendars found.")
        return
      }
      for cal in calendars.sorted(by: { $0.title < $1.title }) {
        print("\(cal.title)  (\(cal.source))")
      }
    case .plain:
      for cal in calendars.sorted(by: { $0.title < $1.title }) {
        print([cal.id, cal.title, cal.source].joined(separator: "\t"))
      }
    case .json:
      printJSON(calendars)
    }
  }

  static func printEvents(_ events: [CalendarEvent], format: OutputFormat) {
    switch format {
    case .human:
      if events.isEmpty {
        print("No events found.")
        return
      }
      let sorted = events.sorted { $0.startDate < $1.startDate }
      for event in sorted {
        let dateStr: String
        if event.isAllDay {
          dateStr = DateParsing.formatDate(event.startDate) + "  All day"
        } else {
          dateStr =
            DateParsing.formatDisplay(event.startDate)
            + " – " + DateParsing.formatTime(event.endDate)
        }
        var line = "\(dateStr)  \(event.title)  [\(event.calendarTitle)]"
        if let loc = event.location, !loc.isEmpty { line += "  📍 \(loc)" }
        print(line)
      }
    case .plain:
      for event in events.sorted(by: { $0.startDate < $1.startDate }) {
        let loc = event.location ?? ""
        print(
          [
            event.id, event.calendarTitle, isoString(event.startDate),
            isoString(event.endDate), event.isAllDay ? "1" : "0",
            loc, event.title
          ]
          .joined(separator: "\t"))
      }
    case .json:
      printJSON(events)
    }
  }

  // MARK: - Auth

  static func printAuthStatus(_ payload: AuthStatusPayload, format: OutputFormat) {
    let debugApp = ProcessInfo.processInfo.environment["ICLI_DEBUG_APP"] == "1"

    switch format {
    case .human:
      print("Reminders: \(payload.reminders)")
      print("Calendars: \(payload.calendars)")
      if debugApp, let app = payload.app {
        print("App PID: \(app.processID)")
        print("App bundle ID: \(app.bundleIdentifier ?? "<none>")")
        print("App bundle: \(app.bundlePath ?? "<none>")")
        print("App executable: \(app.executablePath ?? "<none>")")
      }
    case .plain:
      print("reminders\t\(payload.reminders)")
      print("calendars\t\(payload.calendars)")
    case .json:
      if debugApp {
        printJSON(payload)
      } else {
        let output: [String: String] = [
          "reminders": payload.reminders.rawValue,
          "calendars": payload.calendars.rawValue
        ]
        printJSON(output)
      }
    }
  }

  // MARK: - Errors / helpers

  static func printError(_ message: String) {
    var stderr = FileHandle.standardError
    print("Error: \(message)", to: &stderr)
  }

  // MARK: - Private

  private static func printJSON<T: Encodable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    do {
      let data = try encoder.encode(value)
      if let str = String(data: data, encoding: .utf8) { print(str) }
    } catch {
      printError("JSON encoding failed: \(error.localizedDescription)")
    }
  }

  private static func isoString(_ date: Date) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f.string(from: date)
  }
}

extension FileHandle: @retroactive TextOutputStream {
  public func write(_ string: String) {
    if let data = string.data(using: .utf8) { write(data) }
  }
}
