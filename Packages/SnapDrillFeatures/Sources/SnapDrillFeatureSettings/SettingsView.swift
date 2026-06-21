//
//  SettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置功能主界面，系统样式图标 + 分组列表入口。
//

import SwiftUI
import SwiftData
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillData
import SnapDrillFeatureLibrary
import UIKit
import MessageUI


/// 设置功能主界面
///
/// 采用系统样式图标 + 原生分组列表，提供外观、数据管理和关于等各类设置入口。
public struct SettingsView: View {
    @Bindable private var router: SettingsRouter
    @Environment(\.repositories) private var repositories
    @Environment(\.profileManager) private var profileManager
    // 仅用于 #if DEBUG DataSeeder，正式功能通过 RepositoryContainer 访问
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: SettingsViewModel?
    @AppStorage(UDKey.appTintColor) private var appTintColorHex: String = "#007AFF"
    @AppStorage(UDKey.userName) private var userName: String = "用户"
    @AppStorage(UDKey.userAvatar) private var userAvatar: String = "person.crop.circle.fill"
    @AppStorage(UDKey.userAvatarColorIndex) private var userAvatarColorIndex: Int = 0

    @State private var showingClearAlert = false
    @State private var showingClearError = false
    @State private var showingMail = false
    @State private var isGenerating = false
    @State private var seedTask: Task<Void, Never>?
    @State private var clearTask: Task<Void, Never>?
    @State private var settingsAvatarImage: UIImage?
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }

    // 录入字段可见性（产品规格：学科默认开，其余默认关）
    @AppStorage(UDKey.captureFieldSubject) private var showSubjectField: Bool = true
    @AppStorage(UDKey.captureFieldSource) private var showSourceField: Bool = false
    @AppStorage(UDKey.captureFieldDifficulty) private var showDifficultyField: Bool = false
    @AppStorage(UDKey.captureFieldGrade) private var showGradeField: Bool = false
    @AppStorage(UDKey.captureFieldAnswer) private var showAnswerField: Bool = false

    // 外观设置
    @AppStorage(UDKey.appearanceMode) private var appearanceMode: Int = 0
    @AppStorage(UDKey.cardContextAlignment) private var alignmentRaw: String = "leading"
    @AppStorage(UDKey.cardContextFontSize) private var fontSizeRaw: Double = 16.0

    // 正面卡片外观
    @AppStorage(UDKey.cardFrontAlignment) private var frontAlignmentRaw: String = "leading"
    @AppStorage(UDKey.cardFrontFontSize) private var frontFontSizeRaw: Double = 32.0

    // MARK: - Initialization

    /// 创建设置视图
    /// - Parameter router: 注入的路由器
    public init(router: SettingsRouter) {
        self.router = router
    }

    // MARK: - Body

    /// 设置主界面的视图层次
    public var body: some View {
        NavigationStack(path: $router.path) {
            List {
                // 1. Profile（系统头像区）
                Section {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        profileRow
                    }
                }

                Section {
                    NavigationLink(value: SettingsDestination.profileList) {
                        SettingsRow(icon: "person.2.fill", gradientStart: .cyan, gradientEnd: .blue, title: L10n.Settings.switchLearner)
                    }
                }

                // 2. 录入字段配置
                Section(L10n.Settings.captureFields) {
                    Toggle(isOn: $showSubjectField) {
                        SettingsRow(icon: "folder.fill", gradientStart: .blue, gradientEnd: .indigo, title: L10n.Settings.fieldSubject)
                    }
                    .accessibilityHint(L10n.Accessibility.fieldSubjectHint)

                    Toggle(isOn: $showSourceField) {
                        SettingsRow(icon: "doc.text.fill", gradientStart: .orange, gradientEnd: .yellow, title: L10n.Settings.fieldSource)
                    }
                    .accessibilityHint(L10n.Accessibility.fieldSourceHint)

                    Toggle(isOn: $showDifficultyField) {
                        SettingsRow(icon: "star.fill", gradientStart: .yellow, gradientEnd: .orange, title: L10n.Settings.fieldDifficulty)
                    }
                    .accessibilityHint(L10n.Accessibility.fieldDifficultyHint)

                    Toggle(isOn: $showGradeField) {
                        SettingsRow(icon: "tag.fill", gradientStart: .green, gradientEnd: .mint, title: L10n.Settings.fieldGrade)
                    }
                    .accessibilityHint(L10n.Accessibility.fieldGradeHint)

                    Toggle(isOn: $showAnswerField) {
                        SettingsRow(icon: "text.bubble.fill", gradientStart: .purple, gradientEnd: .pink, title: L10n.Settings.fieldAnswer)
                    }
                    .accessibilityHint(L10n.Accessibility.fieldAnswerHint)

                }

                // 3. 回顾设置
                Section(L10n.Settings.reviewSettings) {
                    NavigationLink {
                        ReviewAppearanceSettingsView(
                            alignmentRaw: $alignmentRaw,
                            fontSizeRaw: $fontSizeRaw,
                            frontAlignmentRaw: $frontAlignmentRaw,
                            frontFontSizeRaw: $frontFontSizeRaw
                        )
                    } label: {
                        SettingsRow(icon: "eye.fill", gradientStart: .indigo, gradientEnd: .blue, title: L10n.Settings.cardAppearance)
                    }


                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        SettingsRow(icon: "bell.fill", gradientStart: .red, gradientEnd: .orange, title: L10n.Settings.reviewReminder)
                    }

                }

                // 4. 数据与备份
                Section {
                    NavigationLink {
                        if let viewModel {
                            DataAndSyncSettingsView(viewModel: viewModel)
                        } else {
                            ProgressView()
                        }
                    } label: {
                        SettingsRow(icon: "externaldrive.fill", gradientStart: .blue, gradientEnd: .cyan, title: L10n.Settings.dataAndSync)
                    }


                    NavigationLink {
                        StorageManagementView()
                    } label: {
                        SettingsRow(icon: "internaldrive.fill", gradientStart: .orange, gradientEnd: .yellow, title: L10n.Settings.storageManagement)
                    }

                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        SettingsRow(icon: "hand.raised.fill", gradientStart: Color(.systemGray), gradientEnd: Color(.systemGray2), title: L10n.Settings.privacyAndExport)
                    }

                } header: {
                    Text(L10n.Settings.dataAndSync)
                }

                // 5. 通用
                Section(L10n.Settings.general) {
                    Picker(selection: $appearanceMode) {
                        Text(L10n.Settings.followSystem).tag(0)
                        Text(L10n.Settings.lightMode).tag(1)
                        Text(L10n.Settings.darkMode).tag(2)
                    } label: {
                        SettingsRow(icon: "paintpalette.fill", gradientStart: .purple, gradientEnd: .pink, title: L10n.Settings.appearance)
                    }


                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        SettingsRow(icon: "globe", gradientStart: .green, gradientEnd: .teal, title: L10n.Settings.language, value: AppLanguage.current.displayName)
                    }

                }

                // 6. 分类管理（L3：学科/来源/级别 + 用户自定义维度统一入口）
                Section(L10n.Settings.categoryManagement) {
                    NavigationLink {
                        CategoryManagerView()
                    } label: {
                        SettingsRow(icon: "folder.fill", gradientStart: .blue, gradientEnd: .indigo, title: L10n.Settings.manageCategories)
                    }
                    .accessibilityIdentifier("settings.manageCategories")
                }

                // 7. 危险操作（独立分区，与日常操作物理隔离）
                Section {
                    Button { showingClearAlert = true } label: {
                        SettingsRow(icon: "trash.fill", gradientStart: .red, gradientEnd: .pink, title: L10n.Settings.clearAllData)
                    }
                    .accessibilityHint(L10n.Accessibility.clearAllDataHint)
                } header: {
                    Text(L10n.Settings.dangerZone)
                        .foregroundStyle(.red)
                } footer: {
                    Text(L10n.Settings.dangerZoneFooter)
                }

                // 7. 关于
                Section(L10n.Settings.about) {
                    Button { showingMail = true } label: {
                        SettingsRow(icon: "heart.text.square.fill", gradientStart: .pink, gradientEnd: .red, title: L10n.Settings.feedbackAndSupport)
                    }

                    if let helpURL = URL(string: "https://notbadhq.com/snapdrill/faq") {
                        Link(destination: helpURL) {
                            SettingsRow(icon: "questionmark.circle.fill", gradientStart: .teal, gradientEnd: .green, title: L10n.Settings.helpCenter)
                        }
                        .accessibilityHint("打开外部网页查看常见问题")
                    }

                    NavigationLink(value: SettingsDestination.privacyPolicy) {
                        SettingsRow(icon: "hand.raised.fill", gradientStart: Color(.systemGray), gradientEnd: Color(.systemGray2), title: L10n.Settings.privacyPolicy)
                    }


                    NavigationLink(value: SettingsDestination.termsOfService) {
                        SettingsRow(icon: "doc.text.fill", gradientStart: .blue, gradientEnd: .teal, title: L10n.Settings.termsOfService)
                    }

                }

