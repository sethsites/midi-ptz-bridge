import Foundation

final class BridgeController {
    private let listener: MidiListener
    private let configStore: ConfigStore
    private let httpClient: PTZHttpClient
    private let onLogEvent: (LogEvent) -> Void
    private let onFlash: (LogEventStatus) -> Void

    init(
        listener: MidiListener = MidiListener(),
        configStore: ConfigStore = ConfigStore(),
        httpClient: PTZHttpClient = PTZHttpClient(),
        onLogEvent: @escaping (LogEvent) -> Void = { _ in },
        onFlash: @escaping (LogEventStatus) -> Void = { _ in }
    ) {
        self.listener = listener
        self.configStore = configStore
        self.httpClient = httpClient
        self.onLogEvent = onLogEvent
        self.onFlash = onFlash
    }

    nonisolated deinit {}

    func start() {
        do {
            try listener.start { [weak self] event in
                Task {
                    await self?.handle(event)
                }
            }
        } catch {
            let log = LogEvent(type: .midi, status: .fail, summary: "MIDI listener failed", details: "\(error)")
            onLogEvent(log)
            onFlash(.fail)
        }
    }

    func stop() {
        listener.stop()
    }

    func handle(_ event: MidiEvent) async {
        logMidi(event)

        let config = (try? configStore.load()) ?? .empty
        if !config.midiSources.isEmpty, !config.midiSources.contains(event.sourceName) {
            return
        }

        let router = MappingRouter(config: config)
        let actions = router.resolveAll(for: event)
        guard !actions.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for action in actions {
                group.addTask { [httpClient, onLogEvent, onFlash] in
                    await Self.perform(action, using: httpClient, onLogEvent: onLogEvent, onFlash: onFlash)
                }
            }
        }
    }

    private func logMidi(_ event: MidiEvent) {
        let summary = "MIDI \(event.sourceName) note \(event.note) \(event.onOff.rawValue)"
        let details = "velocity: \(event.velocity)"
        onLogEvent(LogEvent(type: .midi, status: .ok, summary: summary, details: details))
    }

    private static func perform(
        _ action: ResolvedAction,
        using httpClient: PTZHttpClient,
        onLogEvent: (LogEvent) -> Void,
        onFlash: (LogEventStatus) -> Void
    ) async {
        let camera = action.camera
        let command = action.command
        let requestURL = (try? httpClient.buildRequest(camera: camera, command: command).url?.absoluteString) ?? "invalid-url"
        let summary = "PTZ \(camera.name) \(command.name)"

        do {
            let response = try await httpClient.send(camera: camera, command: command)
            let details = "\(requestURL) -> \(response.httpResponse.statusCode)"
            onLogEvent(LogEvent(type: .http, status: .ok, summary: summary, details: details))
            onFlash(.ok)
        } catch {
            let details = "\(requestURL) -> \(error)"
            onLogEvent(LogEvent(type: .http, status: .fail, summary: summary, details: details))
            onFlash(.fail)
        }
    }
}
