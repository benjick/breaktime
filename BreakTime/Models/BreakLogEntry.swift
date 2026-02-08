import Foundation

enum BreakLogEvent: String, Codable {
    case completed        // timer ran to zero
    case skipped          // user clicked skip
    case postponed        // user clicked postpone
    case deferred         // exception prevented break
    case started          // break overlay appeared
}

struct BreakLogEntry: Codable, Identifiable {
    var id: UUID
    var date: Date
    var tierName: String
    var tierColor: String
    var event: BreakLogEvent
    var reason: String?   // e.g. "microphone", "screen sharing", "Zoom (opened)", "postponed 5 min"

    init(tierName: String, tierColor: String, event: BreakLogEvent, reason: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.tierName = tierName
        self.tierColor = tierColor
        self.event = event
        self.reason = reason
    }
}
