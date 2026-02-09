import Foundation

struct Config: Codable, Equatable {
    var tiers: [BreakTier]
    var idleThreshold: TimeInterval       // seconds, default 180 (3 min)
    var mergeWindow: TimeInterval          // seconds, default 300 (5 min)
    var exceptionRules: [ExceptionRule]
    var autoExceptionMicrophone: Bool
    var autoExceptionScreenSharing: Bool

    static let defaultConfig = Config(
        tiers: [.defaultShort, .defaultLong],
        idleThreshold: 180,
        mergeWindow: 300,
        exceptionRules: [],
        autoExceptionMicrophone: true,
        autoExceptionScreenSharing: true
    )
}
