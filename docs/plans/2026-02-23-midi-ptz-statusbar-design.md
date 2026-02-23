# MIDI-PTZ Status Bar App Design

Date: 2026-02-23

## Summary
A native macOS status bar app that listens to CoreMIDI notes and translates them into vendor-specific PTZ camera HTTP commands. The menu bar flashes green on success and red on failure, shows the last 5 events, and provides a configuration window for MIDI sources, cameras, mappings, and commands. Activity is logged to a rotating log file.

## Goals
- Listen to a selected CoreMIDI source (by name or device+port).
- Map MIDI note + on/off + exact velocity to a PTZ HTTP command.
- Configure PTZ cameras (name, IP, username, password).
- Show activity in the menu bar with success/failure flashes.
- Maintain a persistent log file with size cap and rotate.
- Provide a configuration UI for all settings.

## Non-Goals
- ONVIF abstraction or universal PTZ compatibility.
- Full DAW plugin or MIDI routing features.
- Complex velocity range mapping.

## Architecture
- **Status Bar App**: SwiftUI + AppKit `NSStatusItem` for the menu bar icon and menu.
- **CoreMIDI Service**: Enumerates sources and subscribes to selected source.
- **Mapping Router**: Matches incoming MIDI events to a configured mapping and resolves a command.
- **HTTP Client**: Sends vendor-specific HTTP requests with basic auth to the PTZ camera.
- **Logging**: Append-only log file with rotation, plus a small in-memory ring buffer for last 5 items.

## Data Model
- **Camera**: `id`, `name`, `ip`, `username`, `password`
- **MidiSource**: `mode` (name or device+port), `value`
- **Mapping**: `note`, `onOff`, `velocity`, `cameraId`, `commandTemplateId`
- **CommandTemplate**: `method`, `path`, optional `body`, optional `headers`
- **LogEvent**: timestamp, type (MIDI/HTTP), status (ok/fail), summary, details

## Data Flow
1. CoreMIDI receives a MIDI event.
2. Router validates event and matches mapping by note + on/off + exact velocity.
3. Router resolves target camera and command template.
4. HTTP client builds request and sends to camera.
5. Success/failure triggers green/red flash on the status bar.
6. Log entry is written to the rotating log and last-5 buffer.
7. Menu bar displays last 5 events with timestamps.

## UI/UX
- **Menu bar icon**: flashes green for success, red for failure.
- **Menu list**: last 5 events with timestamp and short summary.
- **Configure button**: opens SwiftUI window with tabs/sections:
  - MIDI source selection (name or device+port)
  - Camera list (CRUD)
  - Command templates (CRUD)
  - Mappings (CRUD)
  - Test camera action

## Error Handling
- MIDI source disconnect logs an error and flashes red.
- HTTP errors log status code and body snippet.
- Invalid mappings are ignored with warning logs.

## Testing
- Unit tests for mapping resolution and command construction.
- Manual integration using a mock PTZ endpoint.

## Open Questions
- Specific vendor HTTP command set and example templates.
- Log size cap and rotation strategy (e.g., 10 MB x 3 files).
- Whether to encrypt stored credentials (currently plain config file).
