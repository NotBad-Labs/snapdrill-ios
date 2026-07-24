//
//  DashboardView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首页仪表盘视图，展示资料概览和快捷入口。
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillFeatureLibrary

/// 首页仪表盘视图。
///
/// 展示今日回顾概览、资料库总量和快捷入口。
public struct DashboardView: View {
    @Bindable private var router: DashboardRouter
    @Environment(\.repositories) private var repositories
    @Environment(\.services) private var services

    @State private var viewModel: DashboardViewModel?
    @State private var analyticsViewModel: DashboardAnalyticsViewModel?
    
    // MARK: - Layout Constants

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }
    /// 创建仪表盘视图
    /// - Parameter router: 注入的路由器
    public init(router: DashboardRouter) {
        self.router = router
    }
    
    // MARK: - Body
    
    /// 首页仪表盘的视图层次
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let viewModel = viewModel {
                    ScrollView {
                        if exposesOptionalSurfacesForUITesting {
                            legacyContent(viewModel: viewModel)
                        } else {
                            releaseOneContent(viewModel: viewModel)
                        }
                    }
                    .onAppear {
                        viewModel.loadData()
                    }
                } else {
                    DashboardLoadingView(
                        exposesOptionalSurfacesForUITesting: exposesOptionalSurfacesForUITesting
                    )
                }
            }
            .accessibilityIdentifier("dashboard.root")
            .onAppear {
                if viewModel == nil {
                    viewModel = DashboardViewModel(
                        repositories: repositories,
                        draftService: services.captureDraft,
                        deletionScheduler: services.deletionScheduler
                    )
                }
                if exposesOptionalSurfacesForUITesting, analyticsViewModel == nil {
                    let vm = DashboardAnalyticsViewModel(
                        repositories: repositories,
                        proEntitlementProvider: services.proEntitlement
                    )
                    analyticsViewModel = vm
                    vm.loadAnalytics()
                }
            }
            .onDisappear {
                viewModel?.cancelTasks()
                analyticsViewModel?.cancelTasks()
            }
            .overlay(alignment: .top) {
                Color(UIColor.systemGroupedBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 0)
                    .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea(edges: .top))
                    .allowsHitTesting(false)
            }
        }
        .alert(L10n.Dashboard.draftAlertTitle, isPresented: Binding(
            get: { viewModel?.isShowingDraftAlert ?? false },
            set: { viewModel?.isShowingDraftAlert = $0 }
        )) {
            Button(L10n.Dashboard.draftStartNew) {
                Task { await viewModel?.startNewCapture(router: router) }
            }
            Button(L10n.Dashboard.draftRestore) {
                viewModel?.restoreDraft(router: router)
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        } message: {
            Text(viewModel?.draftAlertMessage ?? L10n.Dashboard.draftAlertMessage)
        }
        .alert(L10n.Capture.draftUnrecoverableTitle, isPresented: Binding(
            get: { viewModel?.isShowingUnrecoverableDraftAlert ?? false },
            set: { viewModel?.isShowingUnrecoverableDraftAlert = $0 }
        )) {
            if viewModel?.pendingDraftFailure?.discardToken != nil {
                Button(L10n.Dashboard.draftStartNew, role: .destructive) {
                    Task { await viewModel?.startNewCapture(router: router) }
                }
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        } message: {
            Text(L10n.Capture.draftUnrecoverableMessage)
        }
        .alert(L10n.Common.error, isPresented: Binding(
            get: { viewModel?.isShowingDraftVerificationError ?? false },
            set: { viewModel?.isShowingDraftVerificationError = $0 }
        )) {
            Button(L10n.Common.retry) {
                Task { await viewModel?.checkDraftAndCapture(router: router) }
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        } message: {
            Text(L10n.Capture.draftVerificationFailed)
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.isShowingCategoryManager ?? false },
            set: { viewModel?.isShowingCategoryManager = $0 }
        )) {
            // Sheet 场景需要 NavigationStack 宿主（CategoryManagerView 自身不再包含）。
            // L3：分类管理已并入统一维度管理。
            NavigationStack {
                CategoryManagerView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L10n.Common.close) {
                                viewModel?.isShowingCategoryManager = false
                            }
                        }
                    }
            }
        }
    }

    private var exposesOptionalSurfacesForUITesting: Bool {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--uitesting")
            && arguments.contains("--ui-test-optional-surface")
            && !arguments.contains("--ui-test-core-surface")
#else
        return false
#endif
    }

    private func releaseOneContent(viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(L10n.Dashboard.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("dashboard.releaseOne.title")
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 12) {
                BentoCard(
                    title: L10n.Dashboard.smartScan,
                    subtitle: L10n.Dashboard.addNew,
                    icon: "camera.viewfinder",
                    gradient: DashboardTone.capture
                ) {
                    Task { await viewModel.checkDraftAndCapture(router: router) }
                }
                .accessibilityIdentifier("dashboard.bento.capture")

                BentoCard(
                    title: L10n.Dashboard.browseLibrary,
                    subtitle: L10n.Dashboard.manageKnowledge,
                    icon: "books.vertical.fill",
                    gradient: DashboardTone.library
                ) {
                    NotificationCenter.default.post(name: .switchToLibraryTab, object: nil)
                }
                .accessibilityIdentifier("dashboard.bento.library")
            }
            .padding(.horizontal)

            if viewModel.totalCount == 0 {
                AccessibleEmptyState(
                    title: L10n.Dashboard.emptyTitle,
                    message: L10n.Dashboard.emptyDescription,
                    systemImage: "tray"
                )
                .accessibilityIdentifier("dashboard.empty")
            } else {
                Label(L10n.Common.itemCount(viewModel.totalCount), systemImage: "archivebox.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                    .accessibilityIdentifier("dashboard.librarySummary")
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 40)
    }

    private func legacyContent(viewModel: DashboardViewModel) -> some View {
        VStack(spacing: 20) {
            HeaderView()

            if viewModel.totalCount == 0 {
                AccessibleEmptyState(
                    title: L10n.Dashboard.emptyTitle,
                    message: L10n.Dashboard.emptyDescription,
                    systemImage: "tray",
                    actionTitle: L10n.Dashboard.goCapture,
                    actionSystemImage: "camera.viewfinder"
                ) {
                    Task { await viewModel.checkDraftAndCapture(router: router) }
                }
                .accessibilityIdentifier("dashboard.empty.capture")
                .padding(.top, 40)
            } else {
                ReviewHeroCard(
                    totalCount: viewModel.totalCount,
                    dueCount: viewModel.dueCount,
                    reviewedTodayCount: viewModel.reviewedTodayCount,
                    onStartReview: { router.navigateToReview() },
                    onStartCapture: {
                        Task { await viewModel.checkDraftAndCapture(router: router) }
                    }
                )

                legacyShortcutGrid(viewModel: viewModel)

                if let analyticsVM = analyticsViewModel {
                    DashboardAnalyticsView(viewModel: analyticsVM)
                }
            }
        }
        .padding(.bottom, 40)
    }

    private func legacyShortcutGrid(viewModel: DashboardViewModel) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            BentoCard(
                title: L10n.Dashboard.smartScan,
                subtitle: L10n.Dashboard.addNew,
                icon: "camera.viewfinder",
                gradient: DashboardTone.capture
            ) {
                Task { await viewModel.checkDraftAndCapture(router: router) }
            }
            .accessibilityIdentifier("dashboard.bento.capture")

            BentoCard(
                title: L10n.Dashboard.browseLibrary,
                subtitle: L10n.Dashboard.manageKnowledge,
                icon: "books.vertical.fill",
                gradient: DashboardTone.library
            ) {
                NotificationCenter.default.post(name: .switchToLibraryTab, object: nil)
            }
            .accessibilityIdentifier("dashboard.bento.library")

            DailyStatsView(
                todayItemsCount: viewModel.todayItemsCount,
                reviewedTodayCount: viewModel.reviewedTodayCount,
                dueCount: viewModel.dueCount
            )
            .accessibilityIdentifier("dashboard.dailyStats")

            BentoCard(
                title: L10n.Library.categoryManager,
                subtitle: L10n.Dashboard.customize,
                icon: "square.grid.2x2",
                gradient: DashboardTone.categories
            ) {
                viewModel.isShowingCategoryManager = true
            }
            .accessibilityIdentifier("dashboard.bento.categories")
        }
        .padding(.horizontal)
    }
}

