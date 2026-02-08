import SwiftUI

struct BreakOverlayView: View {
    @State var appState: AppState

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.75)

            if let overlayState = appState.overlayState {
                VStack(spacing: 30) {
                    // Tier name
                    Text(overlayState.tier.name)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(overlayState.tier.color.color)

                    // Break content
                    if overlayState.tier.screenType == .short {
                        ShortBreakContentView()
                    } else {
                        LongBreakContentView()
                    }

                    // Timer countdown
                    Text(formatTime(overlayState.remainingBreakTime))
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    if overlayState.isGracePeriod {
                        Text("Finish your thought... break starts when you stop typing")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Action buttons
                    BreakActionsView(lockAfterBreak: overlayState.lockAfterBreak)
                }
                .frame(maxWidth: 600)
            }
        }
        .ignoresSafeArea()
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
