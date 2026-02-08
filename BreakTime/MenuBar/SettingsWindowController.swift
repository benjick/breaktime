import AppKit
import SwiftUI

@MainActor
class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private weak var appState: AppState?

    func setup(appState: AppState) {
        self.appState = appState
    }

    func showWindow() {
        if window == nil {
            createWindow()
        }

        NSApp.setActivationPolicy(.regular)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createWindow() {
        guard let appState = appState else { return }

        let contentView = SettingsView(appState: appState)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 450),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window?.center()
        window?.title = "BreakTime Settings"
        window?.contentView = NSHostingView(rootView: contentView)
        window?.delegate = self
        window?.minSize = NSSize(width: 450, height: 350)
        window?.isReleasedWhenClosed = false
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