#if DEBUG
#Preview {
    DashboardView(router: DashboardRouter())
        .environment(\.services, MockServiceContainer())
}
#endif

private enum DashboardTone {
    static let capture = LinearGradient(
        colors: [Color.blue.opacity(0.82), Color.cyan.opacity(0.58)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let library = LinearGradient(
        colors: [Color.indigo.opacity(0.72), Color.blue.opacity(0.58)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let categories = LinearGradient(
        colors: [Color.gray.opacity(0.68), Color.blue.opacity(0.36)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Dashboard 数据加载中的稳定占位，避免首页启动时只出现孤立 spinner。
private struct DashboardLoadingView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let exposesOptionalSurfacesForUITesting: Bool

    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if exposesOptionalSurfacesForUITesting {
                    HeaderView()
                        .redacted(reason: .placeholder)
                } else {
                    Text(L10n.Dashboard.title)
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .redacted(reason: .placeholder)
                }

                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(height: 172)
                    .overlay {
                        ProgressView(L10n.Common.loading)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<(exposesOptionalSurfacesForUITesting ? 4 : 2), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .frame(height: 120)
                    }
                }
                .padding(.horizontal)
                .redacted(reason: .placeholder)
            }
            .padding(.bottom, 40)
        }
    }
}

/// 多维今日统计卡片：今日新增 / 今日回顾 / 待回顾（纯展示，无跳转）。
struct DailyStatsView: View {
    let todayItemsCount: Int
    let reviewedTodayCount: Int
    let dueCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                Spacer()
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                StatRow(label: L10n.Dashboard.todayAdded, value: todayItemsCount)
                StatRow(label: L10n.Dashboard.todayReviewed, value: reviewedTodayCount)
                StatRow(label: L10n.Dashboard.dueReview, value: dueCount)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .accessibleGroup(label: L10n.Accessibility.dailyStatsLabel(added: todayItemsCount, reviewed: reviewedTodayCount, due: dueCount))
    }
}

/// 统计行：标签 + 数值。
private struct StatRow: View {
    let label: String
    let value: Int

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(L10n.Common.itemCountShort(value))
                .font(.caption.bold())
                .foregroundStyle(.primary)
        }
    }
}
