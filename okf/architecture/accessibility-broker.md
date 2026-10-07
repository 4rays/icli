---
type: Implementation Plan
title: Accessibility and computer-use broker
description: Extend iCLI.app to perform permissioned macOS UI actions on behalf of CLI and local-process clients.
tags: [architecture, accessibility, permissions, computer-use]
status: draft
generated: { by: pi/gpt-6.1-sol, at: 2026-10-07T09:41:32Z }
sources:
  - id: runtime
    resource: /architecture/runtime.md
    title: Existing CLI and companion-app runtime
  - id: ipc
    resource: /architecture/ipc.md
    title: Existing JSON IPC contract
  - id: server
    resource: ../../App/Sources/AppServer.swift
    title: Local socket server
  - id: client
    resource: ../../CLI/Sources/Core/AppClient.swift
    title: App launch and request retry behavior
  - id: entitlements
    resource: ../../icli.entitlements
    title: App entitlements
  - id: apple-ax
    resource: https://developer.apple.com/documentation/applicationservices/axuielement
    title: AXUIElement
  - id: apple-events
    resource: https://developer.apple.com/documentation/coregraphics/cgpreflightposteventaccess()
    title: Event-posting access check
  - id: apple-capture
    resource: https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-in-macos
    title: ScreenCaptureKit and Screen Recording permission
---

# Goal

Allow agents, scripts, and other local processes to request macOS UI inspection and actions through iCLI without holding Accessibility permissions themselves. The user grants permissions to iCLI.app; the app performs protected operations on the caller's behalf.

This is permission brokering, not permission inheritance. Clients do not acquire permission to call protected APIs directly.

```text
Agent / script / local process
        ↓ CLI or local Unix socket
     iCLI.app ← user grants permissions here
        ↓ Accessibility / input / screen capture
     Other macOS apps
```

# Existing foundation

- Reuse the background companion app, CLI-driven launch through LaunchServices, local Unix socket, and JSON request/response envelopes.[^runtime][^ipc][^client]
- Keep protected calls in the companion-app process, not in the CLI or arbitrary subprocesses.
- The checked-in entitlements do not enable App Sandbox. Keep the general cross-app Accessibility broker non-sandboxed; retain Developer ID signing and Hardened Runtime.[^entitlements]
- Existing Calendar and Reminders operations remain available and retain their permission model.

# Implementation sequence

## 1. Validate the permission boundary

1. Add Accessibility status and request handling to the app with `AXIsProcessTrustedWithOptions` and `kAXTrustedCheckOptionPrompt`.
2. Show the actual trust status in the app settings and CLI authorization output. A prompt is asynchronous and does not mean access has been granted.
3. Inspect and press a harmless control in another app using native Accessibility APIs.
4. Invoke those operations from a caller without Accessibility permission; verify that the grant belongs to iCLI.app and that the caller remains unprivileged.
5. Separately validate synthesized mouse/keyboard input and screen capture, including their permission-denied paths.

Complete this gate before committing to the larger command contract. Permission attribution across supported macOS versions and launch contexts must be validated, not assumed.

## 2. Establish the broker trust boundary

- Explicitly restrict the support directory and socket to the owning user and verify the peer user before handling requests.
- Bound request sizes, connection lifetimes, and concurrent work. The current server reads requests to EOF without a request-size bound or explicit peer authorization.[^server]
- Provide a user-controlled enable/disable switch for computer-use operations.
- Resolve the client trust policy before exposing UI mutations: all same-user processes or explicitly approved clients/sessions. Neither policy is selected by this plan.
- Do not treat a token readable by every same-user process as isolation between those processes.
- Do not expose arbitrary code or shell execution as a substitute for typed computer-use operations.

## 3. Add Accessibility inspection and semantic actions

Implement an app-side backend using `AXUIElement` APIs.[^apple-ax]

