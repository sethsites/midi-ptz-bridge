import XCTest
@testable import MIDI_PTZ_Bridge

final class MappingRouterTests: XCTestCase {
    func testResolvesCommandForExactMatch() {
        let camId = UUID()
        let cmdId = UUID()
        let config = AppConfig(
            midiSource: .byName("Bus"),
            cameras: [Camera(id: camId, name: "Cam", ip: "1.2.3.4", username: "u", password: "p")],
            commandTemplates: [CommandTemplate(id: cmdId, name: "Home", method: .get, path: "/home", headers: [:], body: nil)],
            mappings: [Mapping(id: UUID(), note: 60, onOff: .on, velocity: 100, cameraId: camId, commandTemplateId: cmdId)]
        )
        let router = MappingRouter(config: config)
        let event = MidiEvent(note: 60, velocity: 100, onOff: .on)
        let action = router.resolve(event)
        XCTAssertEqual(action?.camera.name, "Cam")
        XCTAssertEqual(action?.command.path, "/home")
    }
}
