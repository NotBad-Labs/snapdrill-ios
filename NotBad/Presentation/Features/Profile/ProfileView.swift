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
struct ProfileView: View {

    // MARK: - Environment

    @Query private var allItems: [ReviewItem]
    
    // MARK: - State
    
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var showingEditProfile = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                userSection
                statisticsSection
                settingsSection
                aboutSection
            }
            .navigationTitle("profile_title")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                ProfileEditView()
            }
        }
    }

    // MARK: - User Section

    private var userSection: some View {
        Section {
            Button {
                showingEditProfile = true
            } label: {
                HStack(spacing: DesignTokens.Spacing.lg) {
                    // 头像 with user-selected gradient and icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: profileManager.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .shadow(color: profileManager.gradientColors[0].opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: profileManager.avatar)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(profileManager.nickname)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("profile_subtitle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
            .buttonStyle(.plain)
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
        HStack(spacing: DesignTokens.Spacing.md) {
            // Icon with circle background
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.body)

            Spacer()

            Text(value)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
