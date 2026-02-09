import CoreGraphics
import Foundation

struct IdleDetector {
    static func secondsSinceLastInput() -> TimeInterval {
        let keyboard = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let leftDown = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDown)
        let rightDown = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .rightMouseDown)
        let scroll = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .scrollWheel)
        // mouseMoved excluded — synthetic mouse movers (e.g. Amphetamine) only generate
        // mouseMoved events, so ignoring them avoids counting fake activity.
        // Real mouse usage is still captured via clicks and scrolls.
        return min(keyboard, leftDown, rightDown, scroll)
    }
}
