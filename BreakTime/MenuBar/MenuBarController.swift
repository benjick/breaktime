import AppKit

@MainActor
class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var menuBuilder: TrayMenuBuilder?
    private var displayTimer: Timer?
    private var pulseToggle = false

    weak var appState: AppState?

    var onPause: ((TimeInterval?) -> Void)?       // nil = indefinite
    var onResume: (() -> Void)?
    var onTakeBreakNow: ((BreakTier) -> Void)?
    var onTestBreak: ((BreakTier) -> Void)?
    var onOpenSettings: (() -> Void)?

    func setup(appState: AppState) {
        self.appState = appState

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        menuBuilder = TrayMenuBuilder(appState: appState)
        menuBuilder?.onLaunchAtLoginToggled = {
            LaunchAtLoginManager.shared.toggle()
        }
        menuBuilder?.onPause = { [weak self] duration in
            self?.onPause?(duration)
        }
        menuBuilder?.onResume = { [weak self] in
            self?.onResume?()
        }
        menuBuilder?.onTakeBreakNow = { [weak self] tier in
            self?.onTakeBreakNow?(tier)
        }
        menuBuilder?.onTestBreak = { [weak self] tier in
            self?.onTestBreak?(tier)
        }
        menuBuilder?.onOpenSettings = { [weak self] in
            self?.onOpenSettings?()
        }
        menuBuilder?.onQuit = {
            NSApplication.shared.terminate(nil)
        }

        startDisplayTimer()
        updateMenu()
    }

    func updateMenu() {
        guard let menuBuilder = menuBuilder else { return }
        let menu = menuBuilder.buildMenu()
        menu.delegate = self
        statusItem?.menu = menu
    }

    // Rebuild menu with fresh countdowns right when it opens
    nonisolated func menuWillOpen(_ menu: NSMenu) {
        MainActor.assumeIsolated {
            guard let menuBuilder = self.menuBuilder else { return }
            menu.removeAllItems()
            for item in menuBuilder.buildMenu().items {
                // Move items from new menu to existing one
                item.menu?.removeItem(item)
                menu.addItem(item)
            }
        }
    }

    func updateTitle() {
        guard let appState = appState, let button = statusItem?.button else { return }

        if appState.pauseState.isPaused {
            let pauseImage = NSImage(systemSymbolName: "pause.fill",
                                     accessibilityDescription: "Paused")
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            button.image = pauseImage?.withSymbolConfiguration(config)
            if let remaining = appState.pauseState.remainingSeconds {
                button.title = " \(formatTimerDisplay(remaining))"
            } else {
                button.title = " Paused"
            }
            return
        }

        if case .warning(let tier, _) = appState.breakPhase {
            pulseToggle.toggle()
            button.image = makeDotImage(color: tier.color.nsColor, hollow: pulseToggle)
            button.title = ""
        } else if case .idle = appState.breakPhase, let countdown = appState.nextBreakCountdown,
           let tier = appState.nextBreakTier {
            let deferred = !appState.queuedBreaks.isEmpty
            button.image = makeDotImage(color: tier.color.nsColor, hollow: deferred)
            button.title = " \(formatTimerDisplay(countdown))"
        } else {
            button.image = makeDotImage(color: .gray)
            button.title = ""
        }
    }

    private func makeDotImage(color: NSColor, hollow: Bool = false) -> NSImage {
        let size = NSSize(width: 10, height: 10)
        let image = NSImage(size: size, flipped: false) { rect in
            let inset = rect.insetBy(dx: 1, dy: 1)
            if hollow {
                color.setStroke()
                let path = NSBezierPath(ovalIn: inset.insetBy(dx: 0.75, dy: 0.75))
                path.lineWidth = 1.5
                path.stroke()
            } else {
                color.setFill()
                NSBezierPath(ovalIn: inset).fill()
            }
            return true
        }
        image.isTemplate = false
        return image
    }

    private func startDisplayTimer() {
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTitle()
            }
        }
    }

}

func formatTimerDisplay(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    let h = totalSeconds / 3600
    let m = (totalSeconds % 3600) / 60
    let s = totalSeconds % 60

    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    } else {
        return String(format: "%d:%02d", m, s)
    }
}
