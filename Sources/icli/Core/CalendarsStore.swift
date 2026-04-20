import EventKit
import Foundation

actor CalendarsStore {
    private let eventStore = EKEventStore()

    nonisolated func requestAccess() throws {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            break
        default:
            throw ICLIError.accessDenied("Calendars. Run 'icli auth request' first")
        }
    }

    static func authorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func calendars() -> [CalendarInfo] {
        eventStore.calendars(for: .event).map {
            CalendarInfo(id: $0.calendarIdentifier, title: $0.title, source: $0.source.title)
        }
    }

    func events(start: Date, end: Date, calendarName: String? = nil) throws -> [CalendarEvent] {
        var cals = eventStore.calendars(for: .event)
        if let name = calendarName {
            cals = cals.filter { $0.title.lowercased() == name.lowercased() }
            if cals.isEmpty { throw ICLIError.calendarNotFound(name) }
        }
        let pred = eventStore.predicateForEvents(withStart: start, end: end, calendars: cals)
        return eventStore.events(matching: pred).map { makeEvent($0) }
    }

    func createEvent(_ draft: EventDraft) throws -> CalendarEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = draft.title
        event.isAllDay = draft.isAllDay
        event.location = draft.location
        event.notes = draft.notes
        event.url = draft.url

        if draft.isAllDay {
            let cal = Calendar.current
            event.startDate = cal.startOfDay(for: draft.startDate)
            event.endDate = cal.startOfDay(for: draft.endDate)
        } else {
            event.startDate = draft.startDate
            event.endDate = draft.endDate
        }

        var targetCal = eventStore.defaultCalendarForNewEvents
        if let name = draft.calendarName {
            if let match = eventStore.calendars(for: .event)
                .first(where: { $0.title.lowercased() == name.lowercased() }) {
                targetCal = match
            }
        }
        event.calendar = targetCal

        try eventStore.save(event, span: .thisEvent, commit: true)
        return makeEvent(event)
    }

    func deleteEvent(id: String) throws {
        guard let event = eventStore.calendarItem(withIdentifier: id) as? EKEvent else {
            throw ICLIError.eventNotFound(id)
        }
        try eventStore.remove(event, span: .thisEvent, commit: true)
    }

    // MARK: - Private

    private func makeEvent(_ e: EKEvent) -> CalendarEvent {
        CalendarEvent(
            id: e.calendarItemIdentifier,
            title: e.title ?? "",
            startDate: e.startDate,
            endDate: e.endDate,
            isAllDay: e.isAllDay,
            location: e.location,
            notes: e.notes,
            calendarID: e.calendar?.calendarIdentifier ?? "",
            calendarTitle: e.calendar?.title ?? "",
            url: e.url
        )
    }
}
