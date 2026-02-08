import SwiftUI

struct LongBreakContentView: View {
    private static let nudges = [
        "Take a short walk",
        "Grab some water",
        "Look out a window",
        "Do some light stretching",
        "Rest your eyes — look at something far away",
    ]

    @State private var currentIndex = Int.random(in: 0..<nudges.count)

    var body: some View {
        Text(Self.nudges[currentIndex])
            .font(.system(size: 32, weight: .semibold))
            .foregroundColor(.white)
            .padding()
    }
}
