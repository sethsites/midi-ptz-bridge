import Foundation

struct PTZOpticsRequest: Equatable {
    let method: String
    let path: String
}

enum PTZOpticsActionCatalog {
    static func request(for action: PTZAction, params: CommandParams) -> PTZOpticsRequest {
        switch (action, params) {
        case (.presetRecall, .presetRecall(let number)):
            return PTZOpticsRequest(
                method: "GET",
                path: "/cgi-bin/ptzctrl.cgi?ptzcmd&poscall&\(number)"
            )
        }
    }
}
