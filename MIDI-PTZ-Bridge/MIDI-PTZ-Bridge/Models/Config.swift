import Foundation

struct AppConfig: Codable, Equatable {
    var midiSource: MidiSource
    var cameras: [Camera]
    var commandTemplates: [CommandTemplate]
    var mappings: [Mapping]

    static let empty = AppConfig(
        midiSource: .byName(""),
        cameras: [],
        commandTemplates: [],
        mappings: []
    )
}

struct Camera: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var ip: String
    var username: String
    var password: String
}

enum MidiSource: Codable, Equatable {
    case byName(String)
    case byDevicePort(device: String, port: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case name
        case device
        case port
    }

    private enum SourceType: String, Codable {
        case byName
        case byDevicePort
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SourceType.self, forKey: .type)
        switch type {
        case .byName:
            let name = try container.decode(String.self, forKey: .name)
            self = .byName(name)
        case .byDevicePort:
            let device = try container.decode(String.self, forKey: .device)
            let port = try container.decode(String.self, forKey: .port)
            self = .byDevicePort(device: device, port: port)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .byName(let name):
            try container.encode(SourceType.byName, forKey: .type)
            try container.encode(name, forKey: .name)
        case .byDevicePort(let device, let port):
            try container.encode(SourceType.byDevicePort, forKey: .type)
            try container.encode(device, forKey: .device)
            try container.encode(port, forKey: .port)
        }
    }
}

enum HTTPMethod: String, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct CommandTemplate: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var method: HTTPMethod
    var path: String
    var headers: [String: String]
    var body: String?
}

enum MidiOnOff: String, Codable, Equatable {
    case on
    case off
}

struct Mapping: Codable, Equatable, Identifiable {
    let id: UUID
    var note: Int
    var onOff: MidiOnOff
    var velocity: Int
    var cameraId: UUID?
    var commandTemplateId: UUID?
}

struct LogEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let timestamp: Date
    var type: LogEventType
    var status: LogEventStatus
    var summary: String
    var details: String

    init(type: LogEventType, status: LogEventStatus, summary: String, details: String, timestamp: Date = Date(), id: UUID = UUID()) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.status = status
        self.summary = summary
        self.details = details
    }
}

enum LogEventType: String, Codable, Equatable {
    case midi
    case http
}

enum LogEventStatus: String, Codable, Equatable {
    case ok
    case fail
}
