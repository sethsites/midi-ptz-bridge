import Foundation

struct AppConfig: Codable, Equatable {
    var midiSources: [String]
    var cameras: [Camera]
    var commandTemplates: [CommandTemplate]
    var rules: [Rule]

    static let empty = AppConfig(
        midiSources: [],
        cameras: [],
        commandTemplates: [],
        rules: []
    )
}

struct Camera: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var scheme: CameraScheme
    var host: String
    var port: Int
    var username: String?
    var password: String?
}

enum CameraScheme: String, Codable, Equatable {
    case http
    case https
}

struct CommandTemplate: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var action: PTZAction
    var params: CommandParams
}

enum PTZAction: String, Codable, Equatable {
    case presetRecall
}

enum CommandParams: Codable, Equatable {
    case presetRecall(number: Int)

    private enum CodingKeys: String, CodingKey {
        case type
        case number
    }

    private enum ParamsType: String, Codable {
        case presetRecall
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ParamsType.self, forKey: .type)
        switch type {
        case .presetRecall:
            let number = try container.decode(Int.self, forKey: .number)
            self = .presetRecall(number: number)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .presetRecall(let number):
            try container.encode(ParamsType.presetRecall, forKey: .type)
            try container.encode(number, forKey: .number)
        }
    }
}

enum MidiOnOff: String, Codable, Equatable {
    case on
    case off
}

enum VelocityCondition: Codable, Equatable {
    case exact(Int)
    case min(Int)
    case max(Int)
    case range(Int, Int)

    private enum CodingKeys: String, CodingKey {
        case type
        case value
        case min
        case max
    }

    private enum ConditionType: String, Codable {
        case exact
        case min
        case max
        case range
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ConditionType.self, forKey: .type)
        switch type {
        case .exact:
            let value = try container.decode(Int.self, forKey: .value)
            self = .exact(value)
        case .min:
            let value = try container.decode(Int.self, forKey: .value)
            self = .min(value)
        case .max:
            let value = try container.decode(Int.self, forKey: .value)
            self = .max(value)
        case .range:
            let minValue = try container.decode(Int.self, forKey: .min)
            let maxValue = try container.decode(Int.self, forKey: .max)
            self = .range(minValue, maxValue)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .exact(let value):
            try container.encode(ConditionType.exact, forKey: .type)
            try container.encode(value, forKey: .value)
        case .min(let value):
            try container.encode(ConditionType.min, forKey: .type)
            try container.encode(value, forKey: .value)
        case .max(let value):
            try container.encode(ConditionType.max, forKey: .type)
            try container.encode(value, forKey: .value)
        case .range(let minValue, let maxValue):
            try container.encode(ConditionType.range, forKey: .type)
            try container.encode(minValue, forKey: .min)
            try container.encode(maxValue, forKey: .max)
        }
    }
}

struct Rule: Codable, Equatable, Identifiable {
    let id: UUID
    var note: Int
    var onOff: MidiOnOff
    var velocity: VelocityCondition
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
