---
type: Model
title: Authorization
description: Reminders and Calendars TCC status values the app reports to the CLI.
tags: [model, tcc, permissions]
status: draft
generated: { by: grok/okf, at: 2026-10-07T09:08:47Z }
sources:
  - id: ipc
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Shared/Sources/IPC.swift
    title: Authorization status types
  - id: auth
    resource: /Users/kaishin/Developer/Spikes/icli/icli/App/Sources/AppAuthorization.swift
    title: AppAuthorization
  - id: entitlements
    resource: /Users/kaishin/Developer/Spikes/icli/icli/icli.entitlements
    title: App entitlements
---

# Status values

`AuthorizationStatus` raw values are `authorized`, `not-determined`, `denied`, `restricted`, `write-only`, `skipped`, and `unknown`.[^ipc]

`AuthStatusPayload` carries `reminders`, `calendars`, and optional `app` diagnostics: process id, bundle identifier, bundle path, and executable path.[^ipc]

# Mapping

EventKit status maps as:[^auth]

| EventKit | Reported |
| --- | --- |
| `fullAccess`, `authorized` | `authorized` |
| `notDetermined` | `not-determined` |
| `denied` | `denied` |
| `restricted` | `restricted` |
| `writeOnly` | `write-only` |
| unknown | `unknown` |

`skipped` is the CLI-side default for a service that `auth.request` was not asked to request. It is not an EventKit status.[^auth]

# Cache

The app keeps an in-process cache of the last non-`notDetermined`, non-`skipped` request result. Status reporting prefers the live EventKit value unless live is `notDetermined` and the cache has a different value. A comment in `AppAuthorization` says `authorizationStatus(for:)` can stay stale `notDetermined` in-process on macOS 26 beta after a grant.[^auth]

Store access checks treat `fullAccess` and `authorized` as granted. A live `notDetermined` is also treated as granted when the cache says `authorized`.[^auth]

# Entitlements

The app entitlements file enables `com.apple.security.personal-information.calendars` and `com.apple.security.personal-information.reminders`.[^entitlements]

# Related

- [Permissions](/operations/permissions.md)
