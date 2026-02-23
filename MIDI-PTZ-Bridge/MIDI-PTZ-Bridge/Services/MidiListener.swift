import Foundation

struct MidiEvent: Equatable {
    let note: Int
    let velocity: Int
    let onOff: MidiOnOff
}

protocol MidiEventSource {
    func start(handler: @escaping (MidiEvent) -> Void) throws
    func stop()
}

final class MidiListener {
    private let source: MidiEventSource

    init(source: MidiEventSource = CoreMidiSource()) {
        self.source = source
    }

    func start(handler: @escaping (MidiEvent) -> Void) throws {
        try source.start(handler: handler)
    }

    func stop() {
        source.stop()
    }
}

final class CoreMidiSource: MidiEventSource {
    func start(handler: @escaping (MidiEvent) -> Void) throws {
        // CoreMIDI wiring will be added in a later task.
    }

    func stop() {
        // CoreMIDI teardown will be added in a later task.
    }
}
