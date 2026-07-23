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
    @Environment(\.services) private var services
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
    private let tabBarBreathingRoom: CGFloat = 160
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }

    private static let categoryVisibilityKey = "\(CategoryDimensionModel.visibilityKeyPrefix)\(CategorySystemKey.category)"
    private static let sourceVisibilityKey = "\(CategoryDimensionModel.visibilityKeyPrefix)\(CategorySystemKey.source)"
    private static let levelVisibilityKey = "\(CategoryDimensionModel.visibilityKeyPrefix)\(CategorySystemKey.level)"

    // 录入字段可见性：内置分类/来源/级别默认隐藏；用户在这里或分类管理中按需打开。
    @AppStorage(Self.categoryVisibilityKey) private var showCategoryField: Bool = false
    @AppStorage(Self.sourceVisibilityKey) private var showSourceField: Bool = false
    @AppStorage(Self.levelVisibilityKey) private var showLevelField: Bool = false
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
                if exposesOptionalSurfacesForUITesting {
                    Section {
                        NavigationLink {
                            EditProfileView()
                        } label: {
                            profileRow
                        }
                        .accessibilityIdentifier("settings.editProfile")
                    }

                    Section {
                        NavigationLink(value: SettingsDestination.profileList) {
                            SettingsRow(icon: "person.2.fill", gradientStart: .cyan, gradientEnd: .blue, title: L10n.Settings.switchLearner)
                        }
                        .accessibilityIdentifier("settings.profileList")
                    }
                }

                Section {
                    Text(L10n.Settings.captureFields)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Toggle(isOn: $showCategoryField) {
                        SettingsRow(icon: "folder.fill", gradientStart: .blue, gradientEnd: .indigo, title: L10n.Settings.fieldCategory)
                    }
                    .accessibilityIdentifier("settings.captureField.category")
                    .accessibilityHint(L10n.Accessibility.fieldCategoryHint)

                    Toggle(isOn: $showSourceField) {
                        SettingsRow(icon: "doc.text.fill", gradientStart: .orange, gradientEnd: .yellow, title: L10n.Settings.fieldSource)
                    }
                    .accessibilityIdentifier("settings.captureField.source")
                    .accessibilityHint(L10n.Accessibility.fieldSourceHint)

                    Toggle(isOn: $showLevelField) {
                        SettingsRow(icon: "tag.fill", gradientStart: .green, gradientEnd: .mint, title: L10n.Settings.fieldLevel)
                    }
                    .accessibilityIdentifier("settings.captureField.level")
                    .accessibilityHint(L10n.Accessibility.fieldLevelHint)

                    Toggle(isOn: $showAnswerField) {
                        SettingsRow(icon: "text.bubble.fill", gradientStart: .purple, gradientEnd: .pink, title: L10n.Settings.fieldAnswer)
                    }
                    .accessibilityIdentifier("settings.captureField.answer")
                    .accessibilityHint(L10n.Accessibility.fieldAnswerHint)
                }

                if exposesOptionalSurfacesForUITesting {
                    Section {
                        Text(L10n.Settings.reviewSettings)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)

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
                        .accessibilityIdentifier("settings.reviewAppearance")

                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            SettingsRow(icon: "bell.fill", gradientStart: .red, gradientEnd: .orange, title: L10n.Settings.reviewReminder)
                        }
                        .accessibilityIdentifier("settings.notifications")
                    }
                }

                // 4. 数据与备份
                Section {
                    Text(L10n.Settings.dataAndSync)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)

                    NavigationLink {
                        if let viewModel {
                            DataAndSyncSettingsView(viewModel: viewModel)
                        } else {
                            ProgressView()
                        }
                    } label: {
                        SettingsRow(icon: "externaldrive.fill", gradientStart: .blue, gradientEnd: .cyan, title: L10n.Settings.dataAndSync)
                    }
                    .accessibilityIdentifier("settings.dataAndSync")

                    NavigationLink {
                        StorageManagementView()
                    } label: {
                        SettingsRow(icon: "internaldrive.fill", gradientStart: .orange, gradientEnd: .yellow, title: L10n.Settings.storageManagement)
                    }
                    .accessibilityIdentifier("settings.storage")

                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        SettingsRow(icon: "hand.raised.fill", gradientStart: Color(.systemGray), gradientEnd: Color(.systemGray2), title: L10n.Settings.privacyAndExport)
                    }
                    .accessibilityIdentifier("settings.privacyExport")
                }

                // 5. 通用
                Section {
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
                    .accessibilityIdentifier("settings.language")

                } header: {
                    Text(L10n.Settings.general)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                }

                // 6. 分类管理（L3：分类/来源/级别 + 用户自定义维度统一入口）
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
                    .accessibilityIdentifier("settings.clearAllData")
                    .accessibilityHint(L10n.Accessibility.clearAllDataHint)
                } header: {
                    Text(L10n.Settings.dangerZone)
                        .foregroundStyle(.red)
                } footer: {
                    Text(L10n.Settings.dangerZoneFooter)
                }

                // 7. 关于
                Section {
                    Button { showingMail = true } label: {
                        SettingsRow(icon: "heart.text.square.fill", gradientStart: .pink, gradientEnd: .red, title: L10n.Settings.feedbackAndSupport)
                    }
                    .accessibilityIdentifier("settings.feedback")

                    if let helpURL = URL(string: "https://notbadhq.com/snapdrill/faq") {
                        Link(destination: helpURL) {
                            SettingsRow(icon: "questionmark.circle.fill", gradientStart: .teal, gradientEnd: .green, title: L10n.Settings.helpCenter)
                        }
                        .accessibilityHint("打开外部网页查看常见问题")
                    }

                    NavigationLink(value: SettingsDestination.licenses) {
                        SettingsRow(icon: "curlybraces.square.fill", gradientStart: .purple, gradientEnd: .indigo, title: L10n.Settings.openSourceTitle)
                    }
                    .accessibilityIdentifier("settings.licenses")

                    NavigationLink(value: SettingsDestination.privacyPolicy) {
                        SettingsRow(icon: "hand.raised.fill", gradientStart: Color(.systemGray), gradientEnd: Color(.systemGray2), title: L10n.Settings.privacyPolicy)
                    }
                    .accessibilityIdentifier("settings.privacyPolicy")


                    NavigationLink(value: SettingsDestination.termsOfService) {
                        SettingsRow(icon: "doc.text.fill", gradientStart: .blue, gradientEnd: .teal, title: L10n.Settings.termsOfService)
                    }
                    .accessibilityIdentifier("settings.terms")

                } header: {
                    Text(L10n.Settings.about)
                } footer: {
                    debugSectionBreathingRoom
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
                    .accessibilityIdentifier("settings.generateTestData")
                    .accessibilityHint(L10n.Accessibility.generateTestDataHint)

                }
#endif
            }
            .listStyle(.insetGrouped)
            .padding(.bottom, 100)
            .background(Color(uiColor: .systemGroupedBackground))
            .accessibilityIdentifier("settings.root")
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
                    ProfileListView(
                        profileManager: profileManager,
                        draftService: services.captureDraft
                    )
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

    private var exposesOptionalSurfacesForUITesting: Bool {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--uitesting") && !arguments.contains("--ui-test-core-surface")
#else
        return false
#endif
    }

    @ViewBuilder
    private var bottomBreathingRoom: some View {
        Color.clear
            .frame(height: tabBarBreathingRoom)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var debugSectionBreathingRoom: some View {
#if DEBUG
        bottomBreathingRoom
#else
        EmptyView()
#endif
    }

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
                    .foregroundStyle(.primary)
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
