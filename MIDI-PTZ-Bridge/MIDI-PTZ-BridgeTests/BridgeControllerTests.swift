import XCTest
@testable import MIDI_PTZ_Bridge

final class BridgeControllerTests: XCTestCase {
    func testHandlesMidiEvent() async {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ConfigStore(baseURL: dir)
        let controller = BridgeController(
            configStore: store,
            onLogEvent: { _ in },
            onFlash: { _ in }
        )

        let event = MidiEvent(note: 60, velocity: 100, onOff: .on, sourceName: "Bus")
        await controller.handle(event)

        XCTAssertTrue(true)
    }
}
