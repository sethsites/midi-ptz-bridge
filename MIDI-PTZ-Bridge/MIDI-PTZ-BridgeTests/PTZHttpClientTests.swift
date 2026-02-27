import XCTest
@testable import MIDI_PTZ_Bridge

final class PTZHttpClientTests: XCTestCase {
    func testBuildsURLWithCredentials() throws {
        let camera = Camera(
            id: UUID(),
            name: "Cam",
            scheme: .http,
            host: "1.2.3.4",
            port: 80,
            username: "user",
            password: "pass"
        )
        let url = try PTZHttpClient.buildURL(
            camera: camera,
            path: "/cgi-bin/ptz.cgi?command=preset&action=call&index=1"
        )
        XCTAssertEqual(url.absoluteString, "http://user:pass@1.2.3.4:80/cgi-bin/ptz.cgi?command=preset&action=call&index=1")
    }
}
