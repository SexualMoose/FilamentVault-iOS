import SwiftUI
import SwiftData

@main
struct FilamentVaultApp: App {

    // SwiftData container — models are declared inline so Xcode auto-creates
    // the SQLite store on first launch. Schema migrations are version-safe.
    let container: ModelContainer = {
        let schema = Schema([
            Filament.self,
            DefaultSetting.self,
            DefaultOverride.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Seed the built-in filament defaults catalog on first launch
                    // (and refresh it when the asset count changes in new builds)
                    Task {
                        await DefaultsPopulator.seedIfNeeded(context: container.mainContext)
                    }
                }
        }
        .modelContainer(container)
    }
}
