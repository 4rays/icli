---
type: Product
title: iCLI
description: A macOS command-line interface for Apple Reminders and Calendar, backed by a companion app that holds TCC permissions.
tags: [product, macos, reminders, calendar]
resource: /Users/kaishin/Developer/Spikes/icli/icli/README.md
status: draft
generated: { by: grok/okf, at: 2026-10-07T09:40:00Z }
sources:
  - id: readme
    resource: /Users/kaishin/Developer/Spikes/icli/icli/README.md
    title: README
  - id: info-plist
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Info.plist
    title: App Info.plist
  - id: config
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Tuist/ProjectDescriptionHelpers/Config.swift
    title: Tuist project config
---

# What it is

iCLI is a local utility, not a hosted service. The user-facing binary is `icli`. A companion app bundle named `iCLI.app` holds Calendar and Reminders entitlements and performs EventKit work.[^readme]

The app is an accessory UI element (`LSUIElement`) with bundle identifier `net.4rays.icli`. Usage strings say the app manages reminders and calendar events from the terminal.[^info-plist]

# Platforms

| Source | Claim |
| --- | --- |
| README | macOS 14 (Sonoma) or later, Xcode 16 or later, Tuist to generate the workspace.[^readme] |
| Tuist config | Deployment target `macOS("15.0")`, destination `.mac`.[^config] |
| App Info.plist and CLI `--version` | `0.2.4`.[^info-plist] |

Those two floors are not reconciled in the sources.

# Distribution

The README documents two install paths:[^readme]

- Homebrew cask: `brew install --cask 4rays/tap/icli`
- From source: `make install`, which installs into `~/.local/lib/icli/` and symlinks `~/.local/bin/icli`

`TODO.md` describes a desired signed-and-notarized cask layout and a DMG path. Those items are unchecked plans, not current behavior. See [Install](/operations/install.md).

# Related

- [Runtime](/architecture/runtime.md)
- [CLI surface](/commands/cli.md)
