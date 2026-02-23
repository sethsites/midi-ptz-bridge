# MIDI-PTZ Status Bar App Design

Date: 2026-02-23

## Summary
A native macOS status bar app that listens to CoreMIDI notes from multiple named sources and translates them into vendor-specific PTZ camera HTTP commands. The menu bar flashes green on success and red on failure, shows the last 5 events, and provides a configuration window for MIDI sources, cameras, rule-based mappings, and commands. Activity is logged to a rotating log file.

## Goals
- Listen to multiple CoreMIDI sources (by name).
- Map MIDI note + on/off + velocity conditions to PTZ HTTP commands via simple rules.
- Configure PTZ cameras (name, IP, username, password) stored in app config.
- Show activity in the menu bar with success/failure flashes.
- Maintain a persistent log file with size cap and rotate.
- Provide a configuration UI for all settings.

## Non-Goals
- ONVIF abstraction or universal PTZ compatibility.
- Full DAW plugin or MIDI routing features.
- Complex velocity range mapping.

## Architecture
- **Status Bar App**: SwiftUI + AppKit `NSStatusItem` for the menu bar icon and menu.
- **CoreMIDI Service**: Enumerates sources and subscribes to multiple configured sources.
- **Rule Engine**: Matches incoming MIDI events to configured rules and resolves commands.
- **HTTP Client**: Sends vendor-specific HTTP requests with basic auth to the PTZ camera and retries (3).
- **Logging**: Append-only log file with rotation, plus a small in-memory ring buffer for last 5 items.

## Data Model
- **Camera**: `id`, `name`, `ip`, `username`, `password`
- **MidiSource**: `name`
- **Rule**: `note`, `onOff`, `velocityCondition` (exact or threshold), `cameraId`, `commandTemplateId`
- **CommandTemplate**: `method`, `path`, optional `body`, optional `headers`
- **LogEvent**: timestamp, type (MIDI/HTTP), status (ok/fail), summary, details

## Data Flow
1. CoreMIDI receives a MIDI event from any configured source.
2. Rule engine validates event and matches rules by note + on/off + velocity condition.
3. Rule engine resolves target camera and command template.
4. HTTP client builds request and sends to camera (up to 3 retries).
5. Success/failure triggers green/red flash on the status bar.
6. Log entry is written to the rotating log and last-5 buffer.
7. Menu bar displays last 5 events with timestamps.

## UI/UX
- **Menu bar icon**: flashes green for success, red for failure.
- **Menu list**: last 5 events with timestamp and short summary.
- **Configure button**: opens SwiftUI window with tabs/sections:
  - MIDI source selection (multiple by name)
  - Camera list (CRUD)
  - Command templates (CRUD)
  - Rules/mappings (CRUD)
  - Test camera action

## Error Handling
- MIDI source disconnect logs an error and flashes red; listener attempts reconnect.
- HTTP errors retry up to 3 times with short backoff, then log status code and body snippet.
- Invalid rules are ignored with warning logs.

## Testing
- Unit tests for rule matching, command construction, and retry logic.
- Manual integration using a mock PTZ endpoint.

## Open Questions
- Specific vendor HTTP command set and example templates.
- Log size cap and rotation strategy (e.g., 10 MB x 3 files).
