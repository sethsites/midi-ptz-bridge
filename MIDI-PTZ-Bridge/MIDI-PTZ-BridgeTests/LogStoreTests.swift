import XCTest
@testable import MIDI_PTZ_Bridge

final class LogStoreTests: XCTestCase {
    func testAppendsAndRotates() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store = LogStore(baseURL: dir, maxBytes: 100, maxFiles: 2)
        for _ in 0..<20 {
            store.append(.init(type: .midi, status: .ok, summary: "x", details: "y"))
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.appendingPathComponent("activity.log").path))
    }

    func testKeepsLastFiveEvents() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var store = LogStore(baseURL: dir, maxBytes: 10_000, maxFiles: 2)
        for i in 0..<6 {
            store.append(.init(type: .midi, status: .ok, summary: "e\(i)", details: "d"))
        }
        XCTAssertEqual(store.recentEvents.count, 5)
        XCTAssertEqual(store.recentEvents.first?.summary, "e1")
        XCTAssertEqual(store.recentEvents.last?.summary, "e5")
    }
}
