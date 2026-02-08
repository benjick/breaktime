import Foundation

enum TriggerMode: String, Codable {
    case focused
    case opened
}

struct ExceptionRule: Codable, Identifiable, Equatable {
    var id: UUID
    var bundleIdentifier: String
    var appName: String
    var triggerMode: TriggerMode

    init(id: UUID = UUID(), bundleIdentifier: String, appName: String, triggerMode: TriggerMode) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.triggerMode = triggerMode
    }
}
