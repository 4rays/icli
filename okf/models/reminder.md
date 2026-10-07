---
type: Model
title: Reminder
description: Reminder lists, items, drafts, and updates passed between the CLI and EventKit.
tags: [model, reminders, eventkit]
status: draft
generated: { by: grok/okf, at: 2026-10-07T09:40:00Z }
sources:
  - id: models
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Shared/Sources/Models.swift
    title: Shared models
  - id: store
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Sources/RemindersStore.swift
    title: RemindersStore
---

# List

`ReminderList` has `id`, `title`, `reminderCount`, and `overdueCount`.[^models]

`id` is the EventKit calendar identifier. Counts include only incomplete reminders. A reminder is overdue when its due date is before the start of today in the store's calendar. Reminders with no due date are not overdue.[^store]

# Item

`ReminderItem` fields:[^models]

| Field | Role |
| --- | --- |
| `id` | `EKReminder.calendarItemIdentifier` |
| `title` | Reminder title, or empty string when EventKit has none |
| `notes` | Optional |
| `isCompleted` | Completion flag |
| `completionDate` | Set by EventKit when completed |
| `priority` | `none`, `low`, `medium`, or `high` |
| `dueDate` | Date reconstructed from due-date components |
| `listID` | Reminder calendar identifier |
| `listName` | Reminder calendar title |
| `url` | Optional |

# Priority

EventKit integer ranges map to the four labels, and the labels write back a single integer:[^models]

| Label | Read from EventKit | Written to EventKit |
| --- | --- | --- |
| `high` | 1...4 | 1 |
| `medium` | 5 | 5 |
| `low` | 6...9 | 9 |
| `none` | anything else | 0 |

# Draft and update

`ReminderDraft` requires `title` and `priority`. `notes`, `dueDate`, and `url` are optional.[^models]

`ReminderUpdate` is partial. `clearDueDate` and `clearURL` default to false. Setting `clearDueDate` removes due-date components; a non-nil `dueDate` writes year, month, day, hour, and minute components. `listName` moves the reminder to a reminder calendar with that exact title.[^store]

# Lookup

List names are matched case- and diacritic-insensitively. If no `--list` is given on add, the store uses `defaultCalendarForNewReminders()`. If that is missing, it fails with "No default list. Specify --list <name>." A missing id fails as `reminderNotFound`.[^store]

Listing uses `predicateForReminders(in:)`. Without `--completed`, completed items are filtered out after fetch.[^store]

# Related

- [Reminder commands](/commands/reminder.md)
