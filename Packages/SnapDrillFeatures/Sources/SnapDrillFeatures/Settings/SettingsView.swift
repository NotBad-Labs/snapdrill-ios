//
//  SettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置功能主界面，提供应用参数配置
//

import SwiftUI
import SwiftData
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillData
#if canImport(UIKit)
import UIKit
import MessageUI
#endif


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
    @State private var showingSubjectManager = false
    @State private var showingSourceManager = false
    @State private var showingGradeManager = false
    
    // Appearance Setting
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0 // 0=System, 1=Light, 2=Dark
    @AppStorage("cardContextAlignment") private var alignmentRaw: String = "leading"
    @AppStorage("cardContextFontSize") private var fontSizeRaw: Double = 16.0
    
    // Front Card Appearance
    @AppStorage("cardFrontAlignment") private var frontAlignmentRaw: String = "center"
    @AppStorage("cardFrontFontSize") private var frontFontSizeRaw: Double = 32.0
    
    // MARK: - Initialization
    
    public init(router: SettingsRouter) {
        self.router = router
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            List {
                // 1. Profile（个人资料在顶部，参考 Telegram 设计范式）
                Section {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        HStack(spacing: 12) {
                            let colors: [[Color]] = [
                                [.blue, .purple], [.orange, .red], [.green, .teal],
                                [.pink, .indigo], [.gray, .black], [.yellow, .orange]
                            ]
                            let selectedColors = colors[userAvatarColorIndex < colors.count ? userAvatarColorIndex : 0]
                            
                            if userAvatar.contains("images/"), let image = ImageStorage().loadImage(path: userAvatar) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                            } else {
                                Image(systemName: userAvatar)
                                    .font(.system(size: 60))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: selectedColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userName)
                                    .font(.title2.bold())
                                    Text("编辑个人资料")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Study Experience Section (Priority)
                Section("复习设置") {
                    NavigationLink {
                        ReviewAppearanceSettingsView(
                            alignmentRaw: $alignmentRaw,
                            fontSizeRaw: $fontSizeRaw,
                            frontAlignmentRaw: $frontAlignmentRaw,
                            frontFontSizeRaw: $frontFontSizeRaw
                        )
                    } label: {
                        SettingsRow(icon: "eye.fill", color: .indigo, title: "卡片外观", value: "已定制")
                    }
                    
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        SettingsRow(icon: "bell.fill", color: .red, title: "复习提醒")
                    }
                }
                
                // Data & Cloud (Utility)
                Section("数据与云同步") {
                    NavigationLink {
                        DataAndSyncSettingsView()
                    } label: {
                        SettingsRow(icon: "icloud.fill", color: .blue, title: "iCloud 同步与存储")
                    }
                    
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        SettingsRow(icon: "hand.raised.fill", color: .gray, title: "隐私与导出")
                    }
                }
                
                // General Settings
                Section("通用") {
                    // Appearance
                    Picker(selection: $appearanceMode) {
                        Text("跟随系统").tag(0)
                        Text("浅色").tag(1)
                        Text("深色").tag(2)
                    } label: {
                        SettingsRow(icon: "paintpalette.fill", color: .cyan, title: "外观")
                    }
                    
                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "globe",
                            color: .purple,
                            title: "语言",
                            value: "简体中文"
                        )
                    }
                }
                
                // Data Management Section
                Section("数据管理") {
                    Button {
                        showingSubjectManager = true
                    } label: {
                        SettingsRow(icon: "folder.fill", color: .blue, title: "管理学科分类")
                    }
                    
                    Button {
                        showingSourceManager = true
                    } label: {
                        SettingsRow(icon: "doc.text.fill", color: .orange, title: "管理来源")
                    }

                    Button {
                        showingGradeManager = true
                    } label: {
                        SettingsRow(icon: "graduationcap.fill", color: .green, title: "管理年级")
                    }

                    if showingClearAlert { } // Trigger logic moved to modifier
                    Button {
                        showingClearAlert = true
                    } label: {
                        SettingsRow(icon: "trash.fill", color: .red, title: "清空所有数据")
                    }
                }
                
                // 6. About
                Section("关于") {
                    Button {
                        showingMail = true
                    } label: {
                        SettingsRow(icon: "heart.text.square.fill", color: .pink, title: "反馈与支持")
                    }
                    
                    NavigationLink(value: SettingsDestination.privacyPolicy) {
                        SettingsRow(icon: "hand.raised.fill", color: .gray, title: "隐私政策")
                    }
                    
                    NavigationLink(value: SettingsDestination.termsOfService) {
                        SettingsRow(icon: "doc.text.fill", color: .blue, title: "用户协议")
                    }
                }
                
#if DEBUG
                Section("调试") {
                     Button {
                        generateMockData()
                    } label: {
                        if isGenerating {
                            HStack { ProgressView(); Text("生成中...") }
                        } else {
                            SettingsRow(icon: "hammer.fill", color: .blue, title: "生成测试数据 (100条)")
                        }
                    }
                    .disabled(isGenerating)
                }
#endif
            }
            .listStyle(.insetGrouped) // The key to the Telegram look
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline) // Telegram usually inline title or large
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
                Button("清空", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("此操作将删除所有题目和学科分类，且不可恢复。")
            }
            .sheet(isPresented: $showingSubjectManager) {
                SubjectManagerView()
            }
            .sheet(isPresented: $showingSourceManager) {
                SourceManagerView()
            }
            .sheet(isPresented: $showingGradeManager) {
                GradeManagerView()
            }
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
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func clearAllData() {
        initViewModelIfNeeded()
        viewModel?.clearAllData()
    }
    
    private func generateMockData() {
        isGenerating = true
        seedTask?.cancel()
        seedTask = Task {
            defer { isGenerating = false }
            do {
                // 直接使用 mainContext，确保数据写入后 ReviewRepository 立即可见
                // DataSeeder.seedReviewItems 内部已在 save 后 post reviewDataDidChange
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
