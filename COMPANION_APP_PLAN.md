# iCLI Companion App Plan

## Summary
Build `icli` around a bundled macOS companion app instead of direct EventKit access from the CLI. The companion will be an `LSUIElement` utility app with a real bundle identity, and it will own both TCC authorization and all Reminders / Calendar EventKit operations. The CLI will remain the user-facing interface and will proxy requests to the app over a local Unix domain socket.

Before implementation begins, save this plan into `icli/` as the project plan artifact and create a baseline commit for the current `icli/` state plus the plan file. Implementation starts only after that checkpoint.

## Key Changes

### Architecture
- Add a new macOS app target, bundled alongside the existing `icli` executable.
- The app owns `EKEventStore`, authorization requests, and all reminder/calendar CRUD and list/read operations.
- The CLI stops calling EventKit directly for reminder/calendar work and becomes a request/response client for the companion.
- Do not use Bonjour. Use a fixed local socket path under the user domain, such as `~/Library/Application Support/icli/companion.sock`.

### IPC and command flow
- Define a small JSON protocol with a top-level operation name, arguments payload, success/error envelope, and typed response body.
- CLI behavior:
  - check whether the socket is available
  - if unavailable, launch the companion app
  - retry connection for a short bounded startup window
  - send request JSON
  - render response using existing `icli` output formatting
- Companion behavior:
  - start socket listener on launch
  - validate request shape
  - dispatch to reminder/calendar service handlers
  - return normalized JSON results and structured errors
- `icli auth request` becomes a proxy command that tells the app to request Reminders and/or Calendar access and then returns the post-request status from the app's point of view.

### Packaging and install
- Keep the existing CLI binary, but install/package it together with the companion `.app`.
- The app must include the usage descriptions and stable bundle identifier required for TCC.
- Update the install flow so the CLI can deterministically find the companion app path after installation.
- Favor one install root owned by `icli`, rather than assuming a separately user-installed app in `/Applications`.

### CLI surface and compatibility
- Preserve the current user-facing `icli` command structure and output formats.
- Internal behavior changes only:
  - reminder commands proxy to the app
  - calendar commands proxy to the app
  - auth commands query or trigger the app
- Keep non-EventKit commands local if any are added later; only EventKit-backed operations need the proxy path.

### Minimal companion UX
- Companion is an `LSUIElement` agent app, not a menu bar product and not a Dock app.
- Show UI only when needed:
  - first-launch/bootstrap failure
  - permission request flow if app activation is needed for visibility
  - unrecoverable socket/bootstrap errors
- No Bonjour discovery, no broad iMCP-style service UI, no user-facing feature surface beyond permissions/bootstrap.

## Public Interfaces / Contracts
- New bundled app target: `iCLI Companion.app` with a stable bundle identifier.
- New local IPC contract:
  - request: `{ "id": "...", "op": "...", "args": { ... } }`
  - success: `{ "id": "...", "ok": true, "result": ... }`
  - failure: `{ "id": "...", "ok": false, "error": { "code": "...", "message": "...", "details": ... } }`
- Initial operation families:
  - `auth.status`
  - `auth.request`
  - `reminder.list`
  - `reminder.add`
  - `reminder.edit`
  - `reminder.complete`
  - `reminder.delete`
  - `calendar.list`
  - `calendar.events`
  - `calendar.add`
  - `calendar.delete`
- Error contract should distinguish:
  - companion unavailable
  - permission denied / not granted
  - validation failure
  - domain object not found
  - internal EventKit failure

## Test Plan
- Build validation:
  - package builds both CLI and companion targets successfully
  - install layout places the CLI and app where the CLI can find the app deterministically
- Authorization scenarios:
  - fresh machine / reset TCC: `icli auth request --reminders` causes the app to request access and returns updated status
  - same for calendars
  - denied access returns a stable, actionable error without hanging
- Proxy scenarios:
  - companion not running: CLI launches it and request succeeds or fails with a bounded timeout
  - companion already running: CLI connects directly
  - socket stale/corrupt: CLI recovers by relaunching or surfaces a clear bootstrap error
- Functional parity:
  - existing reminder/calendar commands continue to produce the same human/json/plain outputs
  - not-found and validation errors still map cleanly to current CLI messaging
- Regression checks:
  - `auth status` reports app-owned authorization state
  - CLI no longer directly imports or depends on EventKit for reminder/calendar command execution paths

## Assumptions and defaults
- Chosen default scope: the companion owns full EventKit backend responsibilities, not auth-only.
- Chosen IPC: Unix domain socket, not Bonjour, XPC, or temp-file handoff.
- Chosen app style: `LSUIElement` utility app with minimal UI.
- Default plan artifact path: `icli/COMPANION_APP_PLAN.md`.
- Pre-implementation checkpoint commit should contain only the current `icli/` state plus the saved plan artifact, with no implementation changes mixed in.
