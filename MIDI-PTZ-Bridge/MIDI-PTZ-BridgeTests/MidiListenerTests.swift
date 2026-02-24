import XCTest
@testable import MIDI_PTZ_Bridge

final class MidiListenerTests: XCTestCase {
    func testParsesNoteOn() {
        let event = MidiEvent(note: 60, velocity: 100, onOff: .on, sourceName: "Bus")
        XCTAssertEqual(event.note, 60)
        XCTAssertEqual(event.sourceName, "Bus")
    }

    func testListenerPassesSelectedSources() {
        struct StubProvider: MidiSelectionProvider {
            func selectedSourceNames() -> [String] { ["Bus A", "Bus B"] }
        }

        final class StubSource: MidiEventSource {
            private(set) var lastSelected: [String] = []
            func start(selectedSources: [String], handler: @escaping (MidiEvent) -> Void) throws {
                lastSelected = selectedSources
            }
            func stop() {}
        }

        let source = StubSource()
        let listener = MidiListener(source: source, selectionProvider: StubProvider())
        try? listener.start { _ in }
        XCTAssertEqual(source.lastSelected, ["Bus A", "Bus B"])
    }

    func testCoreMidiSourceTracksSelectedSources() {
        let source = CoreMidiSource()
        source.connectSelectedSources(["Bus A"])
        XCTAssertTrue(source.connectedSourceNames.contains("Bus A"))
    }

    func testParsesNoteOnAndOff() {
        let events = CoreMidiSource.parse(bytes: [0x90, 60, 100, 0x80, 60, 0])
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].onOff, .on)
        XCTAssertEqual(events[1].onOff, .off)
    }

    func testAutoReconnectKeepsSelectedSources() {
        let source = CoreMidiSource()
        source.connectSelectedSources(["Bus A"])
        source.handleSystemChange()
        XCTAssertTrue(source.connectedSourceNames.contains("Bus A"))
    }
}
