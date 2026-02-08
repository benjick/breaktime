import SwiftUI

struct BreakTiersSettingsView: View {
    @State var appState: AppState
    @State private var selectedTierId: UUID?
    @State private var showDeleteConfirmation = false

    var body: some View {
        HSplitView {
            // Left: tier list
            VStack(alignment: .leading, spacing: 0) {
                List(appState.config.tiers, selection: $selectedTierId) { tier in
                    HStack {
                        Circle()
                            .fill(tier.color.color)
                            .frame(width: 10, height: 10)
                        Text(tier.name)
                        Spacer()
                        Text(formatDuration(tier.activeInterval))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .tag(tier.id)
                }
                .listStyle(.sidebar)

                HStack {
                    Button(action: addTier) {
                        Image(systemName: "plus")
                    }
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedTierId == nil)
                }
                .padding(8)
            }
            .frame(minWidth: 180, maxWidth: 220)

            // Right: tier editor
            if let selectedId = selectedTierId,
               let tierIndex = appState.config.tiers.firstIndex(where: { $0.id == selectedId }) {
                TierEditorView(
                    tier: Binding(
                        get: { appState.config.tiers[tierIndex] },
                        set: {
                            appState.config.tiers[tierIndex] = $0
                            saveConfig()
                        }
                    )
                )
                .id(selectedId)
            } else {
                Text("Select a break tier to edit")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert("Delete Tier", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteTier()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this break tier?")
        }
        .onAppear {
            if selectedTierId == nil {
                selectedTierId = appState.config.tiers.first?.id
            }
        }
    }

    private func addTier() {
        let newTier = BreakTier(
            id: UUID(),
            name: "New Break",
            color: .blue,
            activeInterval: 30 * 60,
            breakDuration: 30,
            screenType: .short
        )
        appState.config.tiers.append(newTier)
        appState.initializeCounters()
        selectedTierId = newTier.id
        saveConfig()
    }

    private func deleteTier() {
        guard let id = selectedTierId else { return }
        appState.config.tiers.removeAll { $0.id == id }
        appState.initializeCounters()
        selectedTierId = appState.config.tiers.first?.id
        saveConfig()
    }

    private func saveConfig() {
        ConfigManager.shared.save(appState.config)
        NotificationCenter.default.post(name: .configChanged, object: nil)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}
