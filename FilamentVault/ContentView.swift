import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .inventory

    enum Tab: Hashable { case inventory, database, settings }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FilamentListView()
            }
            .tabItem {
                Label("Inventory", systemImage: "shippingbox.fill")
            }
            .tag(Tab.inventory)

            NavigationStack {
                DefaultsListView()
            }
            .tabItem {
                Label("Database", systemImage: "tray.full.fill")
            }
            .tag(Tab.database)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
