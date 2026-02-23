import Foundation

struct LogStore {
    private let baseURL: URL
    private let maxBytes: Int
    private let maxFiles: Int
    private let fileManager: FileManager
    private let logFilename = "activity.log"

    private(set) var recentEvents: [LogEvent] = []

    init(baseURL: URL = LogStore.defaultBaseURL(), maxBytes: Int = 10 * 1024 * 1024, maxFiles: Int = 3, fileManager: FileManager = .default) {
        self.baseURL = baseURL
        self.maxBytes = max(1, maxBytes)
        self.maxFiles = max(1, maxFiles)
        self.fileManager = fileManager
    }

    mutating func append(_ event: LogEvent) {
        updateRecentEvents(with: event)
        ensureDirectoryExists()
        appendLine(format(event))
        rotateIfNeeded()
    }

    private mutating func updateRecentEvents(with event: LogEvent) {
        recentEvents.append(event)
        if recentEvents.count > 5 {
            recentEvents.removeFirst(recentEvents.count - 5)
        }
    }

    private func ensureDirectoryExists() {
        guard !fileManager.fileExists(atPath: baseURL.path) else { return }
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    private func format(_ event: LogEvent) -> String {
        let timestamp = ISO8601DateFormatter().string(from: event.timestamp)
        return "[\(timestamp)] \(event.type.rawValue.uppercased()) \(event.status.rawValue.uppercased()) \(event.summary) | \(event.details)"
    }

    private func appendLine(_ line: String) {
        let url = baseURL.appendingPathComponent(logFilename)
        let data = (line + "\n").data(using: .utf8) ?? Data()

        if fileManager.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            }
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func rotateIfNeeded() {
        let url = baseURL.appendingPathComponent(logFilename)
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber else {
            return
        }

        if size.intValue <= maxBytes { return }

        if maxFiles <= 1 {
            try? fileManager.removeItem(at: url)
            return
        }

        let lastIndex = maxFiles - 1
        let lastURL = baseURL.appendingPathComponent("\(logFilename).\(lastIndex)")
        if fileManager.fileExists(atPath: lastURL.path) {
            try? fileManager.removeItem(at: lastURL)
        }

        if lastIndex >= 2 {
            for idx in stride(from: lastIndex - 1, through: 1, by: -1) {
                let src = baseURL.appendingPathComponent("\(logFilename).\(idx)")
                let dst = baseURL.appendingPathComponent("\(logFilename).\(idx + 1)")
                if fileManager.fileExists(atPath: src.path) {
                    try? fileManager.moveItem(at: src, to: dst)
                }
            }
        }

        let firstRotated = baseURL.appendingPathComponent("\(logFilename).1")
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.moveItem(at: url, to: firstRotated)
        }
    }

    private static func defaultBaseURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return (base ?? FileManager.default.temporaryDirectory).appendingPathComponent("MIDI-PTZ-Bridge", isDirectory: true)
    }
}
