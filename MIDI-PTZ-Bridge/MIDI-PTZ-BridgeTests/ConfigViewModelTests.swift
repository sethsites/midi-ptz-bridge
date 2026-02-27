import XCTest
@testable import MIDI_PTZ_Bridge

final class ConfigViewModelTests: XCTestCase {
    private struct StubMidiSourceProvider: MidiSourceProvider {
        func fetchSourceNames() -> [String] {
            []
        }
    }

    @MainActor
    func testAddsCamera() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ConfigStore(baseURL: dir)
        let vm = ConfigViewModel(store: store, sourceProvider: StubMidiSourceProvider())
        vm.addCamera(name: "Cam", scheme: .http, host: "1.2.3.4", port: 80, username: "u", password: "p")
        XCTAssertEqual(vm.config.cameras.count, 1)
    }

    @MainActor
    func testInitOnly() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ConfigStore(baseURL: dir)
        _ = ConfigViewModel(store: store, sourceProvider: StubMidiSourceProvider())
        XCTAssertTrue(true)
    }
}
