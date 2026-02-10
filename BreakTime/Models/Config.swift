import Foundation

struct Config: Codable, Equatable {
    var tiers: [BreakTier]
    var idleThreshold: TimeInterval       // seconds, default 180 (3 min)
    var mergeWindow: TimeInterval          // seconds, default 300 (5 min)
    var warningDuration: TimeInterval      // seconds, default 30
    var exceptionRules: [ExceptionRule]
    var autoExceptionMicrophone: Bool
    var autoExceptionScreenSharing: Bool
    var slackToken: String?

    static let defaultConfig = Config(
        tiers: [.defaultShort, .defaultLong],
        idleThreshold: 180,
        mergeWindow: 300,
        warningDuration: 30,
        exceptionRules: [],
        autoExceptionMicrophone: true,
        autoExceptionScreenSharing: true,
        slackToken: nil
    )
}
