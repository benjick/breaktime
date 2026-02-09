import AppKit

@MainActor
class TimerEngine {
    private weak var appState: AppState?
    private var timer: Timer?
    private var lastTickTime: Date = Date()
    private var mergeLoggedTiers: Set<UUID> = []

    var onTierThresholdReached: ((BreakTier) -> Void)?

    func start(appState: AppState) {
        self.appState = appState
        lastTickTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        // On wake from sleep, bulk-unwind counters by the full idle duration
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let appState = self.appState else { return }
                let idleSeconds = IdleDetector.secondsSinceLastInput()
                if idleSeconds > appState.config.idleThreshold {
                    appState.unwindCounters(by: idleSeconds)
                }
                self.lastTickTime = Date()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let appState = appState else { return }

        let now = Date()
        let elapsed = now.timeIntervalSince(lastTickTime)
        lastTickTime = now

        // Clamp elapsed to avoid huge jumps (e.g., after wake)
        let clampedElapsed = min(elapsed, 5.0)

        // Check if paused
        if appState.pauseState.isPaused {
            // Auto-resume timed pauses that expired
            if case .pausedUntil(let date) = appState.pauseState, Date() >= date {
                appState.pauseState = .notPaused
            }
            return
        }

        // Skip if break is active
        if case .idle = appState.breakPhase {
            // Continue — timers tick in idle phase
        } else {
            return
        }

        // Query idle
        let idleSeconds = IdleDetector.secondsSinceLastInput()

        if idleSeconds < appState.config.idleThreshold {
            // User is active — increment all counters
            appState.incrementCounters(by: clampedElapsed)
        } else {
            // User is idle past threshold — unwind counters
            appState.unwindCounters(by: clampedElapsed)
        }

        // Check thresholds
        for tier in appState.config.tiers {
            let counter = appState.tierCounters[tier.id, default: 0]
            if counter >= tier.activeInterval {
                // Check postponement
                if appState.isPostponed(tier) {
                    continue
                }

                // Check merge window: skip if a longer break is due soon
                if let mergedInto = mergeTarget(tier: tier, appState: appState) {
                    if !mergeLoggedTiers.contains(tier.id) {
                        mergeLoggedTiers.insert(tier.id)
                        BreakLogger.shared.log(tierName: tier.name, tierColor: tier.color.rawValue, event: .deferred, reason: "merged into \(mergedInto.name)")
                    }
                    continue
                }
                mergeLoggedTiers.remove(tier.id)

                onTierThresholdReached?(tier)
                break  // Only fire one break at a time
            }
        }
    }

    private func mergeTarget(tier: BreakTier, appState: AppState) -> BreakTier? {
        for otherTier in appState.config.tiers {
            guard otherTier.breakDuration > tier.breakDuration else { continue }
            let otherCounter = appState.tierCounters[otherTier.id, default: 0]
            let otherRemaining = otherTier.activeInterval - otherCounter
            if otherRemaining > 0 && otherRemaining <= appState.config.mergeWindow {
                return otherTier
            }
        }
        return nil
    }
}
