import AppKit

@MainActor
class TrayMenuBuilder {
    private weak var appState: AppState?

    var onLaunchAtLoginToggled: (() -> Void)?
    var onPause: ((TimeInterval?) -> Void)?   // nil = indefinite
    var onResume: (() -> Void)?
    var onTakeBreakNow: ((BreakTier) -> Void)?
    var onTestBreak: ((BreakTier) -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    init(appState: AppState) {
        self.appState = appState
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()

        addTierStatuses(to: menu)
        menu.addItem(NSMenuItem.separator())
        addLaunchAtLogin(to: menu)
        addPauseSection(to: menu)
        addTakeBreakNow(to: menu)
        addTestBreak(to: menu)
        menu.addItem(NSMenuItem.separator())
        addSettingsItem(to: menu)
        menu.addItem(NSMenuItem.separator())
        addQuitItem(to: menu)

        return menu
    }

    // MARK: - Tier Statuses

    private func addTierStatuses(to menu: NSMenu) {
        guard let appState = appState else { return }

        for tier in appState.config.tiers {
            let counter = appState.tierCounters[tier.id, default: 0]
            let remaining = tier.activeInterval - counter
            let timeStr = formatTimerDisplay(max(0, remaining))

            let item = NSMenuItem(title: "\(tier.name)  \(timeStr)", action: nil, keyEquivalent: "")
            item.isEnabled = false

            item.image = makeDotImage(color: tier.color.nsColor)

            menu.addItem(item)
        }
    }

    // MARK: - Launch at Login

    private func addLaunchAtLogin(to menu: NSMenu) {
        let item = NSMenuItem(
            title: "Launch at Login",
            action: #selector(launchAtLoginClicked(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        menu.addItem(item)
    }

    // MARK: - Pause

    private func addPauseSection(to menu: NSMenu) {
        guard let appState = appState else { return }

        if appState.pauseState.isPaused {
            let resumeItem = NSMenuItem(
                title: "Resume Timers",
                action: #selector(resumeClicked(_:)),
                keyEquivalent: ""
            )
            resumeItem.target = self
            menu.addItem(resumeItem)
        } else {
            let pauseSubmenu = NSMenu()
            let durations: [(String, TimeInterval?)] = [
                ("1 Hour", 3600),
                ("2 Hours", 7200),
                ("3 Hours", 10800),
                ("6 Hours", 21600),
                ("12 Hours", 43200),
                ("Indefinitely", nil),
            ]

            for (title, duration) in durations {
                let item = NSMenuItem(
                    title: title,
                    action: #selector(pauseClicked(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = duration as AnyObject?
                pauseSubmenu.addItem(item)
            }

            let pauseItem = NSMenuItem(title: "Pause Timers", action: nil, keyEquivalent: "")
            pauseItem.submenu = pauseSubmenu
            menu.addItem(pauseItem)
        }
    }

    // MARK: - Take a Break Now

    private func addTakeBreakNow(to menu: NSMenu) {
        guard let appState = appState else { return }

        let submenu = NSMenu()
        for tier in appState.config.tiers {
            let item = NSMenuItem(
                title: tier.name,
                action: #selector(takeBreakNowClicked(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = tier.id
            item.image = makeDotImage(color: tier.color.nsColor)

            submenu.addItem(item)
        }

        let takeBreakItem = NSMenuItem(title: "Take a Break Now", action: nil, keyEquivalent: "")
        takeBreakItem.submenu = submenu
        menu.addItem(takeBreakItem)
    }

    // MARK: - Test Break

    private func addTestBreak(to menu: NSMenu) {
        guard let appState = appState else { return }

        let submenu = NSMenu()
        for tier in appState.config.tiers {
            let item = NSMenuItem(
                title: tier.name,
                action: #selector(testBreakClicked(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = tier.id
            item.image = makeDotImage(color: tier.color.nsColor)

            submenu.addItem(item)
        }

        let testBreakItem = NSMenuItem(title: "Test Break", action: nil, keyEquivalent: "")
        testBreakItem.submenu = submenu
        menu.addItem(testBreakItem)
    }

    // MARK: - Settings

    private func addSettingsItem(to menu: NSMenu) {
        let item = NSMenuItem(
            title: "Settings...",
            action: #selector(settingsClicked(_:)),
            keyEquivalent: ","
        )
        item.target = self
        menu.addItem(item)
    }

    // MARK: - Quit

    private func addQuitItem(to menu: NSMenu) {
        let item = NSMenuItem(
            title: "Quit BreakTime",
            action: #selector(quitClicked(_:)),
            keyEquivalent: "q"
        )
        item.target = self
        menu.addItem(item)
    }

    // MARK: - Actions

    @objc private func launchAtLoginClicked(_ sender: NSMenuItem) {
        onLaunchAtLoginToggled?()
    }

    @objc private func pauseClicked(_ sender: NSMenuItem) {
        let duration = sender.representedObject as? TimeInterval
        onPause?(duration)
    }

    @objc private func resumeClicked(_ sender: NSMenuItem) {
        onResume?()
    }

    @objc private func takeBreakNowClicked(_ sender: NSMenuItem) {
        guard let tierId = sender.representedObject as? UUID,
              let tier = appState?.config.tiers.first(where: { $0.id == tierId }) else { return }
        onTakeBreakNow?(tier)
    }

    @objc private func testBreakClicked(_ sender: NSMenuItem) {
        guard let tierId = sender.representedObject as? UUID,
              let tier = appState?.config.tiers.first(where: { $0.id == tierId }) else { return }
        onTestBreak?(tier)
    }

    @objc private func settingsClicked(_ sender: NSMenuItem) {
        onOpenSettings?()
    }

    @objc private func quitClicked(_ sender: NSMenuItem) {
        onQuit?()
    }

    // MARK: - Helpers

    private func makeDotImage(color: NSColor) -> NSImage {
        let dotSize = NSSize(width: 10, height: 10)
        return NSImage(size: dotSize, flipped: false) { rect in
            color.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
    }
}
