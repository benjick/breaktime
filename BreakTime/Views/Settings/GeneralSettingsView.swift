import SwiftUI

struct GeneralSettingsView: View {
    @State var appState: AppState
    @State private var slackTokenInput: String = ""
    @State private var slackTestResult: SlackTestResult?
    @State private var slackIsTesting = false

    private enum SlackTestResult {
        case success
        case error(String)
    }

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { LaunchAtLoginManager.shared.isEnabled },
                    set: { _ in
                        LaunchAtLoginManager.shared.toggle()
                    }
                ))
            }

            Section("Idle Detection") {
                HStack {
                    Text("Idle threshold")
                    Spacer()
                    Stepper(
                        "\(Int(appState.config.idleThreshold / 60)) min",
                        value: Binding(
                            get: { appState.config.idleThreshold / 60 },
                            set: { appState.config.idleThreshold = $0 * 60; saveConfig() }
                        ),
                        in: 1...30,
                        step: 1
                    )
                }

            }

            Section("Break Merging") {
                HStack {
                    Text("Merge window")
                    Spacer()
                    Stepper(
                        "\(Int(appState.config.mergeWindow / 60)) min",
                        value: Binding(
                            get: { appState.config.mergeWindow / 60 },
                            set: { appState.config.mergeWindow = $0 * 60; saveConfig() }
                        ),
                        in: 1...30,
                        step: 1
                    )
                }
                Text("Skip shorter breaks if a longer one is due within this window")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Break Warning") {
                HStack {
                    Text("Warning duration")
                    Spacer()
                    Stepper(
                        "\(Int(appState.config.warningDuration)) sec",
                        value: Binding(
                            get: { appState.config.warningDuration },
                            set: { appState.config.warningDuration = $0; saveConfig() }
                        ),
                        in: 5...60,
                        step: 5
                    )
                }
                Text("Colored border shown before break starts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Slack Status") {
                Text("Automatically set your Slack status during breaks and clear it when the break ends. Your existing status will not be overwritten.")
                    .foregroundStyle(.secondary)
                    .font(.callout)

                SecureField("Slack User Token (xoxp-...)", text: $slackTokenInput)
                    .onChange(of: slackTokenInput) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        appState.config.slackToken = trimmed.isEmpty ? nil : trimmed
                        saveConfig()
                        slackTestResult = nil
                    }

                HStack {
                    Button("Test Connection") {
                        testSlackConnection()
                    }
                    .disabled(slackTokenInput.isEmpty || slackIsTesting)

                    if slackIsTesting {
                        ProgressView()
                            .controlSize(.small)
                    }

                    if let result = slackTestResult {
                        switch result {
                        case .success:
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        case .error(let message):
                            Label(message, systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }

                DisclosureGroup("How to get a Slack token") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 0) {
                            Text("1. Go to ")
                            Link("api.slack.com/apps", destination: URL(string: "https://api.slack.com/apps")!)
                            Text(" → Create New App (From Scratch)")
                        }
                        Text("2. Under **OAuth & Permissions**, add User Token Scopes:")
                        Text("   `users.profile:read` and `users.profile:write`")
                            .font(.system(.callout, design: .monospaced))
                        Text("3. Click **Install to Workspace** and authorize")
                        Text("4. Copy the **User OAuth Token** (starts with xoxp-)")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                }
            }

            Section("Menu Bar Icon") {
                iconLegendRow(
                    icon: { Circle().fill(.blue).frame(width: 10, height: 10) },
                    label: "Next break approaching"
                )
                iconLegendRow(
                    icon: { Circle().strokeBorder(.blue, lineWidth: 1.5).frame(width: 10, height: 10) },
                    label: "Break deferred (exception active)"
                )
                iconLegendRow(
                    icon: {
                        Circle().fill(.blue).frame(width: 10, height: 10)
                            .opacity(0.6)
                    },
                    label: "Warning — break starting soon"
                )
                iconLegendRow(
                    icon: { Circle().fill(.gray).frame(width: 10, height: 10) },
                    label: "Idle"
                )
                iconLegendRow(
                    icon: { Text("⏸").font(.system(size: 10)) },
                    label: "Paused"
                )
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            slackTokenInput = appState.config.slackToken ?? ""
        }
    }

    private func iconLegendRow<Icon: View>(icon: () -> Icon, label: String) -> some View {
        HStack(spacing: 8) {
            icon()
                .frame(width: 16, alignment: .center)
            Text(label)
                .font(.callout)
        }
    }

    private func saveConfig() {
        ConfigManager.shared.save(appState.config)
        NotificationCenter.default.post(name: .configChanged, object: nil)
    }

    private func testSlackConnection() {
        guard !slackTokenInput.isEmpty else { return }
        slackIsTesting = true
        slackTestResult = nil
        let token = slackTokenInput

        Task.detached {
            do {
                _ = try await SlackAPI.getStatus(token: token)
                await MainActor.run {
                    slackTestResult = .success
                    slackIsTesting = false
                }
            } catch {
                await MainActor.run {
                    slackTestResult = .error(error.localizedDescription)
                    slackIsTesting = false
                }
            }
        }
    }
}
