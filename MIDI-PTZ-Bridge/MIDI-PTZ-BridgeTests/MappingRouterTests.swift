import XCTest
@testable import MIDI_PTZ_Bridge

final class MappingRouterTests: XCTestCase {
    func testReturnsAllMatchingRules() {
        let camId = UUID()
        let cmdA = UUID()
        let cmdB = UUID()
        let config = AppConfig(
            midiSources: ["Bus"],
            cameras: [Camera(id: camId, name: "Cam", scheme: .http, host: "1.2.3.4", port: 80, username: nil, password: nil)],
            commandTemplates: [
                CommandTemplate(id: cmdA, name: "Preset 1", action: .presetRecall, params: .presetRecall(number: 1)),
                CommandTemplate(id: cmdB, name: "Preset 2", action: .presetRecall, params: .presetRecall(number: 2))
            ],
            rules: [
                Rule(id: UUID(), note: 60, onOff: .on, velocity: .exact(100), cameraId: camId, commandTemplateId: cmdA),
                Rule(id: UUID(), note: 60, onOff: .on, velocity: .exact(100), cameraId: camId, commandTemplateId: cmdB)
            ]
        )
        let router = MappingRouter(config: config)
        let event = MidiEvent(note: 60, velocity: 100, onOff: .on, sourceName: "Bus")
        let actions = router.resolveAll(for: event)
        XCTAssertEqual(actions.count, 2)
    }
}
