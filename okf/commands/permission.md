---
type: CLI
title: Permission commands
description: Commands that report, request, or reset Reminders and Calendar access, and that open settings.
tags: [cli, permissions, tcc]
status: draft
generated: { by: pi/gpt-6.1-sol, at: 2026-10-07T09:41:32Z }
sources:
  - id: router
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/CommandRouter.swift
    title: CommandRouter
  - id: permission
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/AuthCommand.swift
    title: PermissionCommand
  - id: request
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Auth/AuthRequestCommand.swift
    title: PermissionRequestCommand
  - id: reset
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Auth/PermissionResetCommand.swift
    title: PermissionResetCommand
  - id: status
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Auth/AuthStatusCommand.swift
    title: StatusCommand
  - id: settings
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Auth/AuthSettingsCommand.swift
    title: PermissionSettingsCommand
---

# Commands

| Invocation | What it does |
| --- | --- |
| `icli status` | Sends `auth.status` and prints both service statuses. |
| `icli permission request` | Sends `auth.request` for both services unless a filter flag is set. |
| `icli permission reset` | Runs `tccutil reset` locally. It does not send an IPC operation. |
| `icli settings` | Sends `app.showSettings`. |

`permission` help lists `request` and `reset` only. `settings` is not a permission subcommand.[^permission][^router]

# request

`--reminders` or `--reminder` requests only Reminders. `--calendars` or `--calendar` requests only Calendars. With neither flag, both are requested. The command exits 1 when either reported status is `denied`, `restricted`, `write-only`, `not-determined`, or `unknown`. `skipped` is not in that failure set, so a one-service request can still exit 0 while the other service is `skipped`.[^request]

The app only calls EventKit's request API when the live status is `notDetermined`. Otherwise it returns the current label. Before requesting, it activates the app.[^request]

# reset

`icli permission reset` runs `/usr/bin/tccutil reset Reminders net.4rays.icli` and the same for `Calendar`. It does not check `tccutil`'s exit status. Human output says to relaunch iCLI and then run `icli permission request`.[^reset]

# status and settings

Human status prints `Reminders: <status>` and `Calendars: <status>`. Plain prints two `service<tab>status` lines. JSON prints those two keys unless `ICLI_DEBUG_APP=1`, in which case the full payload including `app` is encoded.[^status]

`icli settings` prints `Opened iCLI settings.`, `opened\ttrue`, or `{"opened":true}`.[^settings]

# Related

- [Authorization](/models/authorization.md)
- [Permissions](/operations/permissions.md)
