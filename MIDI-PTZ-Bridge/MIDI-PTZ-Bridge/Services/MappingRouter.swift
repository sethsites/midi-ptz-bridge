import Foundation

struct ResolvedAction: Equatable {
    let camera: Camera
    let command: CommandTemplate
}

struct MappingRouter {
    private let config: AppConfig
    private let camerasById: [UUID: Camera]
    private let commandsById: [UUID: CommandTemplate]

    init(config: AppConfig) {
        self.config = config
        self.camerasById = Dictionary(uniqueKeysWithValues: config.cameras.map { ($0.id, $0) })
        self.commandsById = Dictionary(uniqueKeysWithValues: config.commandTemplates.map { ($0.id, $0) })
    }

    func resolve(_ event: MidiEvent) -> ResolvedAction? {
        resolveAll(for: event).first
    }

    func resolveAll(for event: MidiEvent) -> [ResolvedAction] {
        config.rules.compactMap { rule in
            guard matches(rule: rule, event: event) else { return nil }
            guard let cameraId = rule.cameraId, let commandId = rule.commandTemplateId else {
                return nil
            }
            guard let camera = camerasById[cameraId], let command = commandsById[commandId] else {
                return nil
            }
            return ResolvedAction(camera: camera, command: command)
        }
    }

    private func matches(rule: Rule, event: MidiEvent) -> Bool {
        guard rule.note == event.note, rule.onOff == event.onOff else { return false }
        return velocityMatches(rule.velocity, velocity: event.velocity)
    }

    private func velocityMatches(_ condition: VelocityCondition, velocity: Int) -> Bool {
        switch condition {
        case .exact(let value):
            return velocity == value
        case .min(let value):
            return velocity >= value
        case .max(let value):
            return velocity <= value
        case .range(let minValue, let maxValue):
            return velocity >= minValue && velocity <= maxValue
        }
    }
}
