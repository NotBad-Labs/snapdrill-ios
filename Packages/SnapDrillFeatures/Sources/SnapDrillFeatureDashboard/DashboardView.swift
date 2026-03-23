//
//  DashboardView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首页仪表盘视图，展示复习进度概览和快捷入口。
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillFeatureLibrary

/// 首页仪表盘视图
///
/// 展示今日复习进度概览（待复习数、已复习数、题库总数）和快捷入口（开始复习、新建采集）。
public struct DashboardView: View {
    @Bindable private var router: DashboardRouter
    @Environment(\.repositories) private var repositories

    @State private var viewModel: DashboardViewModel?
    
    // MARK: - Layout Constants
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
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
                // 背景
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 1. Header Area
                            HeaderView()

                            if viewModel.totalCount == 0 {
                                // 空状态：引导用户采集第一道题
                                ContentUnavailableView {
                                    Label(L10n.Dashboard.emptyTitle, systemImage: "books.vertical")
                                } description: {
                                    Text(L10n.Dashboard.emptyDescription)
                                } actions: {
                                    Button(L10n.Dashboard.goCapture) {
                                        viewModel.checkDraftAndCapture(router: router)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.top, 40)
                            } else {
                                // 2. Hero Section (Review Status, Reactive)
                                ReviewHeroCard(
                                    totalCount: viewModel.totalCount,
                                    dueCount: viewModel.dueCount,
                                    reviewedTodayCount: viewModel.reviewedTodayCount,
                                    onStartReview: { router.navigateToReview() },
                                    onStartCapture: { viewModel.checkDraftAndCapture(router: router) }
                                )

                                // 3. Bento Grid Actions
                                LazyVGrid(columns: columns, spacing: 12) {
                                    BentoCard(
                                        title: L10n.Dashboard.smartScan,
                                        subtitle: L10n.Dashboard.addNew,
                                        icon: "camera.viewfinder",
                                        gradient: LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    ) {
                                        viewModel.checkDraftAndCapture(router: router)
                                    }

                                    // 题库卡片
                                    BentoCard(
                                        title: L10n.Dashboard.browseLibrary,
                                        subtitle: L10n.Dashboard.manageKnowledge,
                                        icon: "books.vertical.fill",
                                        gradient: LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    ) {
                                        NotificationCenter.default.post(name: .switchToLibraryTab, object: nil)
                                    }

                                    // Daily Insight (纯展示，暂无详情页)
                                    DailyStatsView(
                                        todayItemsCount: viewModel.todayItemsCount,
                                        reviewedTodayCount: viewModel.reviewedTodayCount,
                                        dueCount: viewModel.dueCount
                                    )

                                    // 设置/更多
                                    BentoCard(
                                        title: L10n.Dashboard.subjectManage,
                                        subtitle: L10n.Dashboard.customize,
                                        icon: "square.grid.2x2",
                                        gradient: LinearGradient(
                                            colors: [.gray.opacity(0.8), .gray],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    ) {
                                        viewModel.isShowingSubjectManager = true
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .onAppear {
                        viewModel.loadData()
                    }
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = DashboardViewModel(repositories: repositories)
                }
            }
            .onDisappear {
                viewModel?.cancelTasks()
            }
        }
        .alert(L10n.Dashboard.draftAlertTitle, isPresented: Binding(
            get: { viewModel?.isShowingDraftAlert ?? false },
            set: { viewModel?.isShowingDraftAlert = $0 }
        )) {
            Button(L10n.Dashboard.draftStartNew) {
                viewModel?.startNewCapture(router: router)
            }
            Button(L10n.Dashboard.draftRestore) {
                viewModel?.restoreDraft(router: router)
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        } message: {
            Text(L10n.Dashboard.draftAlertMessage)
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.isShowingSubjectManager ?? false },
            set: { viewModel?.isShowingSubjectManager = $0 }
        )) {
            // Sheet 场景需要 NavigationStack 宿主（SubjectManagerView 自身不再包含）
            NavigationStack {
                SubjectManagerView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L10n.Common.close) {
                                viewModel?.isShowingSubjectManager = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    DashboardView(router: DashboardRouter())
}

/// 多维今日统计卡片：今日新增 / 今日复习 / 待复习（纯展示，无跳转）
struct DailyStatsView: View {
    let todayItemsCount: Int
    let reviewedTodayCount: Int
    let dueCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundStyle(.white)
                Spacer()
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                StatRow(label: L10n.Dashboard.todayAdded, value: todayItemsCount, color: .white)
                StatRow(label: L10n.Dashboard.todayReviewed, value: reviewedTodayCount, color: .white.opacity(0.85))
                StatRow(label: L10n.Dashboard.dueReview, value: dueCount, color: .white.opacity(0.85))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// 统计行：标签 + 数值
private struct StatRow: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(color.opacity(0.8))
            Spacer()
            Text(L10n.Common.itemCountShort(value))
                .font(.caption.bold())
                .foregroundStyle(color)
        }
    }
}
