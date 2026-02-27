import XCTest
@testable import MIDI_PTZ_Bridge

final class ConfigStoreTests: XCTestCase {
    func testRoundTripConfig() throws {
        let store = ConfigStore(baseURL: FileManager.default.temporaryDirectory)
        let config = AppConfig(
            midiSources: ["IAC Driver Bus 1", "IAC Driver Bus 2"],
            cameras: [Camera(id: UUID(), name: "Cam A", scheme: .http, host: "192.168.0.10", port: 80, username: "u", password: "p")],
            commandTemplates: [CommandTemplate(id: UUID(), name: "Preset 1", action: .presetRecall, params: .presetRecall(number: 1))],
            rules: [Rule(id: UUID(), note: 60, onOff: .on, velocity: .exact(100), cameraId: nil, commandTemplateId: nil)]
        )
        try store.save(config)
        let loaded = try store.load()
        XCTAssertEqual(loaded.midiSources, config.midiSources)
        XCTAssertEqual(loaded.cameras.count, 1)
    }
}