#if DEBUG
                Section(L10n.Settings.debugTitle) {
                    Button {
                        generateMockData()
                    } label: {
                        if isGenerating {
                            HStack { ProgressView(); Text(L10n.Settings.generating) }
                        } else {
                            SettingsRow(icon: "hammer.fill", gradientStart: .blue, gradientEnd: .purple, title: L10n.Settings.generateTestData(100))
                        }
                    }
                    .disabled(isGenerating)
                    .accessibilityHint(L10n.Accessibility.generateTestDataHint)

                }
#endif
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .placeholder:
                    Text(L10n.Common.comingSoon)
                case .licenses:
                    LicenseView()
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .termsOfService:
                    TermsOfServiceView()
                case .profileList:
                    ProfileListView(profileManager: profileManager)
                }
            }
            .alert(L10n.Settings.clearConfirmTitle, isPresented: $showingClearAlert) {
                Button(L10n.Common.cancel, role: .cancel) { }
                Button(L10n.Settings.clearConfirmButton, role: .destructive) { clearAllData() }
            } message: {
                Text(L10n.Settings.clearConfirmMessage)
            }
            .alert(L10n.Settings.operationFailed, isPresented: $showingClearError) {
                Button(L10n.Common.ok) { viewModel?.clearError = nil }
            } message: {
                Text(viewModel?.clearError ?? L10n.Settings.unknownError)
            }
            .alert(L10n.Settings.feedbackTitle, isPresented: $showingMail) {
                Button(L10n.Settings.copyEmail) {
                    UIPasteboard.general.string = "hello@notbadhq.com"
                }
                Button(L10n.Settings.maybeLater, role: .cancel) { }
            } message: {
                Text(L10n.Settings.feedbackMessage)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(repositories: repositories, profileManager: profileManager)
                }
            }
            .onDisappear {
                seedTask?.cancel()
                clearTask?.cancel()
            }
            .task(id: userAvatar) {
                if userAvatar.contains("images/") {
                    let storage = imageStorage
                    settingsAvatarImage = await storage.loadImageAsync(path: userAvatar)
                } else {
                    settingsAvatarImage = nil
                }
            }
        }
    }

    // MARK: - Private Helpers

    /// Profile 行：系统 insetGrouped 行内的头像 + 姓名 + 副标题。
    @ViewBuilder
    private var profileRow: some View {
        HStack(spacing: 14) {
            avatarView
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.headline)
                    .lineLimit(1)
                Text(L10n.Settings.editProfileSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var avatarView: some View {
        let colors: [[Color]] = [
            [.blue, .purple], [.orange, .red], [.green, .teal],
            [.pink, .indigo], [.gray, .black], [.yellow, .orange]
        ]
        let selectedColors = colors[userAvatarColorIndex < colors.count ? userAvatarColorIndex : 0]

        if userAvatar.contains("images/"), let image = settingsAvatarImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
        } else if userAvatar.contains("images/") {
            // 自定义头像加载中占位
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: userAvatar)
                .font(.system(size: 30))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(colors: selectedColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 52, height: 52)
                .background(Circle().fill(.ultraThinMaterial))
                .clipShape(Circle())
        }
    }

    private func clearAllData() {
        guard let viewModel else { return }
        clearTask?.cancel()
        clearTask = Task {
            await viewModel.clearAllData()
            if viewModel.clearError != nil {
                showingClearError = true
            }
        }
    }

    private func generateMockData() {
        isGenerating = true
        seedTask?.cancel()
        seedTask = Task {
            defer { isGenerating = false }
            do {
                let seeder = DataSeeder(modelContext: modelContext)
                let time = try seeder.seedReviewItems(count: 100)
                SnapDrillLogger.generic.info("生成测试数据成功: \(time)s")
            } catch {
                SnapDrillLogger.generic.error("生成测试数据失败: \(error.localizedDescription)")
            }
        }
    }

}
