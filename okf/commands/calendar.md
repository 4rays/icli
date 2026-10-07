---
type: CLI
title: Calendar commands
description: icli calendar subcommands for listing calendars and events, and for adding or deleting one event.
tags: [cli, calendar]
status: draft
generated: { by: pi/gpt-6.1-sol, at: 2026-10-07T09:41:32Z }
sources:
  - id: group
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/CalendarCommand.swift
    title: CalendarCommand
  - id: events
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Calendar/CalendarEventsCommand.swift
    title: CalendarEventsCommand
  - id: add
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Calendar/CalendarAddCommand.swift
    title: CalendarAddCommand
  - id: delete
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Calendar/CalendarDeleteCommand.swift
    title: CalendarDeleteCommand
  - id: output
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Core/Output.swift
    title: Output
---

# Subcommands

| Command | Aliases | Wire `op` |
| --- | --- | --- |
| `list` | `ls` | `calendar.list` |
| `events` | none | `calendar.events` |
| `add` | none | `calendar.add` |
| `delete` | `rm`, `remove` | `calendar.delete` |

There is no edit command.

# list

`icli calendar list` prints `title  (source)`, sorted by title. Plain columns: `id`, `title`, `source`.[^output]

# events

`icli calendar events [--start <date>] [--end <date>] [--calendar <name>]`

`--start` / `-s` defaults to the start of today. `--end` / `-e` defaults to 7 days after the chosen start. `--calendar` / `-c` filters by title, case- and diacritic-insensitively. The end value is passed through as parsed; the CLI does not extend a date-only end to the end of that day.[^events]

Human output sorts by start. All-day lines use a medium date plus `All day`. Timed lines use a medium date and short time, then an en dash and the end time. Location is appended when non-empty. Plain columns: `id`, calendar title, ISO 8601 start, ISO 8601 end, `1` or `0`, location or empty, title.[^output]

# add

`icli calendar add <title> --start <datetime> --end <datetime> [--calendar <name>] [--location <text>] [--notes <text>] [--url <url>] [--all-day]`

`--start` / `-s` and `--end` / `-e` are required. Title is `--title` / `-t` or the first positional. `--all-day` and `--allday` set `isAllDay`. `--url` is optional and has no short flag; an unparseable string becomes a nil URL rather than an error.[^add]

# delete

`icli calendar delete <id>` sends one id. Human output is `Deleted event.`. Plain prints `1`. JSON prints `{"deleted": 1}`. The help text says the id comes from `icli calendar events --format json`; plain output also puts the id in the first column.[^delete][^group]

# Related

- [Calendar event](/models/calendar-event.md)
- [Date parsing](/commands/date-parsing.md)
