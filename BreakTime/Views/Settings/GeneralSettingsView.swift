import SwiftUI

struct GeneralSettingsView: View {
    @State var appState: AppState

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
        }
        .formStyle(.grouped)
        .padding()
    }

    private func saveConfig() {
        ConfigManager.shared.save(appState.config)
        NotificationCenter.default.post(name: .configChanged, object: nil)
    }
}
