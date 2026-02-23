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
        guard let mapping = config.mappings.first(where: { $0.note == event.note && $0.onOff == event.onOff && $0.velocity == event.velocity }) else {
            return nil
        }
        guard let cameraId = mapping.cameraId, let commandId = mapping.commandTemplateId else {
            return nil
        }
        guard let camera = camerasById[cameraId], let command = commandsById[commandId] else {
            return nil
        }
        return ResolvedAction(camera: camera, command: command)
    }
}
