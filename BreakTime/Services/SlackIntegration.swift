import Foundation

@MainActor
class SlackIntegration {
    private var token: String?
    private var didSetStatus = false
    private var breakIsActive = false

    func updateToken(_ token: String?) {
        self.token = (token?.isEmpty == true) ? nil : token
    }

    func breakStarted(breakDuration: TimeInterval) {
        guard let token = token else { return }
        breakIsActive = true
        didSetStatus = false

        let statusText = formatStatusText(breakDuration: breakDuration)
        let expiration = Int(Date().timeIntervalSince1970) + Int(breakDuration) + 60

        Task.detached {
            do {
                let current = try await SlackAPI.getStatus(token: token)
                guard current.isEmpty else {
                    // User has an existing status — don't overwrite
                    return
                }
                try await SlackAPI.setStatus(
                    token: token,
                    text: statusText,
                    emoji: ":coffee:",
                    expiration: expiration
                )
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.didSetStatus = true
                    // If break ended while we were in-flight, clear immediately
                    if !self.breakIsActive {
                        Task.detached {
                            try? await SlackAPI.clearStatus(token: token)
                        }
                    }
                }
            } catch {
                // Network/API error — silently ignore
            }
        }
    }

    func breakEnded() {
        breakIsActive = false
        guard didSetStatus, let token = token else { return }
        didSetStatus = false

        Task.detached {
            try? await SlackAPI.clearStatus(token: token)
        }
    }

    private func formatStatusText(breakDuration: TimeInterval) -> String {
        let minutes = Int(breakDuration) / 60
        if minutes > 0 {
            return "BreakTime: \(minutes) min"
        } else {
            return "BreakTime: \(Int(breakDuration)) sec"
        }
    }
}
