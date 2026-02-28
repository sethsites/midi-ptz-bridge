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
    
    func updateCamera(_ camera: Camera) {
        for i in 0..<config.cameras.count {
            if config.cameras[i].id == camera.id {
                config.cameras[i] = camera
                break
            }
        }
        save()
    }

    func removeCameras(at offsets: IndexSet) {
        config.cameras.remove(atOffsets: offsets)
        save()
    }
    
    func removeCamera(_ id: UUID) {
        config.cameras.removeAll { $0.id == id }
        save()
    }

    func addCommandTemplate(name: String, action: PTZAction, params: CommandParams) {
        let template = CommandTemplate(id: UUID(), name: name, action: action, params: params)
        config.commandTemplates.append(template)
        save()
    }
    
    func updateCommandTemplate(_ template: CommandTemplate) {
        for i in 0..<config.commandTemplates.count {
            if config.commandTemplates[i].id == template.id {
                config.commandTemplates[i] = template
                break
            }
        }
        save()
    }

    func removeCommandTemplates(at offsets: IndexSet) {
        config.commandTemplates.remove(atOffsets: offsets)
        save()
    }
    
    func removeCommandTemplate(_ id: UUID) {
        config.commandTemplates.removeAll { $0.id == id }
        save()
    }

    func addRule(note: Int, onOff: MidiOnOff, velocity: VelocityCondition, cameraId: UUID?, commandTemplateId: UUID?) {
        let rule = Rule(id: UUID(), note: note, onOff: onOff, velocity: velocity, cameraId: cameraId, commandTemplateId: commandTemplateId)
        config.rules.append(rule)
        save()
    }
    
    func updateRule(_ rule: Rule) {
        for i in 0..<config.rules.count {
            if config.rules[i].id == rule.id {
                config.rules[i] = rule
                break
            }
        }
        save()
    }

    func removeRules(_ rule: Rule) {
        for i in 0..<config.rules.count {
            if config.rules[i].id == rule.id {
                config.rules.remove(at: i)
                break
            }
        }
        
        save()
    }
}
