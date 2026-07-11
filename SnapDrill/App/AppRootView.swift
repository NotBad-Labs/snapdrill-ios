//
//  AppRootView.swift
//  SnapDrill
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  应用根视图，组合导航和各个 Feature 模块。
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit
import SnapDrillCore
import SnapDrillData
import SnapDrillFeatureCapture
import SnapDrillFeatureLibrary
import SnapDrillFeatureReview
import SnapDrillFeatureDashboard
import SnapDrillFeatureSettings

/// 应用根视图 (Composition Root UI)
///
/// 这里是所有 Feature 模块的物理聚合点。
/// 它负责将 Router 状态绑定到具体的视图结构上。
struct AppRootView: View {
    
    // MARK: - Properties

    @Bindable var router: AppRouter
    let makeLibrarySession: () async -> LibrarySession
    @Environment(\.services) private var services
    @State private var librarySession: LibrarySession?
    @State private var handledStoreRecoveryEventKey: String?

    var body: some View {
        Group {
            if let librarySession {
                loadedContent(librarySession: librarySession)
                    .modelContainer(librarySession.container)
                    .environment(\.repositories, librarySession.repositories)
            } else {
                ProgressView()
                    .task {
                        await loadLibrarySessionIfNeeded()
                    }
            }
        }
    }

    @ViewBuilder
    private func loadedContent(librarySession: LibrarySession) -> some View {
        ZStack(alignment: .top) {
            // Tab struct（iOS 18+）：自动获得 Liquid Glass 效果
            // iPad 上自动切换为侧边栏导航
            TabView(selection: $router.selectedTab) {
                Tab(L10n.Dashboard.title, systemImage: "house", value: AppTab.dashboard) {
                    DashboardView(router: router.dashboardRouter)
                }

                Tab(L10n.Library.title, systemImage: "books.vertical", value: AppTab.library) {
                    LibraryView(router: router.libraryRouter)
                }

                Tab(L10n.Capture.title, systemImage: "camera", value: AppTab.capture) {
                    CaptureView(router: router.captureRouter)
                }

                Tab(L10n.Review.title, systemImage: "clock.arrow.circlepath", value: AppTab.review) {
                    ReviewView(router: router.reviewRouter)
                }

                Tab(L10n.Settings.title, systemImage: "gear", value: AppTab.settings) {
                    SettingsView(router: router.settingsRouter)
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            // AGENTS.md 异步准则：用 async notification stream 替代 Combine .onReceive
            .task {
                for await _ in NotificationCenter.default.notifications(named: .switchToCaptureTab) {
                    withAnimation(.spring(duration: 0.4)) { router.selectedTab = .capture }
                }
            }
            .task {
                for await _ in NotificationCenter.default.notifications(named: .switchToLibraryTab) {
                    withAnimation(.spring(duration: 0.4)) { router.selectedTab = .library }
                }
            }
            .task {
                for await _ in NotificationCenter.default.notifications(named: .switchToSettingsTab) {
                    withAnimation(.spring(duration: 0.4)) { router.selectedTab = .settings }
                }
            }
            
            // 降级模式警告横幅
            if shouldShowDegradedModeWarning(for: librarySession) {
                degradedModeWarningBanner
                    .accessibilityIdentifier("app.degradedBanner")
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: storeRecoveryPresentationBinding(for: librarySession)) {
            if let event = activeStoreRecoveryEvent(for: librarySession) {
                StoreRecoveryBlockingView(
                    event: event,
                    repositories: librarySession.repositories,
                    activityTracker: services.activityTracker,
                    onResolved: { markStoreRecoveryHandled(event) }
                )
                .interactiveDismissDisabled(true)
            }
        }
    }
    
    // MARK: - Private Helpers

    private func shouldShowDegradedModeWarning(for librarySession: LibrarySession) -> Bool {
        if librarySession.isUsingInMemoryFallback {
            return true
        }

#if DEBUG
        return ProcessInfo.processInfo.arguments.contains("--ui-test-force-degraded-banner")
#else
        return false
#endif
    }

    private func storeRecoveryPresentationBinding(for librarySession: LibrarySession) -> Binding<Bool> {
        Binding(
            get: {
                guard let event = activeStoreRecoveryEvent(for: librarySession) else {
                    return false
                }
                return handledStoreRecoveryEventKey != storeRecoveryEventKey(event)
            },
            set: { isPresented in
                guard !isPresented, let event = activeStoreRecoveryEvent(for: librarySession) else {
                    return
                }
                markStoreRecoveryHandled(event)
            }
        )
    }

    private func activeStoreRecoveryEvent(for librarySession: LibrarySession) -> StoreRecoveryEvent? {
        if let event = librarySession.storeRecoveryEvent {
            return event
        }

#if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("--ui-test-force-store-recovery") else {
            return nil
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("snapdrill-ui-test-store-recovery", isDirectory: true)
        return StoreRecoveryEvent(
            storeURL: directory.appendingPathComponent("default.store"),
            isolationDirectoryURL: directory.appendingPathComponent("corrupted/2026-07-03T00-00-00Z", isDirectory: true),
            originalErrorDescription: "UI test injected store open failure",
            retryErrorDescription: "UI test injected retry failure"
        )
#else
        return nil
#endif
    }

    private func storeRecoveryEventKey(_ event: StoreRecoveryEvent) -> String {
        event.isolationDirectoryURL.path
    }

    private func markStoreRecoveryHandled(_ event: StoreRecoveryEvent) {
        handledStoreRecoveryEventKey = storeRecoveryEventKey(event)
    }
    
    /// 降级模式警告横幅
    @ViewBuilder
    private var degradedModeWarningBanner: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.AppRoot.degradedModeTitle)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(L10n.AppRoot.degradedModeDescription)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }

    private func loadLibrarySessionIfNeeded() async {
        guard librarySession == nil else { return }
        librarySession = await makeLibrarySession()
    }
}

@MainActor
private struct StoreRecoveryBlockingView: View {
    let event: StoreRecoveryEvent
    let onResolved: () -> Void
    @State private var viewModel: SettingsViewModel
    @State private var showingBackupImporter = false
    @State private var restoreErrorMessage: String?

