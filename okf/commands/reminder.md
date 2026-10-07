---
type: CLI
title: Reminder commands
description: icli reminder subcommands for listing, adding, editing, completing, and deleting reminders.
tags: [cli, reminders]
status: draft
generated: { by: pi/gpt-6.1-sol, at: 2026-10-07T09:41:32Z }
sources:
  - id: group
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/ReminderCommand.swift
    title: ReminderCommand
  - id: add
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Reminder/ReminderAddCommand.swift
    title: ReminderAddCommand
  - id: edit
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Reminder/ReminderEditCommand.swift
    title: ReminderEditCommand
  - id: list
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Reminder/ReminderListCommand.swift
    title: ReminderListCommand
  - id: complete
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Reminder/ReminderCompleteCommand.swift
    title: ReminderCompleteCommand
  - id: delete
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Reminder/ReminderDeleteCommand.swift
    title: ReminderDeleteCommand
  - id: output
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Core/Output.swift
    title: Output
---

# Subcommands

| Command | Aliases | Wire `op` |
| --- | --- | --- |
| `list` | `ls` | `reminder.list` |
| `lists` | none | `reminder.lists` |
| `add` | none | `reminder.add` |
| `complete` | `done` | `reminder.complete` |
| `delete` | `rm`, `remove` | `reminder.delete` |
| `edit` | none | `reminder.edit` |

# list

`icli reminder list [--list <name>] [--completed]`

`--list` / `-l` filters by list title, case- and diacritic-insensitively. `--completed` / `-c` includes completed reminders. Without it, only incomplete reminders are returned.[^list]

Human lines look like `- Title  [List]`, with `x` instead of `-` when completed, `due <medium date, short time>` when a due date exists, `⚠ overdue` when an incomplete due date is before now, `(priority)` when priority is not `none`, and the URL when present.[^output]

Plain columns, tab-separated: `id`, `listName`, `1` or `0`, priority, ISO 8601 due date or empty, ISO 8601 completion date or empty, title.[^output]

# lists

`icli reminder lists` prints list title plus incomplete and overdue counts. Plain columns: `id`, `title`, `reminderCount`, `overdueCount`. Both human and plain sort by title.[^output]

# add

`icli reminder add <title> [--list <name>] [--due <date>] [--notes <text>] [--priority none|low|medium|high] [--url <url>]`

Title comes from `--title` / `-t` or the first positional. `--list` / `-l`, `--due` / `-d`, `--notes` / `-n`, `--priority` / `-p`, and `--url` / `-u` are optional. Omitted priority is `none`. An unparseable date or priority fails before the request. `--url` uses `URL(string:)`, so a non-empty string that Foundation accepts is sent.[^add]

Human output prints `Added: <title>  [<list>]` and a due line when present. Plain prints the new id. JSON prints the `ReminderItem`.[^add]

# edit

`icli reminder edit <id> [--title <t>] [--list <name>] [--due <date|none>] [--notes <t>] [--priority <p>] [--url <url|none>]`

`--due none` sets `clearDueDate`. `--url none` sets `clearURL`. Other supplied flags patch those fields only. The command does not expose a completion flag, even though `ReminderUpdate.isCompleted` exists on the wire model.[^edit]

# complete and delete

Both take one or more positional ids. Complete marks each reminder completed and prints the count. Delete removes each reminder and prints the count. JSON for complete encodes an empty reminder array, not the count. JSON for delete encodes `{"deleted": <count>}`.[^complete][^delete]

# Related

- [Reminder](/models/reminder.md)
- [Date parsing](/commands/date-parsing.md)
