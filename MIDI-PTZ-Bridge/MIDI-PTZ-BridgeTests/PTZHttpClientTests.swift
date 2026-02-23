import XCTest
@testable import MIDI_PTZ_Bridge

final class PTZHttpClientTests: XCTestCase {
    func testBuildsRequestWithBasicAuth() throws {
        let client = PTZHttpClient()
        let camera = Camera(id: UUID(), name: "Cam", ip: "1.2.3.4", username: "user", password: "pass")
        let command = CommandTemplate(id: UUID(), name: "Test", method: .get, path: "/ptz", headers: [:], body: nil)
        let request = try client.buildRequest(camera: camera, command: command)
        XCTAssertEqual(request.url?.absoluteString, "http://1.2.3.4/ptz")
        XCTAssertNotNil(request.value(forHTTPHeaderField: "Authorization"))
    }
}
