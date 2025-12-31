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
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Header Area
                    HeaderView()
                    
                    // 2. Hero Section (Review Status)
                    // 智能切换状态：新用户 vs 有任务 vs 全部完成
                    ReviewHeroCard(
                        totalCount: totalCount,
                        dueCount: dueCount,
                        onStartReview: { router.navigateToReview() },
                        onStartReview: { router.navigateToReview() },
                        onStartCapture: { checkDraftAndCapture() }
                    )
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
                    let item = ReviewItemModel(content: draft.content, subject: "未分类") // Temp
                    // We need a way to pass the image to Edit View directly or handle it in Router.
                    // For simplicity, let's just go to capture and let capture view handle it?
                    // Or better, Router needs a 'restore' endpoint.
                    // Let's assume Router has a way or we push a specific view.
                    
                    // Actually, the simplest way is to route to Capture, and tell CaptureView to skip to Edit directly with this image.
                    // But `router.navigateToCapture()` goes to SmartCameraView.
                    
                    // Let's modify router or just clear draft for now as "Start New" is the safe default if we can't easily restore.
                    // WAIT: The requirement is to restore.
                    // Implementation: 
                    // 1. Pass draft data to Router -> .capture(draft: draft)
                    // 2. Or, since we are in `NotBadFeatures`, we can manually construct the view?
                    
                    // Let's stick to the plan: Route to Capture, but maybe we can improve Router later.
                    // For this iteration, let's just "Start New" works, but "Restore" needs Router support.
                    
                    // Let's hack it: router.navigateToCapture() but maybe we save it to a "CurrentActiveDraft" that the CameraView checks on appear?
                    
                    router.navigateToCapture(withDraft: draft)
                } else {
                    router.navigateToCapture()
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("您有上次未保存的拍摄内容，是否继续编辑？")
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
            // iOS 26 Glassy Background
            ZStack {
                Color(UIColor.systemGroupedBackground)
                
                // Abstract Mesh Gradient Simulation (iOS 18+)
                GeometryReader { proxy in
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: -50, y: -50)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: proxy.size.width - 250, y: 100)
                        
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: 50, y: proxy.size.height - 200)
                }
                .ignoresSafeArea()
            }
        }
    }
    
    private func loadData() {
        let repo = ReviewRepository(modelContext: modelContext)
        let subjectRepo = SubjectRepository(modelContext: modelContext)
        do {
            self.dueCount = try repo.fetchDueCount()
            self.totalCount = try repo.totalItemCount() // New Check
            subjectRepo.initializeDefaultsIfNeeded()
        } catch {
            print("Failed to fetch dashboard data: \(error)")
        }
    }
}

// MARK: - Modern Components

struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.footnote)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text("NotBad 学习助手")
                    .font(.largeTitle.bold())
            }
            Spacer()
            // Avatar / Profile
            Image(systemName: "person.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

/// 核心卡片：根据复习数量动态展示 UI
struct ReviewHeroCard: View {
    let totalCount: Int
    let dueCount: Int
    let onStartReview: () -> Void
    let onStartCapture: () -> Void
    
    var body: some View {
        VStack {
            if totalCount == 0 {
                // Scenario 1: New User (Zero Data)
                // Guide them to add first item
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("欢迎使用")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        
                        Text("添加第一道错题，开启复习之旅")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Button(action: onStartCapture) {
                            Label("录入题目", systemImage: "plus.circle.fill")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .foregroundStyle(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(24)
                .background(
                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            } else if dueCount > 0 {
                // Scenario 2: Has Tasks (Due > 0)
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日待复习")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Text("\(dueCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Button(action: onStartReview) {
                            Text("立即开始")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .foregroundStyle(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                    // Dynamic Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: 0.7) // Mock progress
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 80, height: 80)
                }
                .padding(24)
                .background(
                    LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            } else {
                // Scenario 3: All Caught Up (Total > 0, Due == 0)
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("太棒了！")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        
                        Text("今日复习任务已清空")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.green.gradient)
                        .symbolEffect(.bounce, value: true)
                }
                .padding(24)
                .background(.regularMaterial) // Use material for cards
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

struct BentoCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(gradient) // Gradient Text/Icon
                        .padding(8)
                        .background(.ultraThickMaterial) // Contrast
                        .clipShape(Circle())
                    Spacer()
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary) // Auto adapting
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(height: 120)
            .background(.regularMaterial) // Glass Effect
            .clipShape(RoundedRectangle(cornerRadius: 24)) // More rounded for "iOS 26"
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.2), lineWidth: 1) // Glass Border
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5) // Softer shadow
        }
    }
}

// Keep existing SubjectManagerView ...
struct SubjectManagerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \SubjectModel.sortOrder) var subjects: [SubjectModel]
    
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(subjects) { subject in
                    HStack {
                        Image(systemName: subject.icon)
                            .foregroundStyle(Color(hex: subject.colorHex))
                        Text(subject.name)
                    }
                }
                .onDelete(perform: deleteSubject)
            }
            .navigationTitle("管理学科")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSubjectView()
            }
        }
    }
    
    func deleteSubject(at offsets: IndexSet) {
        for index in offsets {
            let subject = subjects[index]
            modelContext.delete(subject)
        }
    }
}

struct AddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "book"
    @State private var selectedColorHex: String = "#4FC3F7"
    
    let colors = ["#E57373", "#4FC3F7", "#AED581", "#7986CB", "#F06292", "#FFB74D", "#9575CD"]
    let icons = ["book", "text.book.closed", "function", "character.book.closed", "atom", "flask", "leaf", "scroll", "globe", "paintbrush"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("学科名称") {
                    TextField("例如：微积分", text: $name)
                }
                
                Section("选择图标") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .padding(8)
                                .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
                
                Section("选择颜色") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("添加学科")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSubject()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    func saveSubject() {
        let repo = SubjectRepository(modelContext: modelContext)
        repo.add(name: name, icon: selectedIcon, colorHex: selectedColorHex)
    }
}
