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
import SnapDrillFeatureDashboard
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
    @AppStorage("appTintColor") private var appTintColorHex: String = "#007AFF"
    @AppStorage("userName") private var userName: String = "同学"
    @AppStorage("userAvatar") private var userAvatar: String = "person.crop.circle.fill"
    @AppStorage("userAvatarColorIndex") private var userAvatarColorIndex: Int = 0

    @State private var showingClearAlert = false
    @State private var showingMail = false
    @State private var isGenerating = false
    @State private var seedTask: Task<Void, Never>?
    @State private var clearTask: Task<Void, Never>?
    private let imageStorage = ImageStorage()
    @State private var showingSubjectManager = false
    @State private var showingSourceManager = false
    @State private var showingGradeManager = false

    // Appearance Setting
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("cardContextAlignment") private var alignmentRaw: String = "leading"
    @AppStorage("cardContextFontSize") private var fontSizeRaw: Double = 16.0

    // Front Card Appearance
    @AppStorage("cardFrontAlignment") private var frontAlignmentRaw: String = "center"
    @AppStorage("cardFrontFontSize") private var frontFontSizeRaw: Double = 32.0

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

                // 2. 复习设置
                Section("复习设置") {
                    NavigationLink {
                        ReviewAppearanceSettingsView(
                            alignmentRaw: $alignmentRaw,
                            fontSizeRaw: $fontSizeRaw,
                            frontAlignmentRaw: $frontAlignmentRaw,
                            frontFontSizeRaw: $frontFontSizeRaw
                        )
                    } label: {
                        SettingsRow(icon: "eye.fill", gradientStart: .indigo, gradientEnd: .blue, title: "卡片外观")
                    }
                    .listRowSeparator(.hidden)

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        SettingsRow(icon: "bell.fill", gradientStart: .red, gradientEnd: .orange, title: "复习提醒")
                    }
                    .listRowSeparator(.hidden)
                }

                // 3. 数据与云同步
                Section("数据与云同步") {
                    NavigationLink {
                        DataAndSyncSettingsView()
                    } label: {
                        SettingsRow(icon: "icloud.fill", gradientStart: .blue, gradientEnd: .cyan, title: "iCloud 同步与存储")
                    }
                    .listRowSeparator(.hidden)

                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        SettingsRow(icon: "hand.raised.fill", gradientStart: Color(.systemGray), gradientEnd: Color(.systemGray2), title: "隐私与导出")
                    }
                    .listRowSeparator(.hidden)
                }

                // 4. 通用
                Section("通用") {
                    Picker(selection: $appearanceMode) {
                        Text("跟随系统").tag(0)
                        Text("浅色").tag(1)
                        Text("深色").tag(2)
                    } label: {
                        SettingsRow(icon: "paintpalette.fill", gradientStart: .purple, gradientEnd: .pink, title: "外观")
                    }
                    .listRowSeparator(.hidden)

                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        SettingsRow(icon: "globe", gradientStart: .green, gradientEnd: .teal, title: "语言", value: "简体中文")
                    }
                    .listRowSeparator(.hidden)
                }

                // 5. 数据管理
                Section("数据管理") {
                    Button { showingSubjectManager = true } label: {
                        SettingsRow(icon: "folder.fill", gradientStart: .blue, gradientEnd: .indigo, title: "管理学科")
                    }
                    .listRowSeparator(.hidden)

                    Button { showingSourceManager = true } label: {
                        SettingsRow(icon: "doc.text.fill", gradientStart: .orange, gradientEnd: .yellow, title: "管理来源")
                    }
                    .listRowSeparator(.hidden)

                    Button { showingGradeManager = true } label: {
                        SettingsRow(icon: "graduationcap.fill", gradientStart: .green, gradientEnd: .mint, title: "管理年级")
                    }
                    .listRowSeparator(.hidden)

                    Button { showingClearAlert = true } label: {
                        SettingsRow(icon: "trash.fill", gradientStart: .red, gradientEnd: .pink, title: "清空所有数据")
                    }
                    .listRowSeparator(.hidden)
                }

                // 6. 关于
                Section("关于") {
                    Button { showingMail = true } label: {
                        SettingsRow(icon: "heart.text.square.fill", gradientStart: .pink, gradientEnd: .red, title: "反馈与支持")
                    }
                    .listRowSeparator(.hidden)

                    NavigationLink(value: SettingsDestination.privacyPolicy) {
                        SettingsRow(icon: "hand.raised.fill", gradientStart: Color(.systemGray), gradientEnd: Color(.systemGray2), title: "隐私政策")
                    }
                    .listRowSeparator(.hidden)

                    NavigationLink(value: SettingsDestination.termsOfService) {
                        SettingsRow(icon: "doc.text.fill", gradientStart: .blue, gradientEnd: .teal, title: "用户协议")
                    }
                    .listRowSeparator(.hidden)
                }

#if DEBUG
                Section("调试") {
                    Button {
                        generateMockData()
                    } label: {
                        if isGenerating {
                            HStack { ProgressView(); Text("生成中...") }
                        } else {
                            SettingsRow(icon: "hammer.fill", gradientStart: .blue, gradientEnd: .purple, title: "生成测试数据 (100条)")
                        }
                    }
                    .disabled(isGenerating)
                    .listRowSeparator(.hidden)
                }
#endif
            }
            .listStyle(.insetGrouped)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .placeholder:
                    Text("即将上线")
                case .licenses:
                    LicenseView()
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .termsOfService:
                    TermsOfServiceView()
                }
            }
            .alert("确实要清空吗？", isPresented: $showingClearAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) { clearAllData() }
            } message: {
                Text("此操作将删除所有题目和学科分类，且不可恢复。")
            }
            .sheet(isPresented: $showingSubjectManager) { SubjectManagerView() }
            .sheet(isPresented: $showingSourceManager) { SourceManagerView() }
            .sheet(isPresented: $showingGradeManager) { GradeManagerView() }
            .alert("意见反馈", isPresented: $showingMail) {
                Button("复制邮箱") {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = "hello@notbadhq.com"
                    #endif
                }
                Button("以后再说", role: .cancel) { }
            } message: {
                Text("感谢您使用 SnapDrill！您可以发送邮件至 hello@notbadhq.com，或直接在 TestFlight 中反馈。")
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
                Text("编辑个人资料")
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
        initViewModelIfNeeded()
        guard let vm = viewModel else { return }
        clearTask?.cancel()
        clearTask = Task { await vm.clearAllData() }
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

    private func initViewModelIfNeeded() {
        if viewModel == nil {
            viewModel = SettingsViewModel(repositories: repositories)
        }
    }
}
