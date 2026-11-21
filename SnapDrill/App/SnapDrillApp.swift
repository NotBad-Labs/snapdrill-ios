import SwiftData
import SwiftUI

/// Primary application destinations.
enum SnapDrillTab: String, Hashable, Sendable {
    case home
    case review
    case settings
}

/// Optional launch flags supporting automated UI verification across routes and color schemes.
struct AppLaunchArguments: Sendable {
    let initialTab: SnapDrillTab
    let seedDemoIfEmpty: Bool
    let forceDarkMode: Bool
    let openFirstDetail: Bool
    let openFirstEraser: Bool
    let openPDFPreview: Bool
    let openPaywall: Bool
    let openReviewSession: Bool

    static func current(_ args: [String] = ProcessInfo.processInfo.arguments) -> AppLaunchArguments {
        var tab: SnapDrillTab = .home
        if let idx = args.firstIndex(of: "-ui-tab"), args.indices.contains(idx + 1),
           let parsed = SnapDrillTab(rawValue: args[idx + 1]) {
            tab = parsed
        }
        return AppLaunchArguments(
            initialTab: tab,
            seedDemoIfEmpty: args.contains("-ui-demo-seed"),
            forceDarkMode: args.contains("-ui-dark"),
            openFirstDetail: args.contains("-ui-open-first-detail"),
            openFirstEraser: args.contains("-ui-open-eraser"),
            openPDFPreview: args.contains("-ui-open-pdf"),
            openPaywall: args.contains("-ui-open-paywall"),
            openReviewSession: args.contains("-ui-open-review-session")
        )
    }
}

@main
struct SnapDrillApp: App {
    private let launchArgs = AppLaunchArguments.current()

    @State private var environment = AppEnvironment()

    private let modelContainer: ModelContainer?
    private let storeInitializationError: String?

    init() {
        let schema = Schema([
            Subject.self,
            MistakeItem.self,
            MistakeTag.self,
            CustomCause.self
        ])

        // Try local-first CloudKit configuration if user enabled iCloud Sync & Pro,
        // falling back gracefully to local store when unentitled (e.g. personal Simulator runs).
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [localConfig])
            self.storeInitializationError = nil
        } catch {
            self.modelContainer = nil
            self.storeInitializationError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let modelContainer {
                    RootTabView(launchArgs: launchArgs)
                        .environment(environment)
                        .modelContainer(modelContainer)
                } else {
                    DatabaseRecoveryView(
                        errorDescription: storeInitializationError ?? "Unknown SwiftData store error",
                        imageStore: environment.imageStore
                    )
                }
            }
            .preferredColorScheme(
                launchArgs.forceDarkMode ? .dark : environment.preferences.appearanceMode.colorScheme
            )
        }
    }
}
