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
    private(set) var connectedSourceNames: Set<String> = []

    func start(selectedSources: [String], handler: @escaping (MidiEvent) -> Void) throws {
        // CoreMIDI wiring will be added in a later task.
    }

    func stop() {
        // CoreMIDI teardown will be added in a later task.
    }

    func connectSelectedSources(_ names: [String]) {
        connectedSourceNames = Set(names)
    }

    static func parse(bytes: [UInt8], sourceName: String = "") -> [MidiEvent] {
        guard bytes.count >= 3 else { return [] }
        var events: [MidiEvent] = []
        events.reserveCapacity(bytes.count / 3)

        var index = 0
        while index + 2 < bytes.count {
            let status = bytes[index] & 0xF0
            let note = Int(bytes[index + 1])
            let velocity = Int(bytes[index + 2])

            switch status {
            case 0x90:
                let onOff: MidiOnOff = velocity == 0 ? .off : .on
                events.append(MidiEvent(note: note, velocity: velocity, onOff: onOff, sourceName: sourceName))
            case 0x80:
                events.append(MidiEvent(note: note, velocity: velocity, onOff: .off, sourceName: sourceName))
            default:
                break
            }

            index += 3
        }

        return events
    }

    nonisolated deinit {}
}
