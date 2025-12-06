//
//  ProfileView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData

// MARK: - ProfileView

/// 个人中心视图
///
/// 显示用户信息和应用设置。
///
/// ## 功能特性
///
/// - 用户信息展示（可自定义昵称和头像）
/// - 学习统计
/// - 应用设置
/// - 关于信息
///
/// ## 架构设计
///
/// 使用 Use Cases 获取数据，不直接访问 SwiftData
struct ProfileView: View {

    // MARK: - Environment

    @Environment(\.dependencyFactory) private var dependencyFactory
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    /// 从 Use Case 加载的数据
    @State private var allItems: [ReviewItem] = []
    @State private var isLoading = false
    
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var showingEditProfile = false
    #if DEBUG
    @State private var isGeneratingData = false
    @State private var showingClearConfirm = false
    #endif

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                userSection
                statisticsSection
                settingsSection
                aboutSection
                #if DEBUG
                developerSection
                #endif
            }
            .navigationTitle("profile_title")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                ProfileEditView()
            }
            .task {
                await loadData()
            }
            #if DEBUG
            .alert("确认清空", isPresented: $showingClearConfirm) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    TestDataGenerator.clearAll(in: modelContext)
                    allItems = []
                    Task { await loadData(forceRefresh: true) }
                }
            } message: {
                Text("将删除所有 \(allItems.count) 条数据")
            }
            #endif
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData(forceRefresh: Bool = false) async {
        guard let factory = dependencyFactory else { return }
        
        // 如果已有数据且不强制刷新，跳过加载
        guard forceRefresh || allItems.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let useCase = factory.makeFetchReviewItemsUseCase()
        allItems = await useCase.execute()
    }

    // MARK: - User Section

    private var userSection: some View {
        Section {
            ProfileUserCard(
                nickname: profileManager.nickname,
                avatar: profileManager.avatar,
                gradientColors: profileManager.gradientColors,
                onTap: { showingEditProfile = true }
            )
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        Section("profile_section_statistics") {
            StatisticsRow(
                icon: "books.vertical.fill",
                title: String(localized: "profile_total_items"),
                value: "\(allItems.count)",
                color: Color.brand.primary
            )

            StatisticsRow(
                icon: "checkmark.seal.fill",
                title: String(localized: "profile_mastered"),
                value: "\(masteredCount)",
                color: Color.brand.success
            )

            StatisticsRow(
                icon: "clock.arrow.circlepath",
                title: String(localized: "profile_total_reviews"),
                value: "\(totalReviewCount)",
                color: Color.brand.warning
            )

            StatisticsRow(
                icon: "calendar",
                title: String(localized: "profile_study_days"),
                value: "\(studyDays)",
                color: Color.brand.secondary
            )
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        Section("profile_section_settings") {
            NavigationLink {
                SubjectSettingsView()
            } label: {
                Label("profile_subject_settings", systemImage: "book.fill")
            }
            
            NavigationLink {
                notificationSettingsView
            } label: {
                Label("profile_review_reminder", systemImage: "bell.fill")
            }

            NavigationLink {
                dataManagementView
            } label: {
                Label("profile_data_management", systemImage: "externaldrive.fill")
            }

            NavigationLink {
                appearanceSettingsView
            } label: {
                Label("profile_appearance", systemImage: "paintbrush.fill")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("profile_section_about") {
            NavigationLink {
                helpCenterView
            } label: {
                Label("profile_help_center", systemImage: "questionmark.circle.fill")
            }

            NavigationLink {
                feedbackView
            } label: {
                Label("profile_feedback", systemImage: "envelope.fill")
            }

            HStack {
                Label("profile_version", systemImage: "info.circle.fill")
                Spacer()
                Text("1.1.0")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Developer Section (DEBUG only)
    
    #if DEBUG
    private var developerSection: some View {
        Section("🛠 开发者工具") {
            // 生成测试数据
            Button {
                generateTestData(count: 1000)
            } label: {
                HStack {
                    Label("生成 1000 条数据", systemImage: "plus.square.on.square")
                    Spacer()
                    if isGeneratingData {
                        ProgressView()
                    }
                }
            }
            .disabled(isGeneratingData)
            
            Button {
                generateTestData(count: 3000)
            } label: {
                HStack {
                    Label("生成 3000 条数据", systemImage: "square.stack.3d.up")
                    Spacer()
                    if isGeneratingData {
                        ProgressView()
                    }
                }
            }
            .disabled(isGeneratingData)
            
            Button {
                generateTestData(count: 5000)
            } label: {
                HStack {
                    Label("生成 5000 条数据", systemImage: "cube.box")
                    Spacer()
                    if isGeneratingData {
                        ProgressView()
                    }
                }
            }
            .disabled(isGeneratingData)
            
            // 清空数据
            Button(role: .destructive) {
                showingClearConfirm = true
            } label: {
                Label("清空所有数据", systemImage: "trash")
            }
        }
    }
    
    private func generateTestData(count: Int) {
        isGeneratingData = true
        Task {
            TestDataGenerator.generate(count: count, in: modelContext)
            isGeneratingData = false
        }
    }
    #endif

    // MARK: - Computed Properties

    private var masteredCount: Int {
        allItems.filter { $0.masteryLevel == MasteryLevel.mastered.rawValue }.count
    }

    private var totalReviewCount: Int {
        allItems.reduce(0) { $0 + $1.reviewCount }
    }

    private var studyDays: Int {
        let dates = Set(allItems.map { Calendar.current.startOfDay(for: $0.createdAt) })
        return dates.count
    }

    // MARK: - Navigation Destinations

    private var notificationSettingsView: some View {
        NotificationSettingsView()
    }

    private var dataManagementView: some View {
        DataManagementView()
    }

    private var appearanceSettingsView: some View {
        AppearanceSettingsView()
    }

    private var helpCenterView: some View {
        HelpCenterView()
    }

    private var feedbackView: some View {
        FeedbackView()
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
