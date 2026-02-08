import AppKit
import SwiftUI

@MainActor
class OverlayManager {
    private var warningWindows: [NSWindow] = []
    private var overlayWindows: [BreakOverlayWindow] = []
    private weak var currentAppState: AppState?

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Rebuild windows on display change if active
            Task { @MainActor in
                guard let self = self else { return }
                if !self.warningWindows.isEmpty {
                    let color = (self.warningWindows.first?.contentView as? WarningBorderNSView)?.borderColor ?? .yellow
                    let opacity = self.warningWindows.first?.alphaValue ?? 1.0
                    self.hideWarningBorders()
                    self.showWarningBorders(color: color)
                    self.updateWarningOpacity(opacity)
                }
                if !self.overlayWindows.isEmpty, let appState = self.currentAppState {
                    let wasBlocking = self.overlayWindows.first?.isInputBlocked ?? false
                    self.hideOverlayWindows()
                    self.showBreakOverlay(appState: appState)
                    if wasBlocking {
                        self.lockOverlay()
                    }
                }
            }
        }
    }

    // MARK: - Warning Borders

    func showWarningBorders(color: NSColor) {
        hideWarningBorders()

        for screen in NSScreen.screens {
            let window = createWarningWindow(screen: screen, color: color)
            warningWindows.append(window)
            window.orderFrontRegardless()
        }
    }

    func updateWarningOpacity(_ opacity: CGFloat) {
        for window in warningWindows {
            window.alphaValue = opacity
        }
    }

    func hideWarningBorders() {
        for window in warningWindows {
            window.orderOut(nil)
        }
        warningWindows.removeAll()
    }

    private func createWarningWindow(screen: NSScreen, color: NSColor) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.alphaValue = 0

        let borderView = WarningBorderNSView(frame: screen.frame)
        borderView.borderColor = color
        window.contentView = borderView

        return window
    }

    // MARK: - Break Overlay

    func showBreakOverlay(appState: AppState) {
        hideOverlayWindows()
        currentAppState = appState

        for screen in NSScreen.screens {
            let window = createOverlayWindow(screen: screen, appState: appState)
            overlayWindows.append(window)
            window.orderFrontRegardless()
        }
    }

    func lockOverlay() {
        // Make the primary overlay window key and block input
        for window in overlayWindows {
            window.isInputBlocked = true
        }
        if let primaryWindow = overlayWindows.first {
            primaryWindow.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func hideOverlayWindows() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        currentAppState = nil
    }

    private func createOverlayWindow(screen: NSScreen, appState: AppState) -> BreakOverlayWindow {
        let window = BreakOverlayWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let overlayView = BreakOverlayView(appState: appState)
        window.contentView = NSHostingView(rootView: overlayView)

        return window
    }

    // MARK: - Cleanup

    func hideAll() {
        hideWarningBorders()
        hideOverlayWindows()
    }
}

// MARK: - Break Overlay Window (blocks input when locked)

class BreakOverlayWindow: NSWindow {
    var isInputBlocked = false

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        if isInputBlocked {
            switch event.type {
            case .keyDown, .keyUp, .flagsChanged:
                return  // swallow keyboard input
            default:
                break
            }
        }
        super.sendEvent(event)
    }
}

// MARK: - Warning Border NSView

class WarningBorderNSView: NSView {
    var borderColor: NSColor = .yellow {
        didSet { needsDisplay = true }
    }

    private let borderWidth: CGFloat = 8.0

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(borderWidth)
        context.stroke(bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
    }
}
