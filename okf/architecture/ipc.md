---
type: API
title: IPC
description: JSON request and response envelopes exchanged over the local Unix socket between icli and iCLI.app.
tags: [api, ipc, json]
status: draft
generated: { by: pi/gpt-6.1-sol, at: 2026-10-07T09:41:32Z }
sources:
  - id: ipc
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Shared/Sources/IPC.swift
    title: IPC models
  - id: handler
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Sources/AppRequestHandler.swift
    title: AppRequestHandler
  - id: codec
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Shared/Sources/IPC.swift
    title: AppCodec
---

# Envelope

Dates in IPC JSON use ISO 8601.[^codec]

A request is `AppRequestEnvelope`:[^ipc]

| Field | Meaning |
| --- | --- |
| `id` | Caller-chosen string. The CLI uses a UUID string. |
| `op` | `AppOperation` raw value. |
| `args` | JSON value, or omitted for operations that take `EmptyArgs`. |

A response is `AppResponseEnvelope`:[^ipc]

| Field | Meaning |
| --- | --- |
| `id` | Echoes the request id on the success and mapped-error paths. |
| `ok` | `true` when `result` is set. |
| `result` | Encoded payload, or absent on failure. |
| `error` | `AppErrorPayload` with `code`, `message`, and optional `details`. |

# Operations

| `op` | Args | Result |
| --- | --- | --- |
| `app.showSettings` | none | empty |
| `auth.status` | none | `AuthStatusPayload` |
| `auth.request` | `AuthRequestArgs` | `AuthStatusPayload` |
| `reminder.list` | `ReminderListArgs` | `[ReminderItem]` |
| `reminder.lists` | none | `[ReminderList]` |
| `reminder.add` | `ReminderAddArgs` | `ReminderItem` |
| `reminder.edit` | `ReminderEditArgs` | `ReminderItem` |
| `reminder.complete` | `ReminderIDsArgs` | `CountPayload` |
| `reminder.delete` | `ReminderIDsArgs` | `CountPayload` |
| `calendar.list` | none | `[CalendarInfo]` |
| `calendar.events` | `CalendarEventsArgs` | `[CalendarEvent]` |
| `calendar.add` | `CalendarAddArgs` | `CalendarEvent` |
| `calendar.delete` | `CalendarDeleteArgs` | `CountPayload` with `count` 1 |

Unknown `op` values fail as invalid arguments. Reminder and calendar operations call `requestAccess()` before store work.[^handler]

# Error codes

`AppErrorCode` values are `unavailable`, `permission_denied`, `validation_failed`, `not_found`, `internal_failure`, and `bootstrap_failure`.[^ipc]

The handler maps `ICLIError` as follows:[^handler]

| Error | Code |
| --- | --- |
| `accessDenied` | `permission_denied` |
| `listNotFound`, `reminderNotFound`, `calendarNotFound`, `eventNotFound` | `not_found` |
| `missingArgument`, `invalidArgument` | `validation_failed` |
| `operationFailed` | `internal_failure` |
| any other `Error` | `internal_failure` |

The CLI does not branch on those codes. It throws `operationFailed` with `error.message` whenever `ok` is false.[^ipc]

# Related

- [CLI surface](/commands/cli.md)
- [Authorization](/models/authorization.md)
