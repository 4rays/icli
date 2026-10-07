---
type: Playbook
title: Permissions
description: How iCLI requests Calendar and Reminders access and what the CLI reports when access is missing.
tags: [playbook, tcc, permissions]
status: draft
generated: { by: grok/okf, at: 2026-10-07T09:40:00Z }
sources:
  - id: readme
    resource: /Users/kaishin/Developer/Spikes/icli/icli/README.md
    title: README
  - id: auth
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Sources/AppAuthorization.swift
    title: AppAuthorization
  - id: stores
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Sources/RemindersStore.swift
    title: EventKit stores
  - id: models
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Shared/Sources/Models.swift
    title: ICLIError
---

# First run

The README says the first run prompts for Calendar and Reminders access and both should be granted.[^readme]

The prompt is attached to `iCLI.app`, not the CLI. Store methods call `requestFullAccessToReminders()` and `requestFullAccessToEvents()`. A false or thrown result becomes `accessDenied` for "Reminders" or "Calendars".[^stores]

The denial message tells the user to run `icli permission request`.[^models]

# Check and grant

1. `icli status` prints both statuses.
2. `icli permission request` asks for both when neither service flag is passed.
3. `icli permission request --reminders` or `--calendars` limits the prompt to one service.
4. `icli settings` opens the app's settings window, which also shows access state.

If EventKit already has a status other than `notDetermined`, request does not show the system prompt again. It returns the current status. Reset is a separate step. See [Permission commands](/commands/permission.md).

# Related

- [Authorization](/models/authorization.md)
- [Reset runtime](/operations/reset-runtime.md)
