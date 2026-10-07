---
type: Playbook
title: Reset runtime
description: Developer reset that stops iCLI, deletes the socket, and clears TCC grants for the app bundle id.
tags: [playbook, development, tcc]
status: draft
generated: { by: grok/okf, at: 2026-10-07T09:08:47Z }
sources:
  - id: makefile
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Makefile
    title: Makefile
  - id: readme
    resource: /Users/kaishin/Developer/Spikes/icli/icli/README.md
    title: README
  - id: reset
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Commands/Auth/PermissionResetCommand.swift
    title: PermissionResetCommand
---

# make reset

`make reset` does three things:[^makefile]

1. `pkill -x iCLI`, ignoring failure.
2. Removes `~/Library/Application Support/icli/icli.sock`.
3. Runs `tccutil reset Reminders net.4rays.icli` and `tccutil reset Calendar net.4rays.icli`.

The README lists this target as "kill app, remove socket, reset TCC permissions".[^readme]

# CLI equivalent

`icli permission reset` runs the same two `tccutil reset` commands for `net.4rays.icli`. It does not kill the app or remove the socket. Its human message says to relaunch iCLI, then run `icli permission request`.[^reset]

# Related

- [Permissions](/operations/permissions.md)
- [Install](/operations/install.md)
