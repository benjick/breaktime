import Foundation

enum PauseState: Equatable {
    case notPaused
    case pausedUntil(Date)
    case pausedIndefinitely

    var isPaused: Bool {
        switch self {
        case .notPaused: return false
        case .pausedUntil(let date): return Date() < date
        case .pausedIndefinitely: return true
        }
    }

    var remainingSeconds: TimeInterval? {
        switch self {
        case .notPaused: return nil
        case .pausedUntil(let date):
            let remaining = date.timeIntervalSinceNow
            return remaining > 0 ? remaining : nil
        case .pausedIndefinitely: return nil
        }
    }
}
