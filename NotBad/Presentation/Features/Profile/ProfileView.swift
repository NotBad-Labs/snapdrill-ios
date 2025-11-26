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
/// - 用户信息展示
/// - 学习统计
/// - 应用设置
/// - 关于信息
struct ProfileView: View {
    
    // MARK: - Environment
    
    @Query private var allItems: [ReviewItem]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                userSection
                statisticsSection
                settingsSection
                aboutSection
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - User Section
    
    private var userSection: some View {
        Section {
            HStack(spacing: DesignTokens.Spacing.lg) {
                // 头像
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brand.primary, Color.brand.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("学习小能手")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("坚持记录，进步看得见")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        Section("学习统计") {
            StatisticsRow(
                icon: "books.vertical.fill",
                title: "总错题数",
                value: "\(allItems.count)",
                color: Color.brand.primary
            )
            
            StatisticsRow(
                icon: "checkmark.seal.fill",
                title: "已掌握",
                value: "\(masteredCount)",
                color: Color.brand.success
            )
            
            StatisticsRow(
                icon: "clock.arrow.circlepath",
                title: "总复习次数",
                value: "\(totalReviewCount)",
                color: Color.brand.warning
            )
            
            StatisticsRow(
                icon: "calendar",
                title: "学习天数",
                value: "\(studyDays)",
                color: Color.brand.secondary
            )
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        Section("设置") {
            NavigationLink {
                notificationSettingsView
            } label: {
                Label("复习提醒", systemImage: "bell.fill")
            }
            
            NavigationLink {
                dataManagementView
            } label: {
                Label("数据管理", systemImage: "externaldrive.fill")
            }
            
            NavigationLink {
                appearanceSettingsView
            } label: {
                Label("外观设置", systemImage: "paintbrush.fill")
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("关于") {
            NavigationLink {
                helpCenterView
            } label: {
                Label("帮助中心", systemImage: "questionmark.circle.fill")
            }
            
            NavigationLink {
                feedbackView
            } label: {
                Label("意见反馈", systemImage: "envelope.fill")
            }
            
            HStack {
                Label("版本", systemImage: "info.circle.fill")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
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

// MARK: - StatisticsRow

/// 统计行组件
private struct StatisticsRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