    init(
        event: StoreRecoveryEvent,
        repositories: RepositoryContainer,
        activityTracker: AppActivityTracker,
        onResolved: @escaping () -> Void
    ) {
        self.event = event
        self.onResolved = onResolved
        _viewModel = State(
            initialValue: SettingsViewModel(
                repositories: repositories,
                activityTracker: activityTracker
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    explanation

                    if let restoreErrorMessage {
                        errorMessage(restoreErrorMessage)
                    }

                    actions
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(.background)
            .navigationTitle(L10n.AppRoot.storeRecoveryNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .accessibilityIdentifier("app.storeRecovery.root")
        .fileImporter(
            isPresented: $showingBackupImporter,
            allowedContentTypes: [.zip]
        ) { result in
            handleBackupSelection(result)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.orange)
                .accessibilityLabel(L10n.AppRoot.storeRecoveryIconLabel)

            Text(L10n.AppRoot.storeRecoveryTitle)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            Text(L10n.AppRoot.storeRecoveryDescriptionPrimary)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(L10n.AppRoot.storeRecoveryDescriptionSecondary)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.AppRoot.storeRecoveryBackupCopyTitle, systemImage: "archivebox")
                .font(.headline)

            Text(L10n.AppRoot.storeRecoveryBackupCopyDescription)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                UIPasteboard.general.string = event.isolationDirectoryURL.path
            } label: {
                Label(L10n.AppRoot.storeRecoveryCopyPath, systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.primary)
            .accessibilityIdentifier("app.storeRecovery.copyIsolationPath")
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                restoreErrorMessage = nil
                showingBackupImporter = true
            } label: {
                Label(L10n.AppRoot.storeRecoveryRestoreBackup, systemImage: "arrow.clockwise.circle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(Color(UIColor.systemBackground))
                    .background(Color(UIColor.label), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBackupInProgress)
            .accessibilityIdentifier("app.storeRecovery.restoreBackup")

            Button {
                onResolved()
            } label: {
                Text(L10n.AppRoot.storeRecoveryContinueEmpty)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.primary)
                    .background(Color(UIColor.systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(UIColor.label), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isBackupInProgress)
            .accessibilityIdentifier("app.storeRecovery.continueEmpty")

            if viewModel.isBackupInProgress {
                ProgressView(value: viewModel.backupProgress)
                    .accessibilityIdentifier("app.storeRecovery.progress")
            }
        }
    }

    private func errorMessage(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.subheadline)
            .foregroundStyle(.red)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("app.storeRecovery.error")
    }

    private func handleBackupSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            restoreErrorMessage = nil
            Task {
                await viewModel.restoreFromBackup(fileURL: url)
                if let backupError = viewModel.backupError {
                    restoreErrorMessage = backupError
                } else {
                    onResolved()
                }
            }
        case .failure(let error):
            restoreErrorMessage = error.localizedDescription
        }
    }
}
