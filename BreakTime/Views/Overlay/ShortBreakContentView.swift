import SwiftUI

struct ShortBreakContentView: View {
    private static let stretches = [
        ("Shake it out!", "Shake your hands like you're drying them off"),
        ("Finger stretch", "Interlace fingers, palms out, extend arms"),
        ("Wrist circles", "Slowly rotate your wrists in circles"),
        ("Fist and release", "Clench fists tightly, then spread fingers wide"),
        ("Prayer stretch", "Press palms together, slowly lower hands"),
    ]

    @State private var currentIndex = Int.random(in: 0..<stretches.count)

    var body: some View {
        VStack(spacing: 16) {
            Text(Self.stretches[currentIndex].0)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)

            Text(Self.stretches[currentIndex].1)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
    }
}
