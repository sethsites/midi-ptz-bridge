# CoreMIDI Implementation Design

Date: 2026-02-24

## Summary
Implement CoreMIDI input for the MIDI listener. The listener subscribes only to user-selected source names, parses note on/off events, and auto-reconnects when sources appear or disappear.

## Goals
- Listen to CoreMIDI sources whose names match the user-selected list.
- Parse Note On (0x90) and Note Off (0x80), treating Note On with velocity 0 as Note Off.
- Include the MIDI source name in each `MidiEvent`.
- Auto-reconnect when devices/sources are added or removed.

## Non-Goals
- Listening to all sources when no selections are configured.
- MIDI routing, transformations, or filtering beyond note/on/off/velocity.
- Support for other MIDI message types (CC, pitch bend, etc.).

## Architecture
- **CoreMidiSource** owns:
  - `MIDIClientRef` for notifications
  - `MIDIPortRef` input port for incoming data
  - Active map of connected endpoints keyed by source name
- **MidiListener** remains the façade; it starts/stops CoreMidiSource and forwards parsed events.

## Data Flow
1. On `start`:
   - Create `MIDIClientRef` and input `MIDIPortRef`.
   - Enumerate sources, filter to selected names, and connect to each endpoint.
2. On MIDI input:
   - Parse `MIDIPacketList` into `MidiEvent`.
   - Extract note, velocity, on/off, and source name.
3. On CoreMIDI notifications:
   - Re-enumerate sources and reconnect to selected names.
4. On `stop`:
   - Disconnect all sources and dispose port/client.

## Error Handling
- Missing selected sources: log warning, keep running.
- Disconnects: remove from active map; reconnect on next notification.
- Invalid MIDI packets: ignore safely.

## Testing
- Unit tests cover note parsing and source name attribution.
- Manual validation by creating/removing IAC buses and observing auto-reconnect.
