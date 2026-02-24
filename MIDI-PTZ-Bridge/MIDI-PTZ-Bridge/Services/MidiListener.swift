import Foundation

struct MidiEvent: Equatable {
    let note: Int
    let velocity: Int
    let onOff: MidiOnOff
    let sourceName: String

    init(note: Int, velocity: Int, onOff: MidiOnOff, sourceName: String = "") {
        self.note = note
        self.velocity = velocity
        self.onOff = onOff
        self.sourceName = sourceName
    }
}

protocol MidiEventSource {
    func start(selectedSources: [String], handler: @escaping (MidiEvent) -> Void) throws
    func stop()
}

final class MidiListener {
    private let source: MidiEventSource
    private let selectionProvider: MidiSelectionProvider

    init(source: MidiEventSource = CoreMidiSource(), selectionProvider: MidiSelectionProvider = ConfigMidiSelectionProvider()) {
        self.source = source
        self.selectionProvider = selectionProvider
    }

    nonisolated deinit {}

    func start(handler: @escaping (MidiEvent) -> Void) throws {
        let selected = selectionProvider.selectedSourceNames()
        try source.start(selectedSources: selected, handler: handler)
    }

    func stop() {
        source.stop()
    }
}

final class CoreMidiSource: MidiEventSource {
    func start(selectedSources: [String], handler: @escaping (MidiEvent) -> Void) throws {
        // CoreMIDI wiring will be added in a later task.
    }

    func stop() {
        // CoreMIDI teardown will be added in a later task.
    }

    nonisolated deinit {}
}
