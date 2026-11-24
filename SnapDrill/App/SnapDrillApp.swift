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

    @State private var environment: AppEnvironment
    @State private var storeResult: ContainerLoadResult
    @State private var containerInstanceID = UUID()

    init() {
        let env = AppEnvironment()
        let wantsCloudKit = env.preferences.shouldEnableCloudKit(isPro: env.proStore.isPro || env.preferences.lastKnownProActive)
        let initialResult = ModelContainerFactory.makeContainer(cloudKitRequested: wantsCloudKit)
        env.storeSyncStatus = initialResult.syncStatus
        _environment = State(initialValue: env)
        _storeResult = State(initialValue: initialResult)
    }

    private var desiredCloudKitActive: Bool {
        environment.preferences.iCloudSyncEnabled && environment.proStore.isPro
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let modelContainer = storeResult.container {
                    RootTabView(launchArgs: launchArgs)
                        .id(containerInstanceID)
                        .environment(environment)
                        .modelContainer(modelContainer)
                } else {
                    DatabaseRecoveryView(
                        errorDescription: storeResult.errorDescription ?? String(localized: "Unknown SwiftData store error"),
                        storeURL: ModelContainerFactory.defaultStoreURL(),
                        imageStore: environment.imageStore,
                        onRebuildLibrary: {
                            reloadContainer(cloudKitRequested: desiredCloudKitActive)
                        }
                    )
                }
            }
            .preferredColorScheme(
                launchArgs.forceDarkMode ? .dark : environment.preferences.appearanceMode.colorScheme
            )
            .onChange(of: desiredCloudKitActive) { _, newValue in
                environment.preferences.lastKnownProActive = environment.proStore.isPro
                reloadContainer(cloudKitRequested: newValue)
            }
            .onChange(of: environment.proStore.isPro) { _, newIsPro in
                environment.preferences.lastKnownProActive = newIsPro
            }
        }
    }

    private func reloadContainer(cloudKitRequested: Bool) {
        let refreshed = ModelContainerFactory.makeContainer(cloudKitRequested: cloudKitRequested)
        environment.storeSyncStatus = refreshed.syncStatus
        storeResult = refreshed
        containerInstanceID = UUID()
    }
}
