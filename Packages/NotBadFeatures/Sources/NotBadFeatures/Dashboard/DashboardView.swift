//
//  DashboardView.swift
//  NotBadFeatureDashboard
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
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
    @State private var dueCount: Int = 0
    @State private var totalCount: Int = 0 // Add total count tracking
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
                        ReviewHeroCard(
                            totalCount: totalCount,
                            dueCount: dueCount,
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
                            
                            // Analysis/Stats (Placeholder)
                            BentoCard(
                                title: "学习统计",
                                subtitle: "查看趋势",
                                icon: "chart.bar.xaxis",
                                gradient: LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                            ) {
                                showingComingSoon = true
                            }
                            
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
        let repo = ReviewRepository(modelContext: modelContext)
        let subjectRepo = SubjectRepository(modelContext: modelContext)
        do {
            self.dueCount = try repo.fetchDueCount()
            self.totalCount = try repo.totalItemCount()
            subjectRepo.initializeDefaultsIfNeeded()
        } catch {
            print("Failed to fetch dashboard data: \(error)")
        }
    }
}
