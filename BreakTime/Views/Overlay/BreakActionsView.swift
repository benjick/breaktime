import SwiftUI

struct BreakActionsView: View {
    let lockAfterBreak: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                Button("Skip") {
                    NotificationCenter.default.post(name: .breakSkipped, object: nil)
                }
                .buttonStyle(BreakButtonStyle())

                Button("Postpone 1 min") {
                    NotificationCenter.default.post(name: .breakPostponed, object: nil, userInfo: ["minutes": 1])
                }
                .buttonStyle(BreakButtonStyle())

                Button("Postpone 5 min") {
                    NotificationCenter.default.post(name: .breakPostponed, object: nil, userInfo: ["minutes": 5])
                }
                .buttonStyle(BreakButtonStyle())

                Button("Postpone 10 min") {
                    NotificationCenter.default.post(name: .breakPostponed, object: nil, userInfo: ["minutes": 10])
                }
                .buttonStyle(BreakButtonStyle())
            }

            Button {
                if !lockAfterBreak {
                    NotificationCenter.default.post(name: .lockAfterBreakToggled, object: nil)
                }
            } label: {
                HStack {
                    Image(systemName: lockAfterBreak ? "checkmark.circle.fill" : "lock")
                    Text(lockAfterBreak ? "Will lock after break" : "Lock after break")
                }
            }
            .buttonStyle(BreakButtonStyle(isToggled: lockAfterBreak))
            .disabled(lockAfterBreak)
        }
    }
}

struct BreakButtonStyle: ButtonStyle {
    var isToggled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToggled ? Color.green.opacity(0.3) : Color.white.opacity(configuration.isPressed ? 0.2 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}
