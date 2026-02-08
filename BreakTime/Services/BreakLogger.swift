import Foundation

@MainActor
class BreakLogger {
    static let shared = BreakLogger()

    private let fileManager = FileManager.default
    private let maxEntries = 1000

    private var logDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("BreakTime", isDirectory: true)
    }

    private var logFileURL: URL {
        logDirectory.appendingPathComponent("break-log.json")
    }

    private init() {}

    func log(_ entry: BreakLogEntry) {
        var entries = loadEntries()
        entries.append(entry)

        // Trim to max entries
        if entries.count > maxEntries {
            entries = Array(entries.suffix(maxEntries))
        }

        save(entries)
    }

    func log(tierName: String, tierColor: String, event: BreakLogEvent, reason: String? = nil) {
        let entry = BreakLogEntry(tierName: tierName, tierColor: tierColor, event: event, reason: reason)
        log(entry)
    }

    func loadEntries() -> [BreakLogEntry] {
        guard fileManager.fileExists(atPath: logFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: logFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([BreakLogEntry].self, from: data)
        } catch {
            print("Failed to load break log: \(error)")
            return []
        }
    }

    private func save(_ entries: [BreakLogEntry]) {
        do {
            if !fileManager.fileExists(atPath: logDirectory.path) {
                try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: logFileURL, options: .atomic)
        } catch {
            print("Failed to save break log: \(error)")
        }
    }
}
