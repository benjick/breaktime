import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private let menuBarController = MenuBarController()
    private let timerEngine = TimerEngine()
    private let breakScheduler = BreakScheduler()
    private let exceptionMonitor = ExceptionMonitor()
    private let settingsWindowController = SettingsWindowController()
    private let slackIntegration = SlackIntegration()
    private let configManager = ConfigManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadConfig()
        slackIntegration.updateToken(appState.config.slackToken)
        setupBreakScheduler()
        setupExceptionMonitor()
        setupMenuBar()
        setupTimerEngine()
        setupConfigChangeListener()
        checkPermissions()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerEngine.stop()
        exceptionMonitor.stop()
    }

    // MARK: - Setup

    private func loadConfig() {
        appState.config = configManager.load()
        appState.initializeCounters()
    }

    private func setupMenuBar() {
        menuBarController.setup(appState: appState)

        menuBarController.onPause = { [weak self] duration in
            guard let self = self else { return }
            if let duration = duration {
                self.appState.pauseState = .pausedUntil(Date().addingTimeInterval(duration))
            } else {
                self.appState.pauseState = .pausedIndefinitely
            }
            self.menuBarController.updateMenu()
        }

        menuBarController.onResume = { [weak self] in
            guard let self = self else { return }
            self.appState.pauseState = .notPaused
            self.menuBarController.updateMenu()
        }

        menuBarController.onTakeBreakNow = { [weak self] tier in
            self?.breakScheduler.startBreakImmediately(tier: tier)
        }

        menuBarController.onTestBreak = { [weak self] tier in
            self?.breakScheduler.startWarning(tier: tier)
        }

        menuBarController.onOpenSettings = { [weak self] in
            self?.settingsWindowController.showWindow()
        }
    }

    private func setupTimerEngine() {
        timerEngine.onTierThresholdReached = { [weak self] tier in
            self?.breakScheduler.handleTierThresholdReached(tier)
        }
        timerEngine.start(appState: appState)
    }

    private func setupBreakScheduler() {
        breakScheduler.setup(appState: appState)

        breakScheduler.onBreakStarted = { [weak self] _ in
            self?.menuBarController.updateMenu()
        }

        breakScheduler.onOverlayStarted = { [weak self] tier in
            self?.slackIntegration.breakStarted(breakDuration: tier.breakDuration)
        }

        breakScheduler.onBreakEnded = { [weak self] in
            self?.menuBarController.updateMenu()
            self?.slackIntegration.breakEnded()
        }
    }

    private func setupExceptionMonitor() {
        exceptionMonitor.start(appState: appState)

        exceptionMonitor.onExceptionStateChanged = { [weak self] isActive in
            guard let self = self else { return }
            if isActive {
                // Exception started — cancel any active warning/break and re-queue it
                switch self.appState.breakPhase {
                case .warning(let tier, _), .overlay(let tier):
                    self.appState.queuedBreaks.insert(tier.id)
                    self.breakScheduler.cancelCurrentBreak()
                case .idle:
                    break
                }
            } else {
                // Exception ended — fire queued breaks
                self.breakScheduler.handleExceptionEnded()
            }
        }
    }

    private func setupConfigChangeListener() {
        settingsWindowController.setup(appState: appState)

        NotificationCenter.default.addObserver(
            forName: .configChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                // Cancel active break if config changes (tier may have been deleted/modified)
                if case .idle = self.appState.breakPhase { } else {
                    self.breakScheduler.cancelCurrentBreak()
                }
                self.appState.initializeCounters()
                self.slackIntegration.updateToken(self.appState.config.slackToken)
                self.menuBarController.updateMenu()
            }
        }
    }

    private func checkPermissions() {
        // Test if CGEventSource works — if not, we likely need Input Monitoring permission
        let testIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        if testIdle == -1 {
            // Permission likely not granted — show a helpful alert
            let alert = NSAlert()
            alert.messageText = "Input Monitoring Permission Required"
            alert.informativeText = "BreakTime needs Input Monitoring permission to detect keyboard and mouse activity.\n\nPlease go to System Settings → Privacy & Security → Input Monitoring and enable BreakTime."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
