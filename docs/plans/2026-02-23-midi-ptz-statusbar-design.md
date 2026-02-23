# MIDI-PTZ Status Bar App Design

Date: 2026-02-23

## Summary
A native macOS status bar app that listens to CoreMIDI notes from multiple selected sources and translates them into PTZOptics HTTP commands. The menu bar flashes green on success and red on failure, shows the last 5 events, and provides a configuration window for MIDI sources, cameras, rule-based mappings, and commands. Activity is logged to a rotating log file.

## Goals
- Listen to multiple CoreMIDI sources (by name).
- Map MIDI note + on/off + velocity conditions to PTZOptics actions via simple rules.
- Configure PTZ cameras (name, protocol, host, port, username, password) stored in app config.
- Show activity in the menu bar with success/failure flashes.
- Maintain a persistent log file with size cap and rotate.
- Provide a configuration UI for all settings with detected MIDI sources and refresh.

## Non-Goals
- ONVIF abstraction or universal PTZ compatibility.
- Full DAW plugin or MIDI routing features.
- Complex velocity range mapping.

## Architecture
- **Status Bar App**: SwiftUI + AppKit `NSStatusItem` for the menu bar icon and menu.
- **CoreMIDI Service**: Enumerates sources and subscribes to multiple configured sources.
- **Rule Engine**: Matches incoming MIDI events to configured rules and resolves commands.
- **PTZ Action Catalog**: Maps a small set of PTZOptics actions (start with `preset_recall`) to URL templates and required parameters.
- **HTTP Client**: Sends PTZOptics HTTP requests, embedding credentials in the URL when set, and retries (3).
- **Logging**: Append-only log file with rotation, plus a small in-memory ring buffer for last 5 items.

## Data Model
- **Camera**: `id`, `name`, `protocol`, `host`, `port`, `username`, `password`
- **MidiSource**: `name` (selected from detected sources)
- **Rule**: `note`, `onOff`, `velocityCondition` (exact or threshold), `cameraId`, `commandTemplateId`
- **CommandTemplate**: `name`, `action`, `params` (e.g., preset number)
- **LogEvent**: timestamp, type (MIDI/HTTP), status (ok/fail), summary, details

## Data Flow
1. CoreMIDI receives a MIDI event from any configured source.
2. Rule engine validates event and matches rules by note + on/off + velocity condition.
3. Rule engine resolves target camera and command template.
4. PTZ action layer builds URL for `preset_recall` using the command params.
5. HTTP client builds request and sends to camera (up to 3 retries).
6. Success/failure triggers green/red flash on the status bar.
7. Log entry is written to the rotating log and last-5 buffer.
8. Menu bar displays last 5 events with timestamps.

## UI/UX
- **Menu bar icon**: flashes green for success, red for failure.
- **Menu list**: last 5 events with timestamp and short summary.
- **Configure button**: opens SwiftUI window with tabs/sections:
  - MIDI source selection (detected list with refresh)
  - Camera list (CRUD)
  - Command templates (CRUD, action-based)
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
- Log size cap and rotation strategy (e.g., 10 MB x 3 files).
