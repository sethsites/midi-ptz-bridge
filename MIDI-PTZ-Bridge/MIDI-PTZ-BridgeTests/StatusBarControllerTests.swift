import XCTest
@testable import MIDI_PTZ_Bridge

final class StatusBarControllerTests: XCTestCase {
    func testMenuShowsLastFiveEvents() {
        let events = (0..<6).map { index in
            LogEvent(type: .midi, status: .ok, summary: "e\(index)", details: "d")
        }
        let items = StatusBarController.menuItems(for: events)
        XCTAssertEqual(items.count, 5)
    }
}
