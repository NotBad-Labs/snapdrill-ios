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
    public init(router: DashboardRouter) {
        self.router = router
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                // Background
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
                                    Label("还没有任何题目", systemImage: "books.vertical")
                                } description: {
                                    Text("拍摄一道错题，开始你的间隔复习之旅")
                                } actions: {
                                    Button("去采集") {
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
                                        title: "智能扫描",
                                        subtitle: "录入新题",
                                        icon: "camera.viewfinder",
                                        gradient: LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    ) {
                                        viewModel.checkDraftAndCapture(router: router)
                                    }

                                    // Library Card
                                    BentoCard(
                                        title: "题库浏览",
                                        subtitle: "管理知识",
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

                                    // Settings/More
                                    BentoCard(
                                        title: "科目管理",
                                        subtitle: "自定义",
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
        .alert("恢复未完成的题目？", isPresented: Binding(
            get: { viewModel?.isShowingDraftAlert ?? false },
            set: { viewModel?.isShowingDraftAlert = $0 }
        )) {
            Button("开始新的") {
                viewModel?.startNewCapture(router: router)
            }
            Button("恢复") {
                viewModel?.restoreDraft(router: router)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("您有上次未保存的拍摄内容，是否继续编辑？")
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.isShowingSubjectManager ?? false },
            set: { viewModel?.isShowingSubjectManager = $0 }
        )) {
            SubjectManagerView()
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
                StatRow(label: "今日新增", value: todayItemsCount, color: .white)
                StatRow(label: "今日复习", value: reviewedTodayCount, color: .white.opacity(0.85))
                StatRow(label: "待复习", value: dueCount, color: .white.opacity(0.85))
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
            Text("\(value) 题")
                .font(.caption.bold())
                .foregroundStyle(color)
        }
    }
}
