import AppKit

@MainActor
class BreakScheduler {
    private weak var appState: AppState?
    private var overlayManager: OverlayManager?
    private var warningTimer: Timer?
    private var overlayTimer: Timer?
    private var graceTimer: Timer?
    private var warningStartTime: Date?
    private var sleepPreventionActivity: NSObjectProtocol?

    var onBreakStarted: ((BreakTier) -> Void)?
    var onBreakEnded: (() -> Void)?

    func setup(appState: AppState) {
        self.appState = appState
        overlayManager = OverlayManager()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBreakSkipped),
            name: .breakSkipped,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBreakPostponed(_:)),
            name: .breakPostponed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLockAfterBreakToggled),
            name: .lockAfterBreakToggled,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Cancel any active warning or break, resetting to idle state
    func cancelCurrentBreak() {
        guard let appState = appState else { return }
        cancelAll()
        appState.breakPhase = .idle
        appState.overlayState = nil
        onBreakEnded?()
    }

    func handleTierThresholdReached(_ tier: BreakTier) {
        guard let appState = appState else { return }

        // If exceptions are active, queue the break
        if appState.exceptionsActive {
            if appState.queuedBreaks.insert(tier.id).inserted {
                BreakLogger.shared.log(tierName: tier.name, tierColor: tier.color.rawValue, event: .deferred, reason: appState.exceptionReason ?? "exception")
            }
            return
        }

        // Check postponement
        if appState.isPostponed(tier) {
            return
        }

        startWarning(tier: tier)
    }

    func handleExceptionEnded() {
        guard let appState = appState else { return }
        guard !appState.queuedBreaks.isEmpty else { return }

        // Find the longest queued break
        let longestQueued = appState.config.tiers
            .filter { appState.queuedBreaks.contains($0.id) }
            .max(by: { $0.breakDuration < $1.breakDuration })

        appState.queuedBreaks.removeAll()

        if let tier = longestQueued {
            startWarning(tier: tier)
        }
    }

    func startWarning(tier: BreakTier) {
        guard let appState = appState else { return }

        // Cancel any existing warning/overlay
        cancelAll()

        appState.breakPhase = .warning(tier: tier, startedAt: Date())
        warningStartTime = Date()
        sleepPreventionActivity = ProcessInfo.processInfo.beginActivity(
            options: .idleSystemSleepDisabled,
            reason: "Break in progress"
        )
        onBreakStarted?(tier)

        // Show warning border windows
        overlayManager?.showWarningBorders(color: tier.color.nsColor)

        // Start at 25% opacity
        overlayManager?.updateWarningOpacity(0.25)

        // Ramp opacity from 25% to 100% over warning duration
        warningTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateWarningOpacity()
            }
        }

        // After warning duration, transition to overlay
        let warningDuration = appState.config.warningDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + warningDuration) { [weak self] in
            Task { @MainActor in
                guard let self = self, let appState = self.appState else { return }
                if case .warning(let warnTier, _) = appState.breakPhase, warnTier.id == tier.id {
                    self.startOverlay(tier: tier)
                }
            }
        }
    }

    /// Skip warning, go straight to overlay (for "Take a Break Now")
    func startBreakImmediately(tier: BreakTier) {
        guard appState != nil else { return }
        cancelAll()
        onBreakStarted?(tier)
        startOverlay(tier: tier)
    }

    private func updateWarningOpacity() {
        guard let start = warningStartTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        // Ramp from 0.25 to 1.0 over warning duration
        let warningDuration = appState?.config.warningDuration ?? 30.0
        let opacity = 0.25 + 0.75 * min(1.0, elapsed / warningDuration)
        overlayManager?.updateWarningOpacity(CGFloat(opacity))
    }

    private func startOverlay(tier: BreakTier) {
        guard let appState = appState else { return }

        warningTimer?.invalidate()
        warningTimer = nil
        overlayManager?.hideWarningBorders()

        appState.breakPhase = .overlay(tier: tier)
        appState.overlayState = OverlayState(tier: tier)

        overlayManager?.showBreakOverlay(appState: appState)
        BreakLogger.shared.log(tierName: tier.name, tierColor: tier.color.rawValue, event: .started)

        // Start grace period monitoring
        startGracePeriodMonitoring()
    }

    private func startGracePeriodMonitoring() {
        guard appState != nil else { return }

        overlayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let appState = self.appState,
                      var overlayState = appState.overlayState else { return }

                let idleSeconds = IdleDetector.secondsSinceLastInput()

                if overlayState.isGracePeriod {
                    // Grace period: wait for 5 seconds of no input
                    if idleSeconds >= 5.0 {
                        overlayState.isGracePeriod = false
                        appState.overlayState = overlayState
                        self.overlayManager?.lockOverlay()
                        self.startBreakCountdown()
                    } else if idleSeconds < 1.0 {
                        overlayState.lastInputTime = Date()
                        appState.overlayState = overlayState
                    }
                }
            }
        }
    }

    private func startBreakCountdown() {
        overlayTimer?.invalidate()

        overlayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let appState = self.appState,
                      var overlayState = appState.overlayState else { return }

                overlayState.remainingBreakTime -= 1.0
                appState.overlayState = overlayState

                if overlayState.remainingBreakTime <= 0 {
                    self.completeBreak()
                }
            }
        }
    }

    func completeBreak() {
        guard let appState = appState, let overlayState = appState.overlayState else { return }
        let shouldLock = overlayState.lockAfterBreak
        let tier = overlayState.tier

        BreakLogger.shared.log(tierName: tier.name, tierColor: tier.color.rawValue, event: .completed)

        cancelAll()
        appState.cascadeReset(triggeringTier: tier)
        appState.breakPhase = .idle
        appState.overlayState = nil
        onBreakEnded?()

        if shouldLock {
            ScreenLockService.lockScreen()
        }
    }

    func skipBreak() {
        guard let appState = appState, let overlayState = appState.overlayState else { return }
        let shouldLock = overlayState.lockAfterBreak
        let tier = overlayState.tier

        BreakLogger.shared.log(tierName: tier.name, tierColor: tier.color.rawValue, event: .skipped, reason: "user")

        cancelAll()
        appState.cascadeReset(triggeringTier: tier)
        appState.breakPhase = .idle
        appState.overlayState = nil
        onBreakEnded?()

        if shouldLock {
            ScreenLockService.lockScreen()
        }
    }

    func postponeBreak(minutes: Int) {
        guard let appState = appState, let overlayState = appState.overlayState else { return }
        let shouldLock = overlayState.lockAfterBreak
        let tier = overlayState.tier

        BreakLogger.shared.log(tierName: tier.name, tierColor: tier.color.rawValue, event: .postponed, reason: "\(minutes) min")

        cancelAll()
        // Set counter so there's exactly `minutes` of active time left before re-trigger
        appState.tierCounters[tier.id] = max(0, tier.activeInterval - Double(minutes) * 60)
        appState.breakPhase = .idle
        appState.overlayState = nil
        onBreakEnded?()

        if shouldLock {
            ScreenLockService.lockScreen()
        }
    }

    private func cancelAll() {
        warningTimer?.invalidate()
        warningTimer = nil
        overlayTimer?.invalidate()
        overlayTimer = nil
        graceTimer?.invalidate()
        graceTimer = nil
        overlayManager?.hideAll()
        if let activity = sleepPreventionActivity {
            ProcessInfo.processInfo.endActivity(activity)
            sleepPreventionActivity = nil
        }
    }

    // MARK: - Notification Handlers

    @objc private func handleBreakSkipped() {
        skipBreak()
    }

    @objc private func handleBreakPostponed(_ notification: Notification) {
        guard let minutes = notification.userInfo?["minutes"] as? Int else { return }
        postponeBreak(minutes: minutes)
    }

    @objc private func handleLockAfterBreakToggled() {
        guard let appState = appState else { return }
        appState.overlayState?.lockAfterBreak = true
    }
}

extension Notification.Name {
    static let breakSkipped = Notification.Name("breakSkipped")
    static let breakPostponed = Notification.Name("breakPostponed")
    static let lockAfterBreakToggled = Notification.Name("lockAfterBreakToggled")
    static let configChanged = Notification.Name("configChanged")
}
