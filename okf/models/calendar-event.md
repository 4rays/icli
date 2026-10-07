---
type: Model
title: Calendar event
description: Calendar identities and events read and written through EventKit.
tags: [model, calendar, eventkit]
status: draft
generated: { by: pi/gpt-6.1-sol, at: 2026-10-07T09:41:32Z }
sources:
  - id: models
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Shared/Sources/Models.swift
    title: Shared models
  - id: store
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Sources/CalendarsStore.swift
    title: CalendarsStore
---

# Calendar

`CalendarInfo` has `id`, `title`, and `source`. `id` is `calendarIdentifier`. `source` is `EKSource.title`. The list is every calendar EventKit returns for `.event`.[^models][^store]

# Event

`CalendarEvent` has `id`, `title`, `startDate`, `endDate`, `isAllDay`, `location`, `notes`, `calendarID`, `calendarTitle`, and `url`. `id` is `calendarItemIdentifier`. Missing calendar identity becomes an empty string.[^models][^store]

# Draft

`EventDraft` requires `title`, `startDate`, `endDate`, and `isAllDay`. `calendarName`, `location`, `notes`, and `url` are optional.[^models]

On create, all-day events have start and end replaced with `Calendar.current.startOfDay` for those dates. Timed events keep the parsed dates. With no `calendarName`, the store uses `defaultCalendarForNewEvents`. A provided name must match a calendar title case- and diacritic-insensitively; otherwise create throws `calendarNotFound` and does not fall back to the default calendar.[^store]

Event queries use the same name comparison and also throw `calendarNotFound` when nothing matches. The predicate is `predicateForEvents(withStart:end:calendars:)`.[^store]

# Delete

Delete loads `calendarItem(withIdentifier:)` and removes it with span `.thisEvent`. A missing id is `eventNotFound`.[^store]

# Related

- [Calendar commands](/commands/calendar.md)
