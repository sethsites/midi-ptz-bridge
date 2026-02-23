import XCTest
@testable import MIDI_PTZ_Bridge

final class MidiListenerTests: XCTestCase {
    func testParsesNoteOn() {
        let event = MidiEvent(note: 60, velocity: 100, onOff: .on)
        XCTAssertEqual(event.note, 60)
    }
}
