import Foundation

protocol MidiSelectionProvider {
    func selectedSourceNames() -> [String]
}

struct ConfigMidiSelectionProvider: MidiSelectionProvider {
    let store: ConfigStore

    init(store: ConfigStore = ConfigStore()) {
        self.store = store
    }

    func selectedSourceNames() -> [String] {
        (try? store.load())?.midiSources ?? []
    }
}
