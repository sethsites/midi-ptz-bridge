import CoreMIDI
import Foundation

protocol MidiSourceProvider {
    func fetchSourceNames() -> [String]
}

struct CoreMidiSourceProvider: MidiSourceProvider {
    func fetchSourceNames() -> [String] {
        let count = MIDIGetNumberOfSources()
        guard count > 0 else { return [] }

        var names: [String] = []
        names.reserveCapacity(Int(count))

        for index in 0..<count {
            let source = MIDIGetSource(index)
            guard source != 0 else { continue }
            var name: Unmanaged<CFString>?
            let status = MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name)
            guard status == noErr, let cfName = name?.takeRetainedValue() else { continue }
            names.append(cfName as String)
        }

        return names.sorted()
    }
}
