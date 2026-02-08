import Foundation

enum BreakPhase: Equatable {
    case idle
    case warning(tier: BreakTier, startedAt: Date)
    case overlay(tier: BreakTier)
}

struct OverlayState: Equatable {
    var tier: BreakTier
    var remainingBreakTime: TimeInterval
    var isGracePeriod: Bool
    var lockAfterBreak: Bool
    var lastInputTime: Date

    init(tier: BreakTier) {
        self.tier = tier
        self.remainingBreakTime = tier.breakDuration
        self.isGracePeriod = true
        self.lockAfterBreak = false
        self.lastInputTime = Date()
    }
}
