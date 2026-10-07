---
type: Architecture
title: Runtime
description: The CLI locates or launches iCLI.app and exchanges one JSON request per Unix-socket connection.
tags: [architecture, ipc, macos]
status: draft
generated: { by: grok/okf, at: 2026-10-07T09:08:47Z }
sources:
  - id: readme
    resource: /Users/kaishin/Developer/Spikes/icli/icli/README.md
    title: README
  - id: app-client
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Core/AppClient.swift
    title: AppClient
  - id: app-locator
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Shared/Sources/AppLocator.swift
    title: AppLocator
  - id: app-server
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Sources/AppServer.swift
    title: AppServer
  - id: app-delegate
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Sources/AppDelegate.swift
    title: AppDelegate
  - id: makefile
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Makefile
    title: Makefile
  - id: app-project
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Project.swift
    title: App Tuist project
---

# Split

`icli` is a thin CLI. `iCLI.app` holds the Calendar and Reminders entitlements and talks to EventKit. The CLI forwards commands and prints results.[^readme]

The app target depends on Shared and the `icli` CLI target. A post-build script copies the CLI binary into `iCLI.app/Contents/Resources/bin/icli`.[^app-project]

# Socket

The socket file is `icli.sock` under `~/Library/Application Support/icli`.[^makefile]

`AppServer` unlinks that path, binds an `AF_UNIX` `SOCK_STREAM` socket, and listens with backlog 16. Each accepted connection is read to EOF, decoded as one request, handled, and written back as one response. The server stops by closing the listen socket and unlinking the path.[^app-server]

# Launch

If the socket is not connectable, `AppClient` looks up the app and runs `/usr/bin/open -g <app> --args --icli-agent`, then waits up to 5 seconds for the socket. A failed request retries once after 0.15 seconds.[^app-client]

`--icli-agent` keeps the app from opening the settings window at launch. A normal launch, or a reopen, shows settings. Closing the last window does not terminate the app. The activation policy is `.accessory`.[^app-delegate]

# Discovery

`AppLocator` resolves the app in this order:[^app-locator]

1. `ICLI_APP`, when set and non-empty.
2. An `.app` bundle that contains the CLI executable.
3. A sibling `iCLI.app` next to the CLI executable.

If none of those exist, the client fails with "iCLI app not found. Reinstall icli or set ICLI_APP to the app bundle path."[^app-client]

`make install` places the CLI and `iCLI.app` side by side in `~/.local/lib/icli/` and symlinks `~/.local/bin/icli` to the CLI, so the sibling lookup matches that layout.[^makefile]

# Timeouts

`auth.request` waits up to 300 seconds for a response. Every other operation waits 30 seconds.[^app-client]

# Related

- [IPC](/architecture/ipc.md)
- [Permissions](/operations/permissions.md)
