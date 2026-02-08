import SwiftUI

struct SettingsView: View {
    @State var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            BreakTiersSettingsView(appState: appState)
                .tabItem {
                    Label("Break Tiers", systemImage: "timer")
                }

            ExceptionsSettingsView(appState: appState)
                .tabItem {
                    Label("Exceptions", systemImage: "hand.raised")
                }

            BreakLogView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet.rectangle")
                }
        }
        .frame(minWidth: 550, minHeight: 400)
    }
}
