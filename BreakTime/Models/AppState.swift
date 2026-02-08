import Foundation

@Observable
@MainActor
class AppState {
    var config: Config
    var tierCounters: [UUID: TimeInterval] = [:]  // active time per tier
    var pauseState: PauseState = .notPaused
    var breakPhase: BreakPhase = .idle
    var overlayState: OverlayState?
    var queuedBreaks: Set<UUID> = []  // tier IDs queued during exceptions
    var postponements: [UUID: Date] = [:]  // tier ID -> postponed until date
    var exceptionsActive: Bool = false
    var exceptionReason: String?

    init(config: Config = .defaultConfig) {
        self.config = config
        initializeCounters()
    }

    func initializeCounters() {
        for tier in config.tiers {
            if tierCounters[tier.id] == nil {
                tierCounters[tier.id] = 0
            }
        }
        // Clean up counters for removed tiers
        let validIds = Set(config.tiers.map { $0.id })
        tierCounters = tierCounters.filter { validIds.contains($0.key) }
    }

    func incrementCounters(by elapsed: TimeInterval) {
        for tier in config.tiers {
            tierCounters[tier.id, default: 0] += elapsed
        }
    }

    func unwindCounters(by elapsed: TimeInterval) {
        for tier in config.tiers {
            let current = tierCounters[tier.id, default: 0]
            tierCounters[tier.id] = max(0, current - elapsed)
        }
    }

    func cascadeReset(triggeringTier: BreakTier) {
        for tier in config.tiers {
            if tier.breakDuration <= triggeringTier.breakDuration {
                tierCounters[tier.id] = 0
            }
        }
        // Clear postponements for reset tiers
        for tier in config.tiers where tier.breakDuration <= triggeringTier.breakDuration {
            postponements.removeValue(forKey: tier.id)
        }
        // Clear from queued breaks
        for tier in config.tiers where tier.breakDuration <= triggeringTier.breakDuration {
            queuedBreaks.remove(tier.id)
        }
    }

    /// Returns the tier with the nearest upcoming break, accounting for merge window
    var nextBreakTier: BreakTier? {
        let sorted = config.tiers
            .compactMap { tier -> (BreakTier, TimeInterval)? in
                let counter = tierCounters[tier.id, default: 0]
                let remaining = tier.activeInterval - counter
                guard remaining > 0 else { return nil }
                return (tier, remaining)
            }
            .sorted { $0.1 < $1.1 }

        guard let nearest = sorted.first else {
            // All timers are at or past threshold
            return config.tiers.max(by: { $0.breakDuration < $1.breakDuration })
        }

        // Check merge window: if a longer break is due within merge window of the nearest
        for (tier, remaining) in sorted {
            if tier.breakDuration > nearest.0.breakDuration &&
               remaining - nearest.1 <= config.mergeWindow &&
               remaining <= nearest.1 + config.mergeWindow {
                return tier
            }
        }

        return nearest.0
    }

    var nextBreakCountdown: TimeInterval? {
        guard let tier = nextBreakTier else { return nil }
        let counter = tierCounters[tier.id, default: 0]
        let remaining = tier.activeInterval - counter
        return remaining > 0 ? remaining : 0
    }

    func isPostponed(_ tier: BreakTier) -> Bool {
        guard let until = postponements[tier.id] else { return false }
        return Date() < until
    }
}
