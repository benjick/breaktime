import Foundation

@MainActor
class ConfigManager {
    static let shared = ConfigManager()

    private let fileManager = FileManager.default

    private var configDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("BreakTime", isDirectory: true)
    }

    private var configFileURL: URL {
        configDirectory.appendingPathComponent("config.json")
    }

    private init() {}

    func load() -> Config {
        guard fileManager.fileExists(atPath: configFileURL.path) else {
            return .defaultConfig
        }

        do {
            let data = try Data(contentsOf: configFileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(Config.self, from: data)
        } catch {
            print("Failed to load config: \(error)")
            return .defaultConfig
        }
    }

    func save(_ config: Config) {
        do {
            if !fileManager.fileExists(atPath: configDirectory.path) {
                try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configFileURL, options: .atomic)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
