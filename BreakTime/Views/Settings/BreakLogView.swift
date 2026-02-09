import SwiftUI

struct BreakLogView: View {
    @State private var entries: [BreakLogEntry] = []

    var body: some View {
        VStack(spacing: 0) {
            if entries.isEmpty {
                Text("No break events logged yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(entries.reversed()) {
                    TableColumn("Time") { entry in
                        Text(formatDate(entry.date))
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .width(min: 130, ideal: 140)

                    TableColumn("Tier") { entry in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(tierColor(entry.tierColor))
                                .frame(width: 8, height: 8)
                            Text(entry.tierName)
                        }
                    }
                    .width(min: 70, ideal: 80)

                    TableColumn("Event") { entry in
                        Text(eventLabel(entry.event))
                            .foregroundColor(eventColor(entry.event))
                    }
                    .width(min: 70, ideal: 80)

                    TableColumn("Reason") { entry in
                        Text(entry.reason ?? "—")
                            .foregroundColor(.secondary)
                    }
                    .width(min: 80, ideal: 120)
                }
                .font(.system(size: 12))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !entries.isEmpty {
                Button("Clear Log") {
                    BreakLogger.shared.clearAll()
                    entries = []
                }
                .padding(8)
            }
        }
        .onAppear {
            entries = BreakLogger.shared.loadEntries()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm:ss"
        return formatter.string(from: date)
    }

    private func eventLabel(_ event: BreakLogEvent) -> String {
        switch event {
        case .started: return "Started"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        case .postponed: return "Postponed"
        case .deferred: return "Deferred"
        }
    }

    private func eventColor(_ event: BreakLogEvent) -> Color {
        switch event {
        case .completed: return .green
        case .skipped: return .orange
        case .postponed: return .yellow
        case .deferred: return .secondary
        case .started: return .primary
        }
    }

    private func tierColor(_ colorName: String) -> Color {
        guard let tierColor = TierColor(rawValue: colorName) else { return .gray }
        return tierColor.color
    }
}
