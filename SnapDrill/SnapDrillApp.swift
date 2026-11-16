import SwiftData
import SwiftUI

@main
struct SnapDrillApp: App {
    @State private var bootstrap = AppBootstrap()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(SnapDrillTheme.inkBlue)
                .task {
                    await bootstrap.seedIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subject.self,
            MistakeItem.self,
            MistakeTag.self,
            CaptureDraft.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }()
}