- List running apps and windows.
- Return bounded UI-tree snapshots containing roles, labels, supported values, bounds, and available actions.
- Inspect or locate elements and perform supported actions such as press and focus.
- Change attributes only where the target exposes them as writable.
- Retain Accessibility references in the app and return opaque, temporary element handles. Expired or invalid handles require a fresh inspection.
- Bound traversal depth, element count, and Accessibility messaging timeouts so an unresponsive target cannot stall the broker indefinitely.

Prefer semantic element actions over coordinate clicks when the target supports them.

## 4. Add input and visual fallback

- Synthesize click, drag, scroll, text entry, and keyboard shortcuts in the app process.
- Check event-posting access with `CGPreflightPostEventAccess`; request access when needed.[^apple-events]
- Add screenshots through ScreenCaptureKit, with a separate Screen Recording authorization flow.[^apple-capture]
- Include explicit target-app activation and display-coordinate metadata so callers can map screenshot pixels to desktop coordinates.
- Serialize desktop control so multiple callers cannot interleave input. Define the control-session contract before implementing multi-client action sequences.

Input Monitoring is not normally needed merely to send input. Apple Events Automation permissions are relevant only if AppleScript-based control is introduced; it is not part of this plan.

## 5. Extend IPC and CLI

Add typed operation arguments and results in `Shared/Sources/IPC.swift`, dispatch them in `App/Sources/AppRequestHandler.swift`, and expose CLI commands that forward to the app.

Illustrative command surface, not an approved or implemented contract:

```sh
icli auth request --accessibility
icli ui apps --json
icli ui snapshot --app com.apple.finder --json
icli ui press <element-handle>
icli ui type "Hello"
icli ui key cmd+s
icli ui screenshot
```

Extend `App/Sources/AppAuthorization.swift`, the authorization payloads and commands, and the settings UI for the new permission statuses. Link ApplicationServices, CoreGraphics, and ScreenCaptureKit as needed in `App/Project.swift`.

## 6. Prevent duplicated mutations

The current client retries after transport failures. A UI action may have succeeded before its response was lost, so replaying it could click or type twice.[^client]

Before enabling mutations, choose and implement either request-ID deduplication with defined retention semantics or no automatic mutation retry with an explicit outcome-unknown result. Require fresh inspection when the outcome cannot be established.

# Acceptance criteria

- An unpermissioned caller can inspect and operate a harmless control through the permissioned app without gaining direct Accessibility access.
- Revoking the app's Accessibility access prevents Accessibility operations and reports a permission error.
- Screenshots require their own applicable capture authorization; Accessibility access alone does not imply Screen Recording access.
- Input targets the intended foreground app and uses documented coordinate metadata.
- Invalid element handles and unresponsive target apps produce bounded failures.
- A lost response cannot silently cause an action to execute twice.
- Broker access follows the selected client policy, and disabling computer use prevents new actions.
- Concurrent clients cannot interleave desktop-control sequences.
- Calendar and Reminders workflows continue to work.

# Constraints

- Incomplete Accessibility trees require visual/input fallback and may still prevent reliable automation.
- Protected content and security-sensitive system UI may remain inaccessible.
- General keyboard/mouse control requires an active, unlocked GUI session; this is not a headless or login-window automation service.
- Sandboxed callers still need a permitted way to reach the broker.
- Accessibility does not grant Full Disk Access, camera, microphone, or other unrelated permissions.

# Related

- [Runtime](/architecture/runtime.md)
- [IPC](/architecture/ipc.md)
- [Authorization](/models/authorization.md)
- [Permissions](/operations/permissions.md)

[^runtime]: Existing CLI and companion-app runtime.
[^ipc]: Existing JSON IPC contract.
[^server]: Local socket server implementation.
[^client]: App launch and request retry implementation.
[^entitlements]: Checked-in companion-app entitlements.
[^apple-ax]: Apple AXUIElement documentation.
[^apple-events]: Apple event-posting access API.
[^apple-capture]: Apple ScreenCaptureKit sample and permission requirements.
