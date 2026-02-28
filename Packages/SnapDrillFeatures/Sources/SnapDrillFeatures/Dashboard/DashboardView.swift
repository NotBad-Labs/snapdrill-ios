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

public struct DashboardView: View {
    @Bindable private var router: DashboardRouter
    @Environment(\.useCases) private var useCases
    
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
                            
                            // 2. Hero Section (Review Status, Reactive)
                            ReviewHeroCard(
                                totalCount: viewModel.totalCount,
                                dueCount: viewModel.dueCount,
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
                                    NotificationCenter.default.post(name: NSNotification.Name("SwitchToLibraryTab"), object: nil)
                                }
                                
                                // Daily Insight (Real Data, Reactive)
                                DailyStatsView(count: viewModel.todayItemsCount)
                                
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
                                    viewModel.showingSubjectManager = true
                                }
                            }
                            .padding(.horizontal)
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
                    viewModel = DashboardViewModel(
                        reviewUseCase: useCases.review,
                        taxonomyUseCase: useCases.taxonomy
                    )
                }
            }
        }
        .alert("敬请期待", isPresented: Binding(
            get: { viewModel?.showingComingSoon ?? false },
            set: { viewModel?.showingComingSoon = $0 }
        )) {
            Button("好", role: .cancel) { }
        } message: {
            Text("学习统计功能正在火速开发中...")
        }
        .alert("恢复未完成的题目？", isPresented: Binding(
            get: { viewModel?.showingDraftAlert ?? false },
            set: { viewModel?.showingDraftAlert = $0 }
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
            get: { viewModel?.showingSubjectManager ?? false },
            set: { viewModel?.showingSubjectManager = $0 }
        )) {
            SubjectManagerView()
        }
    }
}

#Preview {
    DashboardView(router: DashboardRouter())
}

/// 独立的今日统计视图，由 ViewModel 传入数据
struct DailyStatsView: View {
    let count: Int
    
    init(count: Int) {
        self.count = count
    }
    
    var body: some View {
        BentoCard(
            title: "今日新增",
            subtitle: "\(count) 题",
            icon: "chart.bar.xaxis",
            gradient: LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        ) {
            // No action
        }
    }
}
