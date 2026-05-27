import EventKit
import Foundation

actor CalendarsStore {
    private let eventStore = EKEventStore()

    func requestAccess() async throws {
        let granted = (try? await eventStore.requestFullAccessToEvents()) ?? false
        guard granted else { throw ICLIError.accessDenied("Calendars") }
    }

    func calendars() -> [CalendarInfo] {
        eventStore.calendars(for: .event).map {
            CalendarInfo(id: $0.calendarIdentifier, title: $0.title, source: $0.source.title)
        }
    }

    func events(start: Date, end: Date, calendarName: String? = nil) throws -> [CalendarEvent] {
        var calendars = eventStore.calendars(for: .event)
        if let calendarName {
            calendars = calendars.filter { $0.title.lowercased() == calendarName.lowercased() }
            if calendars.isEmpty { throw ICLIError.calendarNotFound(calendarName) }
        }
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return eventStore.events(matching: predicate).map { makeEvent($0) }
    }

    func createEvent(_ draft: EventDraft) throws -> CalendarEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = draft.title
        event.isAllDay = draft.isAllDay
        event.location = draft.location
        event.notes = draft.notes
        event.url = draft.url

        if draft.isAllDay {
            let calendar = Calendar.current
            event.startDate = calendar.startOfDay(for: draft.startDate)
            event.endDate = calendar.startOfDay(for: draft.endDate)
        } else {
            event.startDate = draft.startDate
            event.endDate = draft.endDate
        }

        var targetCalendar = eventStore.defaultCalendarForNewEvents
        if let name = draft.calendarName {
            if let match = eventStore.calendars(for: .event)
                .first(where: { $0.title.lowercased() == name.lowercased() }) {
                targetCalendar = match
            }
        }
        event.calendar = targetCalendar

        try eventStore.save(event, span: .thisEvent, commit: true)
        return makeEvent(event)
    }

    func deleteEvent(id: String) throws {
        guard let event = eventStore.calendarItem(withIdentifier: id) as? EKEvent else {
            throw ICLIError.eventNotFound(id)
        }
        try eventStore.remove(event, span: .thisEvent, commit: true)
    }

    private func makeEvent(_ event: EKEvent) -> CalendarEvent {
        CalendarEvent(
            id: event.calendarItemIdentifier,
            title: event.title ?? "",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            location: event.location,
            notes: event.notes,
            calendarID: event.calendar?.calendarIdentifier ?? "",
            calendarTitle: event.calendar?.title ?? "",
            url: event.url
        )
    }
}
