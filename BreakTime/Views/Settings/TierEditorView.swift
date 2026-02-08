import SwiftUI

struct TierEditorView: View {
    @Binding var tier: BreakTier

    var body: some View {
        Form {
            Section("Basic") {
                TextField("Name", text: $tier.name)

                Picker("Color", selection: $tier.color) {
                    ForEach(TierColor.allCases, id: \.self) { color in
                        HStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 12, height: 12)
                            Text(color.rawValue.capitalized)
                        }
                        .tag(color)
                    }
                }
            }

            Section("Timing") {
                HStack {
                    Text("Active interval")
                    Spacer()
                    Stepper(
                        "\(Int(tier.activeInterval / 60)) min",
                        value: Binding(
                            get: { tier.activeInterval / 60 },
                            set: { tier.activeInterval = $0 * 60 }
                        ),
                        in: 1...480,
                        step: 5
                    )
                }

                HStack {
                    Text("Break duration")
                    Spacer()
                    if tier.breakDuration >= 60 {
                        Stepper(
                            "\(Int(tier.breakDuration / 60)) min",
                            value: Binding(
                                get: { tier.breakDuration / 60 },
                                set: { tier.breakDuration = $0 * 60 }
                            ),
                            in: 1...60,
                            step: 1
                        )
                    } else {
                        Stepper(
                            "\(Int(tier.breakDuration)) sec",
                            value: $tier.breakDuration,
                            in: 5...55,
                            step: 5
                        )
                    }
                }

                // Toggle between seconds and minutes
                Picker("Duration unit", selection: Binding(
                    get: { tier.breakDuration >= 60 },
                    set: { isMinutes in
                        if isMinutes && tier.breakDuration < 60 {
                            tier.breakDuration = 60
                        } else if !isMinutes && tier.breakDuration >= 60 {
                            tier.breakDuration = 30
                        }
                    }
                )) {
                    Text("Seconds").tag(false)
                    Text("Minutes").tag(true)
                }
                .pickerStyle(.segmented)
            }

            Section("Break Screen") {
                Picker("Screen type", selection: $tier.screenType) {
                    Text("Short (stretch prompts)").tag(ScreenType.short)
                    Text("Long (lifestyle nudges)").tag(ScreenType.long)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
