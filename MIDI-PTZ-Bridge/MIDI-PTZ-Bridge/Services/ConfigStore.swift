import Foundation

struct ConfigStore {
    private let baseURL: URL
    private let fileName = "config.json"

    init(baseURL: URL? = nil) {
        if let baseURL {
            self.baseURL = baseURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.baseURL = appSupport.appendingPathComponent("MIDI-PTZ-Bridge", isDirectory: true)
        }
    }

    func load() throws -> AppConfig {
        let url = baseURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .empty
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AppConfig.self, from: data)
    }

    func save(_ config: AppConfig) throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let url = baseURL.appendingPathComponent(fileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(config)
        try data.write(to: url, options: .atomic)
    }
}
