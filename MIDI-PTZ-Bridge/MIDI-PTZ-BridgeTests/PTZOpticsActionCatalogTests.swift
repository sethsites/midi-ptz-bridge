import XCTest
@testable import MIDI_PTZ_Bridge

final class PTZOpticsActionCatalogTests: XCTestCase {
    func testPresetRecallBuildsPath() {
        let request = PTZOpticsActionCatalog.request(
            for: .presetRecall,
            params: .presetRecall(number: 3)
        )
        XCTAssertEqual(request.path, "/cgi-bin/ptzctrl.cgi?ptzcmd&poscall&3")
        XCTAssertEqual(request.method, "GET")
    }
}
