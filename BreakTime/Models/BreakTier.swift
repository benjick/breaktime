import Foundation
import SwiftUI

enum TierColor: String, Codable, CaseIterable {
    case yellow
    case red
    case blue
    case green
    case orange
    case purple
    case teal
    case pink

    var color: Color {
        switch self {
        case .yellow: return Color(red: 0.9, green: 0.8, blue: 0.2)
        case .red: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .blue: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .green: return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .orange: return Color(red: 0.95, green: 0.6, blue: 0.2)
        case .purple: return Color(red: 0.6, green: 0.3, blue: 0.9)
        case .teal: return Color(red: 0.2, green: 0.7, blue: 0.7)
        case .pink: return Color(red: 0.9, green: 0.4, blue: 0.6)
        }
    }

    var nsColor: NSColor {
        switch self {
        case .yellow: return NSColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1)
        case .red: return NSColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1)
        case .blue: return NSColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
        case .green: return NSColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)
        case .orange: return NSColor(red: 0.95, green: 0.6, blue: 0.2, alpha: 1)
        case .purple: return NSColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 1)
        case .teal: return NSColor(red: 0.2, green: 0.7, blue: 0.7, alpha: 1)
        case .pink: return NSColor(red: 0.9, green: 0.4, blue: 0.6, alpha: 1)
        }
    }
}

enum ScreenType: String, Codable {
    case short
    case long
}

struct BreakTier: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var color: TierColor
    var activeInterval: TimeInterval  // seconds of active time before break
    var breakDuration: TimeInterval   // seconds the break lasts
    var screenType: ScreenType

    static let defaultShort = BreakTier(
        id: UUID(),
        name: "Stretch",
        color: .yellow,
        activeInterval: 20 * 60,   // 20 minutes
        breakDuration: 15,          // 15 seconds
        screenType: .short
    )

    static let defaultLong = BreakTier(
        id: UUID(),
        name: "Walk",
        color: .red,
        activeInterval: 60 * 60,   // 60 minutes
        breakDuration: 5 * 60,     // 5 minutes
        screenType: .long
    )
}
