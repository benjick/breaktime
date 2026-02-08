import SwiftUI

struct ExceptionsSettingsView: View {
    @State var appState: AppState
    @State private var showAppPicker = false

    var body: some View {
        Form {
            Section("Automatic Exceptions") {
                Toggle("Microphone in use", isOn: Binding(
                    get: { appState.config.autoExceptionMicrophone },
                    set: { appState.config.autoExceptionMicrophone = $0; saveConfig() }
                ))
                Text("Defer breaks when microphone is active (e.g., during calls)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Screen sharing active", isOn: Binding(
                    get: { appState.config.autoExceptionScreenSharing },
                    set: { appState.config.autoExceptionScreenSharing = $0; saveConfig() }
                ))
                Text("Defer breaks when screen sharing is detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("App Exceptions") {
                if appState.config.exceptionRules.isEmpty {
                    Text("No app exceptions configured")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(appState.config.exceptionRules.enumerated()), id: \.element.id) { index, rule in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(rule.appName)
                                    .font(.body)
                                Text(rule.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Picker("", selection: Binding(
                                get: { appState.config.exceptionRules[index].triggerMode },
                                set: {
                                    appState.config.exceptionRules[index].triggerMode = $0
                                    saveConfig()
                                }
                            )) {
                                Text("Focused").tag(TriggerMode.focused)
                                Text("Opened").tag(TriggerMode.opened)
                            }
                            .frame(width: 120)

                            Button(action: {
                                appState.config.exceptionRules.remove(at: index)
                                saveConfig()
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                Button("Add App Exception...") {
                    pickApp()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func pickApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let bundle = Bundle(url: url)
            let bundleId = bundle?.bundleIdentifier ?? url.lastPathComponent
            let appName = url.deletingPathExtension().lastPathComponent

            Task { @MainActor in
                // Don't add duplicates
                guard !appState.config.exceptionRules.contains(where: { $0.bundleIdentifier == bundleId }) else {
                    return
                }

                let rule = ExceptionRule(
                    bundleIdentifier: bundleId,
                    appName: appName,
                    triggerMode: .opened
                )
                appState.config.exceptionRules.append(rule)
                saveConfig()
            }
        }
    }

    private func saveConfig() {
        ConfigManager.shared.save(appState.config)
        NotificationCenter.default.post(name: .configChanged, object: nil)
    }
}
