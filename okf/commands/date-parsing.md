---
type: Reference
title: Date parsing
description: Date and time strings DateParsing accepts for reminder due dates and calendar start and end flags.
tags: [cli, dates]
status: draft
generated: { by: grok/okf, at: 2026-10-07T09:08:47Z }
sources:
  - id: parser
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Shared/Sources/DateParsing.swift
    title: DateParsing
---

# Accepted input

`DateParsing.parseUserDate` trims the string, then tries, in order:[^parser]

1. Case-insensitive relative words: `today`, `tomorrow`, `yesterday`, `now`.
2. ISO 8601 internet date-time, with fractional seconds, then without.
3. `yyyy-MM-dd`
4. `yyyy-MM-dd HH:mm`
5. `yyyy-MM-dd HH:mm:ss`
6. `MM/dd/yyyy`
7. `MM/dd/yyyy HH:mm`
8. `dd-MM-yy`
9. `dd-MM-yyyy`

Relative dates except `now` are the start of that local day. `now` is the current instant. The fixed formats use `en_US_POSIX` and the current time zone.[^parser]

Anything else returns nil, and the command reports `Cannot parse date`.

# Display

Human output uses the current locale and calendar time zone. Display is medium date plus short time. Date-only is medium date. Time-only is short time. Plain and JSON dates use ISO 8601 internet date-time without fractional seconds.[^parser]

# Related

- [Reminder commands](/commands/reminder.md)
- [Calendar commands](/commands/calendar.md)
