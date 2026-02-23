import XCTest
@testable import MIDI_PTZ_Bridge

final class ConfigStoreTests: XCTestCase {
    func testRoundTripConfig() throws {
        let store = ConfigStore(baseURL: FileManager.default.temporaryDirectory)
        let config = AppConfig(
            midiSource: .byName("IAC Driver Bus 1"),
            cameras: [Camera(id: UUID(), name: "Cam A", ip: "192.168.0.10", username: "u", password: "p")],
            commandTemplates: [CommandTemplate(id: UUID(), name: "Home", method: .get, path: "/home", headers: [:], body: nil)],
            mappings: [Mapping(id: UUID(), note: 60, onOff: .on, velocity: 100, cameraId: nil, commandTemplateId: nil)]
        )
        try store.save(config)
        let loaded = try store.load()
        XCTAssertEqual(loaded.midiSource, config.midiSource)
        XCTAssertEqual(loaded.cameras.count, 1)
    }
}
