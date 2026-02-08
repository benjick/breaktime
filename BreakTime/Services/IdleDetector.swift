import CoreGraphics
import Foundation

struct IdleDetector {
    static func secondsSinceLastInput(monitoring: InputMonitoring) -> TimeInterval {
        switch monitoring {
        case .keyboard:
            return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        case .mouse:
            let moved = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
            let leftDown = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDown)
            let rightDown = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .rightMouseDown)
            let scroll = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .scrollWheel)
            return min(moved, leftDown, rightDown, scroll)
        case .both:
            let keyboard = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
            let moved = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
            let leftDown = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDown)
            let rightDown = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .rightMouseDown)
            let scroll = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .scrollWheel)
            return min(keyboard, moved, leftDown, rightDown, scroll)
        }
    }
}
