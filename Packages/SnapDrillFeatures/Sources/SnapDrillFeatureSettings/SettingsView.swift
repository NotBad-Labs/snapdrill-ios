//
//  SettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置功能主界面，Telegram 风格渐变图标 + iOS 26 glass profile 区。
//

import SwiftUI
import SwiftData
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillData
import SnapDrillFeatureLibrary
#if canImport(UIKit)
import UIKit
import MessageUI
#endif


/// 设置功能主界面
///
/// 采用 Telegram 风格渐变图标 + iOS 26 glass profile 区，提供外观、数据管理和关于等各类设置入口。
public struct SettingsView: View {
    @Bindable private var router: SettingsRouter
    @Environment(\.repositories) private var repositories
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: SettingsViewModel?
    @AppStorage(UDKey.appTintColor) private var appTintColorHex: String = "#007AFF"
    @AppStorage(UDKey.userName) private var userName: String = "同学"
    @AppStorage(UDKey.userAvatar) private var userAvatar: String = "person.crop.circle.fill"
    @AppStorage(UDKey.userAvatarColorIndex) private var userAvatarColorIndex: Int = 0

    @State private var showingClearAlert = false
    @State private var showingClearError = false
    @State private var showingMail = false
    @State private var isGenerating = false
    @State private var seedTask: Task<Void, Never>?
    @State private var clearTask: Task<Void, Never>?
    private let imageStorage = ImageStorage()
    @State private var showingSubjectManager = false
    @State private var showingSourceManager = false
    @State private var showingGradeManager = false

    // 录入字段可见性（产品规格：学科默认开，其余默认关）
    @AppStorage(UDKey.captureFieldSubject) private var showSubjectField: Bool = true
    @AppStorage(UDKey.captureFieldSource) private var showSourceField: Bool = false
    @AppStorage(UDKey.captureFieldDifficulty) private var showDifficultyField: Bool = false
    @AppStorage(UDKey.captureFieldGrade) private var showGradeField: Bool = false
    @AppStorage(UDKey.captureFieldAnswer) private var showAnswerField: Bool = false

    // Appearance Setting
    @AppStorage(UDKey.appearanceMode) private var appearanceMode: Int = 0
    @AppStorage(UDKey.cardContextAlignment) private var alignmentRaw: String = "leading"
    @AppStorage(UDKey.cardContextFontSize) private var fontSizeRaw: Double = 16.0

    // Front Card Appearance
    @AppStorage(UDKey.cardFrontAlignment) private var frontAlignmentRaw: String = "center"
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
                // 1. Profile（glass 背景，Telegram 大头像风格）
                Section {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        profileRow
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // 2. 录入字段配置
                Section(L10n.Settings.captureFields) {
                    Toggle(isOn: $showSubjectField) {
                        SettingsRow(icon: "folder.fill", gradientStart: .blue, gradientEnd: .indigo, title: L10n.Settings.fieldSubject)
                    }


                    Toggle(isOn: $showSourceField) {
                        SettingsRow(icon: "doc.text.fill", gradientStart: .orange, gradientEnd: .yellow, title: L10n.Settings.fieldSource)
                    }


                    Toggle(isOn: $showDifficultyField) {
                        SettingsRow(icon: "star.fill", gradientStart: .yellow, gradientEnd: .orange, title: L10n.Settings.fieldDifficulty)
                    }


                    Toggle(isOn: $showGradeField) {
                        SettingsRow(icon: "graduationcap.fill", gradientStart: .green, gradientEnd: .mint, title: L10n.Settings.fieldGrade)
                    }


                    Toggle(isOn: $showAnswerField) {
                        SettingsRow(icon: "text.bubble.fill", gradientStart: .purple, gradientEnd: .pink, title: L10n.Settings.fieldAnswer)
                    }

                }

                // 3. 复习设置
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

                // 4. 数据与云同步
                Section {
                    NavigationLink {
                        DataAndSyncSettingsView(viewModel: ensureViewModel())
                    } label: {
                        SettingsRow(icon: "icloud.fill", gradientStart: .blue, gradientEnd: .cyan, title: L10n.Settings.dataAndSync)
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
                        SettingsRow(icon: "globe", gradientStart: .green, gradientEnd: .teal, title: L10n.Settings.language, value: L10n.Settings.simplifiedChinese)
                    }

                }

                // 6. 分类管理
                Section(L10n.Settings.categoryManagement) {
                    Button { showingSubjectManager = true } label: {
                        SettingsRow(icon: "folder.fill", gradientStart: .blue, gradientEnd: .indigo, title: L10n.Settings.manageSubjects)
                    }

                    Button { showingSourceManager = true } label: {
                        SettingsRow(icon: "doc.text.fill", gradientStart: .orange, gradientEnd: .yellow, title: L10n.Settings.manageSources)
                    }

                    Button { showingGradeManager = true } label: {
                        SettingsRow(icon: "graduationcap.fill", gradientStart: .green, gradientEnd: .mint, title: L10n.Settings.manageGrades)
                    }
                }

                // 7. 危险操作（独立分区，与日常操作物理隔离）
                Section {
                    Button { showingClearAlert = true } label: {
                        SettingsRow(icon: "trash.fill", gradientStart: .red, gradientEnd: .pink, title: L10n.Settings.clearAllData)
                    }
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
            .sheet(isPresented: $showingSubjectManager) { SubjectManagerView() }
            .sheet(isPresented: $showingSourceManager) { SourceManagerView() }
            .sheet(isPresented: $showingGradeManager) { GradeManagerView() }
            .alert(L10n.Settings.feedbackTitle, isPresented: $showingMail) {
                Button(L10n.Settings.copyEmail) {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = "hello@notbadhq.com"
                    #endif
                }
                Button(L10n.Settings.maybeLater, role: .cancel) { }
            } message: {
                Text(L10n.Settings.feedbackMessage)
            }
            .onDisappear {
                seedTask?.cancel()
                clearTask?.cancel()
            }
        }
    }

    // MARK: - Private Helpers

    /// Profile 行：大头像 + 姓名 + 副标题，iOS 26 glass 背景
    @ViewBuilder
    private var profileRow: some View {
        HStack(spacing: 16) {
            avatarView
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.title3.bold())
                Text(L10n.Settings.editProfileSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background {
            // iOS 26 Liquid Glass — Profile 卡片专用
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .glassEffect()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var avatarView: some View {
        let colors: [[Color]] = [
            [.blue, .purple], [.orange, .red], [.green, .teal],
            [.pink, .indigo], [.gray, .black], [.yellow, .orange]
        ]
        let selectedColors = colors[userAvatarColorIndex < colors.count ? userAvatarColorIndex : 0]

        if userAvatar.contains("images/"), let image = imageStorage.loadImage(path: userAvatar) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
        } else {
            Image(systemName: userAvatar)
                .font(.system(size: 36))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(colors: selectedColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 64, height: 64)
                .background(Circle().fill(.ultraThinMaterial))
                .clipShape(Circle())
        }
    }

    private func clearAllData() {
        let vm = ensureViewModel()
        clearTask?.cancel()
        clearTask = Task {
            await vm.clearAllData()
            if vm.clearError != nil {
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

    @discardableResult
    private func ensureViewModel() -> SettingsViewModel {
        if let viewModel { return viewModel }
        let vm = SettingsViewModel(repositories: repositories)
        viewModel = vm
        return vm
    }
}
