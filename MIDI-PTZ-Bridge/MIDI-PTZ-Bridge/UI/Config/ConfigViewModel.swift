import Combine
import Foundation
import SwiftUI

@MainActor
final class ConfigViewModel: ObservableObject {
    @Published var config: AppConfig
    @Published var availableMidiSources: [String] = []

    private let store: ConfigStore
    private let sourceProvider: MidiSourceProvider

    init(store: ConfigStore = ConfigStore(), sourceProvider: MidiSourceProvider = CoreMidiSourceProvider()) {
        self.store = store
        self.sourceProvider = sourceProvider
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            self.config = AppConfig.empty
        } else {
            self.config = (try? store.load()) ?? AppConfig.empty
        }
    }

    nonisolated deinit {}

    func save() {
        do {
            try store.save(config)
        } catch {
            // TODO: surface error in UI
        }
    }

    func addMidiSource(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !config.midiSources.contains(trimmed) else { return }
        config.midiSources.append(trimmed)
        save()
    }

    func removeMidiSources(at offsets: IndexSet) {
        config.midiSources.remove(atOffsets: offsets)
        save()
    }

    func setMidiSource(_ name: String, selected: Bool) {
        if selected {
            addMidiSource(name)
        } else {
            config.midiSources.removeAll { $0 == name }
            save()
        }
    }

    func refreshMidiSources() {
        availableMidiSources = sourceProvider.fetchSourceNames()
    }

    func addCamera(name: String, scheme: CameraScheme, host: String, port: Int, username: String?, password: String?) {
        let camera = Camera(id: UUID(), name: name, scheme: scheme, host: host, port: port, username: username, password: password)
        config.cameras.append(camera)
        save()
    }

    func removeCameras(at offsets: IndexSet) {
        config.cameras.remove(atOffsets: offsets)
        save()
    }

    func addCommandTemplate(name: String, action: PTZAction, params: CommandParams) {
        let template = CommandTemplate(id: UUID(), name: name, action: action, params: params)
        config.commandTemplates.append(template)
        save()
    }

    func removeCommandTemplates(at offsets: IndexSet) {
        config.commandTemplates.remove(atOffsets: offsets)
        save()
    }

    func addRule(note: Int, onOff: MidiOnOff, velocity: VelocityCondition, cameraId: UUID?, commandTemplateId: UUID?) {
        let rule = Rule(id: UUID(), note: note, onOff: onOff, velocity: velocity, cameraId: cameraId, commandTemplateId: commandTemplateId)
        config.rules.append(rule)
        save()
    }

    func removeRules(at offsets: IndexSet) {
        config.rules.remove(atOffsets: offsets)
        save()
    }
}
