---
name: icli
description: This skill should be used when the user asks to "add a reminder", "add an event", "list reminders", "list events", "complete a reminder",,"add to my calendar", "delete a reminder", "delete an event", "check permissions", "request permissions", "create a reminder", "create an event", "show reminders", "show calendar events", or any task involving managing Apple Reminders or Calendar from the terminal using icli.
version: 0.1.0
---

# icli

icli is a macOS menu bar app with a CLI for managing Apple Reminders and Calendar events. The CLI communicates with the app over a Unix socket — the iCLI app must be running.

## Command Structure

```
icli <group> <command> [options]

GROUPS:
  reminder    Manage Apple Reminders
  calendar    Manage Apple Calendar events
  permission  Manage system permissions
  status      Show permission status
```

Global option: `--format human|json|plain` (default: human)

---

## Reminders

### List reminders

```bash
icli reminder list                        # all incomplete reminders
icli reminder list --completed            # include completed
icli reminder list --list "Shopping"      # filter by list name
```

Output format: `- Title  [List]  due DATE  (priority)`

### List reminder lists

```bash
icli reminder lists
```

### Add a reminder

```bash
icli reminder add "Buy oat milk"
icli reminder add "Call dentist" --list "Health"
icli reminder add "Submit report" --due "2026-06-01 09:00" --priority high
icli reminder add "Read book" --notes "Start with chapter 3"
```

Options:
- `--list <name>` — target list (default: system default)
- `--due <datetime>` — due date, accepts natural formats: `"tomorrow"`, `"2026-06-01"`, `"2026-06-01 14:00"`
- `--priority low|medium|high`
- `--notes <text>`

### Complete a reminder

```bash
icli reminder complete <id>
icli reminder complete <id1> <id2> <id3>   # multiple at once
```

Get IDs from `icli reminder list --format plain` (first column).

### Edit a reminder

```bash
icli reminder edit <id> --title "New title"
icli reminder edit <id> --due "2026-07-01" --priority medium
icli reminder edit <id> --due none          # clear due date
icli reminder edit <id> --list "Work"       # move to different list
```

### Delete a reminder

```bash
icli reminder delete <id>
icli reminder delete <id1> <id2>
```

---

## Calendar

### List calendars

```bash
icli calendar list
```

### List events

```bash
icli calendar events                              # next 7 days
icli calendar events --start 2026-06-01           # from date
icli calendar events --start 2026-06-01 --end 2026-06-30
icli calendar events --calendar "Work"            # filter by calendar
```

### Add an event

```bash
icli calendar add "Team standup" --start "2026-06-02 09:00" --end "2026-06-02 09:30"
icli calendar add "Conference" --start 2026-06-10 --end 2026-06-12 --all-day
icli calendar add "Lunch" --start "2026-06-03 12:00" --end "2026-06-03 13:00" --calendar "Personal"
icli calendar add "Meeting" --start "2026-06-04 10:00" --end "2026-06-04 11:00" --location "Office" --notes "Bring laptop"
```

Options:
- `--start <datetime>` — required
- `--end <datetime>` — required
- `--calendar <name>` — target calendar
- `--all-day` — all-day event (use date only for start/end)
- `--location <text>`
- `--notes <text>`
- `--url <url>`

### Delete an event

```bash
icli calendar delete <id>
```

Get IDs from `icli calendar events --format plain` (first column).

---

## Permissions

```bash
icli status                        # check current permission status
icli permission request            # request both Reminders + Calendar
icli permission request --reminders
icli permission request --calendars
icli permission reset              # reset TCC permissions (then relaunch iCLI + re-request)
icli permission settings           # open iCLI settings window
```

---

## Getting IDs

To get reminder or event IDs for complete/edit/delete operations, use plain format:

```bash
icli reminder list --format plain   # tab-separated: id, list, completed, priority, due, completionDate, title
icli calendar events --format plain # tab-separated: id, calendar, start, end, allDay, location, title
```

The ID is always the first column.

## JSON Output

All commands support `--format json` for structured output — useful when scripting or piping to other tools.

```bash
icli reminder list --format json
icli calendar events --format json
```
