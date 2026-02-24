//
//  DashboardView.swift
//  NotBadFeatureDashboard
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首页仪表盘视图，展示复习进度概览和快捷入口。
//

import SwiftUI
import SwiftData
import Observation
import NotBadCore
import NotBadUI
import NotBadData

/// 首页看板界面
///
/// 采用现代化的 "Bento Box" 网格布局，提供清晰的信息层级和操作入口。
/// 核心解决 "0待复习" 时的空洞感，将其转化为正反馈的 "任务完成" 状态。
public struct DashboardView: View {
    @Bindable private var router: DashboardRouter
    @Environment(\.modelContext) private var modelContext
    
    // State for dashboard data
    // Counts are now handled reactively by child views (ReviewHeroCard, DailyStatsView)
    @Query(sort: \SubjectModel.sortOrder) private var subjects: [SubjectModel]
    
    @State private var showingSubjectManager = false
    @State private var showingComingSoon = false
    @State private var showingDraftAlert = false

    // Modern Grid Layout
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    public init(router: DashboardRouter) {
        self.router = router
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Header Area
                        HeaderView()
                        
                        // 2. Hero Section (Review Status)
                        // 2. Hero Section (Review Status, Reactive)
                        ReviewHeroCard(
                            onStartReview: { router.navigateToReview() },
                            onStartCapture: { checkDraftAndCapture() }
                        )
                        
                        // 3. Bento Grid Actions
                        LazyVGrid(columns: columns, spacing: 12) {
                            // Capture Card (Dominant Action)
                            BentoCard(
                                title: "智能扫描",
                                subtitle: "录入新题",
                                icon: "camera.viewfinder",
                                gradient: LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            ) {
                                checkDraftAndCapture()
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
                            DailyStatsView()
                            
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
                                showingSubjectManager = true
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
            .onAppear(perform: loadData)
        }
        .alert("敬请期待", isPresented: $showingComingSoon) {
            Button("好", role: .cancel) { }
        } message: {
            Text("学习统计功能正在火速开发中...")
        }
        .alert("恢复未完成的题目？", isPresented: $showingDraftAlert) {
            Button("开始新的") {
                CaptureDraftService.shared.clearDraft()
                router.navigateToCapture()
            }
            Button("恢复") {
                if let draft = CaptureDraftService.shared.loadDraft() {
                    router.navigateToCapture(withDraft: draft)
                } else {
                    router.navigateToCapture()
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("您有上次未保存的拍摄内容，是否继续编辑？")
        }
        .sheet(isPresented: $showingSubjectManager) {
            SubjectManagerView()
        }
    }
    
    private func checkDraftAndCapture() {
        if CaptureDraftService.shared.hasDraft {
            showingDraftAlert = true
        } else {
            router.navigateToCapture()
        }
    }

    private func loadData() {
        let subjectRepo = SubjectRepository(modelContext: modelContext)
        subjectRepo.initializeDefaultsIfNeeded()
    }
}

#Preview {
    DashboardView(router: DashboardRouter())
        .modelContainer(for: [SubjectModel.self, ReviewItemModel.self], inMemory: true)
}

/// 独立的今日统计视图，使用 @Query 实现自动刷新
struct DailyStatsView: View {
    @Query private var todayItems: [ReviewItemModel]
    
    init() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date().addingTimeInterval(86400)
        
        // Dynamic Predicate for "Today"
        let predicate = #Predicate<ReviewItemModel> { item in
            item.createdAt >= startOfDay && item.createdAt < endOfDay
        }
        
        _todayItems = Query(filter: predicate)
    }
    
    var body: some View {
        BentoCard(
            title: "今日新增",
            subtitle: "\(todayItems.count) 题",
            icon: "chart.bar.xaxis",
            gradient: LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        ) {
            // No action
        }
    }
}
