import Foundation

struct SlackStatus {
    let statusText: String
    let statusEmoji: String

    var isEmpty: Bool { statusText.isEmpty && statusEmoji.isEmpty }
}

enum SlackAPI {
    private static let baseURL = "https://slack.com/api/"

    static func getStatus(token: String) async throws -> SlackStatus {
        var request = URLRequest(url: URL(string: baseURL + "users.profile.get")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard json["ok"] as? Bool == true else {
            let error = json["error"] as? String ?? "unknown"
            throw SlackError.apiError(error)
        }

        let profile = json["profile"] as? [String: Any] ?? [:]
        return SlackStatus(
            statusText: profile["status_text"] as? String ?? "",
            statusEmoji: profile["status_emoji"] as? String ?? ""
        )
    }

    static func setStatus(token: String, text: String, emoji: String, expiration: Int) async throws {
        var request = URLRequest(url: URL(string: baseURL + "users.profile.set")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "profile": [
                "status_text": text,
                "status_emoji": emoji,
                "status_expiration": expiration
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard json["ok"] as? Bool == true else {
            let error = json["error"] as? String ?? "unknown"
            throw SlackError.apiError(error)
        }
    }

    static func clearStatus(token: String) async throws {
        try await setStatus(token: token, text: "", emoji: "", expiration: 0)
    }
}

enum SlackError: LocalizedError {
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let message): return "Slack API error: \(message)"
        }
    }
}
