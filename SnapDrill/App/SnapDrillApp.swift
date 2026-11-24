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
    @State private var activeCloudKitMode: Bool
    @State private var isSwitchingContainer: Bool = false
    @State private var switchTask: Task<Void, Never>?
    @State private var containerInstanceID = UUID()

    init() {
        let env = AppEnvironment()
        let initialCloudKit = CloudKitContainerPolicy.launchCloudKitRequested(
            iCloudSyncEnabled: env.preferences.iCloudSyncEnabled,
            lastKnownProActive: env.preferences.lastKnownProActive
        )
        let initialResult = ModelContainerFactory.makeContainer(cloudKitRequested: initialCloudKit)
        env.storeSyncStatus = initialResult.syncStatus
        env.activeCloudKitEnabled = initialCloudKit
        _environment = State(initialValue: env)
        _storeResult = State(initialValue: initialResult)
        _activeCloudKitMode = State(initialValue: initialCloudKit)
    }

    private var desiredCloudKitActive: Bool {
        environment.preferences.iCloudSyncEnabled && environment.proStore.isPro
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isSwitchingContainer {
                    VStack(spacing: 14) {
                        ProgressView()
                            .tint(SnapDrillTheme.inkBlue)
                        Text("Updating iCloud sync...")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .paperBackground()
                } else if let modelContainer = storeResult.container {
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
                            scheduleContainerReload(cloudKitRequested: desiredCloudKitActive)
                        }
                    )
                }
            }
            .preferredColorScheme(
                launchArgs.forceDarkMode ? .dark : environment.preferences.appearanceMode.colorScheme
            )
            .onChange(of: desiredCloudKitActive) { _, _ in
                scheduleSafeContainerTransitionIfNeeded()
            }
            .onChange(of: environment.proStore.hasCompletedInitialRefresh) { _, done in
                guard done else { return }
                environment.preferences.lastKnownProActive = environment.proStore.isPro
                scheduleSafeContainerTransitionIfNeeded()
            }
            .onChange(of: environment.proStore.isPro) { _, newIsPro in
                if environment.proStore.hasCompletedInitialRefresh {
                    environment.preferences.lastKnownProActive = newIsPro
                }
                scheduleSafeContainerTransitionIfNeeded()
            }
            .onChange(of: environment.isCaptureFlowActive) { _, isActive in
                if !isActive {
                    scheduleSafeContainerTransitionIfNeeded()
                }
            }
        }
    }

    private func scheduleSafeContainerTransitionIfNeeded() {
        let shouldTransition = CloudKitContainerPolicy.shouldTransitionContainer(
            activeMode: activeCloudKitMode,
            desiredMode: desiredCloudKitActive,
            hasCompletedInitialRefresh: environment.proStore.hasCompletedInitialRefresh,
            isCaptureFlowActive: environment.isCaptureFlowActive
        )
        guard shouldTransition else { return }
        scheduleContainerReload(cloudKitRequested: desiredCloudKitActive)
    }

    private func scheduleContainerReload(cloudKitRequested: Bool) {
        switchTask?.cancel()
        environment.commitPendingDeletions()
        isSwitchingContainer = true
        // Release strong reference to previous ModelContainer before unmounting and re-opening SQLite URL
        storeResult = ContainerLoadResult(container: nil, syncStatus: storeResult.syncStatus, errorDescription: nil)

        switchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            let refreshed = ModelContainerFactory.makeContainer(cloudKitRequested: cloudKitRequested)
            activeCloudKitMode = cloudKitRequested
            environment.activeCloudKitEnabled = cloudKitRequested
            environment.storeSyncStatus = refreshed.syncStatus
            storeResult = refreshed
            containerInstanceID = UUID()
            isSwitchingContainer = false
        }
    }
}
