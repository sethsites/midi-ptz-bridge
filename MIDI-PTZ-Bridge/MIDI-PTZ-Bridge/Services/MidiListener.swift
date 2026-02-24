import CoreMIDI
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
    private var selectedSourceNames: [String] = []
    private var client: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var handler: ((MidiEvent) -> Void)?
    private var connections: [MIDIEndpointRef: UnsafeMutableRawPointer] = [:]
    private var sourceNamesByEndpoint: [MIDIEndpointRef: String] = [:]

    private final class SourceContext {
        let name: String

        init(name: String) {
            self.name = name
        }
    }

    func start(selectedSources: [String], handler: @escaping (MidiEvent) -> Void) throws {
        self.handler = handler
        selectedSourceNames = selectedSources

        if client == 0 {
            let status = MIDIClientCreateWithBlock("MIDI-PTZ-Bridge Client" as CFString, &client) { [weak self] _ in
                self?.handleSystemChange()
            }
            guard status == noErr else {
                throw MidiListenerError.midiUnavailable
            }
        }

        if inputPort == 0 {
            let status = MIDIInputPortCreateWithBlock(client, "MIDI-PTZ-Bridge Input" as CFString, &inputPort) { [weak self] packetList, refCon in
                let sourceName = self?.sourceName(from: refCon) ?? ""
                self?.handle(packetList: packetList, sourceName: sourceName)
            }
            guard status == noErr else {
                throw MidiListenerError.midiUnavailable
            }
        }

        connectSelectedSources(selectedSources)
    }

    func stop() {
        for (endpoint, refCon) in connections {
            MIDIPortDisconnectSource(inputPort, endpoint)
            Unmanaged<SourceContext>.fromOpaque(refCon).release()
        }
        connections.removeAll()
        sourceNamesByEndpoint.removeAll()
        connectedSourceNames.removeAll()

        if inputPort != 0 {
            MIDIPortDispose(inputPort)
            inputPort = 0
        }

        if client != 0 {
            MIDIClientDispose(client)
            client = 0
        }
    }

    func connectSelectedSources(_ names: [String]) {
        selectedSourceNames = names

        guard inputPort != 0 else {
            connectedSourceNames = Set(names)
            return
        }

        let targetNames = Set(names)

        for (endpoint, refCon) in connections {
            if let name = sourceNamesByEndpoint[endpoint], !targetNames.contains(name) {
                MIDIPortDisconnectSource(inputPort, endpoint)
                Unmanaged<SourceContext>.fromOpaque(refCon).release()
                connections.removeValue(forKey: endpoint)
                sourceNamesByEndpoint.removeValue(forKey: endpoint)
            }
        }

        let count = MIDIGetNumberOfSources()
        if count > 0 {
            for index in 0..<count {
                let endpoint = MIDIGetSource(index)
                guard endpoint != 0 else { continue }
                guard let name = sourceName(for: endpoint) else { continue }
                guard targetNames.contains(name), connections[endpoint] == nil else { continue }

                let context = SourceContext(name: name)
                let refCon = Unmanaged.passRetained(context).toOpaque()
                let status = MIDIPortConnectSource(inputPort, endpoint, refCon)
                if status == noErr {
                    connections[endpoint] = refCon
                    sourceNamesByEndpoint[endpoint] = name
                } else {
                    Unmanaged<SourceContext>.fromOpaque(refCon).release()
                }
            }
        }

        connectedSourceNames = Set(sourceNamesByEndpoint.values)
    }

    func handleSystemChange() {
        connectSelectedSources(selectedSourceNames)
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

    private func handle(packetList: UnsafePointer<MIDIPacketList>, sourceName: String) {
        var packet = packetList.pointee.packet
        for _ in 0..<packetList.pointee.numPackets {
            let length = Int(packet.length)
            let bytes = withUnsafeBytes(of: &packet.data) { rawBuffer in
                Array(rawBuffer.prefix(length))
            }
            let events = Self.parse(bytes: bytes, sourceName: sourceName)
            for event in events {
                handler?(event)
            }
            packet = MIDIPacketNext(&packet).pointee
        }
    }

    private func sourceName(for endpoint: MIDIEndpointRef) -> String? {
        var name: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &name)
        guard status == noErr, let cfName = name?.takeRetainedValue() else { return nil }
        return cfName as String
    }

    private func sourceName(from refCon: UnsafeMutableRawPointer?) -> String? {
        guard let refCon else { return nil }
        return Unmanaged<SourceContext>.fromOpaque(refCon).takeUnretainedValue().name
    }
}

enum MidiListenerError: Error {
    case midiUnavailable
}
