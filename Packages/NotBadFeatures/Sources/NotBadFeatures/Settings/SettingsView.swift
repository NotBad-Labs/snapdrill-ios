//
//  SettingsView.swift
//  NotBadFeatureSettings
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  设置功能主界面，提供应用参数配置
//

import SwiftUI
import Observation
import NotBadCore
import NotBadUI
import SwiftData
import NotBadData
import MessageUI

/// 设置功能界面
///
/// 采用成熟的商业化设置页设计范式：个人信息 -> 通用设置 -> 反馈 -> 关于。
/// 确保每个按钮点击都有响应。
public struct SettingsView: View {
    @Bindable private var router: SettingsRouter
    @Environment(\.modelContext) private var modelContext
    
    // State for mock settings
    @AppStorage("appTintColor") private var appTintColorHex: String = "#007AFF"
    @AppStorage("userName") private var userName: String = "Student"
    @AppStorage("userAvatar") private var userAvatar: String = "person.crop.circle.fill"
    @AppStorage("userAvatarColorIndex") private var userAvatarColorIndex: Int = 0
    
    @State private var showingClearAlert = false
    @State private var showingMail = false
    @State private var isGenerating = false
    @State private var showingSubjectManager = false
    @State private var showingSourceManager = false
    
    // Appearance Setting
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0 // 0=System, 1=Light, 2=Dark
    @AppStorage("cardContextAlignment") private var alignmentRaw: String = "leading"
    @AppStorage("cardContextFontSize") private var fontSizeRaw: Double = 16.0
    
    // Front Card Appearance
    @AppStorage("cardFrontAlignment") private var frontAlignmentRaw: String = "center"
    @AppStorage("cardFrontFontSize") private var frontFontSizeRaw: Double = 32.0
    
    public init(router: SettingsRouter) {
        self.router = router
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            List {
                // 1. Profile / Search Placeholder
                // Telegram puts Profile at top.
                // 1. Profile / Search Placeholder
                // Telegram puts Profile at top.
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
                            
                            Image(systemName: userAvatar)
                                .font(.system(size: 60))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(LinearGradient(colors: selectedColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userName)
                                    .font(.title2.bold())
                                Text("编辑个人资料") // Mock subtitle
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 2. Core Settings (Working Features)
                Section("通用") {
                    // 外观切换 (Working)
                    Picker(selection: $appearanceMode) {
                        Text("跟随系统").tag(0)
                        Text("浅色").tag(1)
                        Text("深色").tag(2)
                    } label: {
                        SettingsRow(icon: "paintpalette.fill", color: .cyan, title: "外观")
                    }
                }
                
                // 3. Review Appearance (New)
                Section("复习体验") {
                     NavigationLink {
                        ReviewAppearanceSettingsView(
                            alignmentRaw: $alignmentRaw,
                            fontSizeRaw: $fontSizeRaw,
                            frontAlignmentRaw: $frontAlignmentRaw,
                            frontFontSizeRaw: $frontFontSizeRaw
                        )
                     } label: {
                        SettingsRow(icon: "eye.fill", color: .indigo, title: "卡片外观")
                     }
                }
                
                // 4. Coming Soon
                Section("即将上线") {
                    SettingsRow(icon: "bell.fill", color: .red, title: "通知与声音")
                    SettingsRow(icon: "star.fill", color: .purple, title: "NotBad 会员", isPremium: true)
                    SettingsRow(icon: "icloud.fill", color: .blue, title: "iCloud 同步")
                }
                .foregroundStyle(.secondary)
                
                // 5. Data Management (Real Features)
                Section("数据") {
                    Button {
                        showingSubjectManager = true
                    } label: {
                         SettingsRow(icon: "folder.fill", color: .blue, title: "管理学科分类")
                    }
                    
                    Button {
                        showingSourceManager = true
                    } label: {
                         SettingsRow(icon: "doc.text.fill", color: .green, title: "管理来源")
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
                    NavigationLink(value: SettingsDestination.privacyPolicy) {
                        SettingsRow(icon: "hand.raised.fill", color: .gray, title: "隐私政策")
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
            .searchable(text: .constant(""), prompt: "搜索设置") // Mock search
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .placeholder:
                    Text("即将上线")
                case .licenses:
                    LicenseView()
                case .privacyPolicy:
                    PrivacyPolicyView()
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
                SourceManagerView(modelContext: modelContext)
            }
        }
    }
    
    private func clearAllData() {
        do {
            try modelContext.delete(model: ReviewItemModel.self)
            try modelContext.delete(model: SubjectModel.self)
            try modelContext.delete(model: SourceModel.self)
            // Re-init defaults
            let subjectRepo = SubjectRepository(modelContext: modelContext)
            subjectRepo.initializeDefaultsIfNeeded()
            let sourceRepo = SourceRepository(modelContext: modelContext)
            sourceRepo.seedDefaultSourcesIfNeeded()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
    
    private func generateMockData() {
        isGenerating = true
        Task {
            let seeder = DataSeeder(container: modelContext.container)
            do {
                let time = try await seeder.seedReviewItems(count: 100)
                print("Success: \(time)s")
            } catch {
                print("Seeding failed: \(error)")
            }
            isGenerating = false
        }
    }
}

// MARK: - Components
struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    var value: String?
    var isPremium: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon Box
            ZStack {
                if isPremium {
                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                } else {
                    color
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            )
            
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if let value {
                Text(value)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView(router: SettingsRouter())
        .modelContainer(for: [ReviewItemModel.self, SubjectModel.self], inMemory: true)
}

/// 独立的复习外观设置页
/// 独立的复习外观设置页
struct ReviewAppearanceSettingsView: View {
    @Binding var alignmentRaw: String
    @Binding var fontSizeRaw: Double
    @Binding var frontAlignmentRaw: String
    @Binding var frontFontSizeRaw: Double
    
    var body: some View {
        Form {
            // MARK: - 卡片正面
            Section("卡片正面 (题目)") {
                HStack {
                    Text("Sample Question")
                        .font(.system(size: frontFontSizeRaw, weight: .bold, design: .serif))
                        .multilineTextAlignment(resolveTextAlignment(frontAlignmentRaw))
                        .frame(maxWidth: .infinity, alignment: resolveAlignment(frontAlignmentRaw))
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .listRowBackground(Color.clear)
                
                Picker("对齐方式", selection: $frontAlignmentRaw) {
                    Text("左对齐").tag("leading")
                    Text("居中").tag("center")
                    Text("右对齐").tag("trailing")
                }
                
                VStack(alignment: .leading) {
                    Text("字体大小: \(Int(frontFontSizeRaw))")
                    Slider(value: $frontFontSizeRaw, in: 20...48, step: 1) {
                        Text("字体大小")
                    } minimumValueLabel: {
                        Text("A").font(.system(size: 14))
                    } maximumValueLabel: {
                        Text("A").font(.system(size: 24))
                    }
                }
            }
            
            // MARK: - 卡片背面
            Section("卡片背面 (Header)") {
                HStack {
                    Text("Q: Sample Question Context")
                        .font(.system(size: fontSizeRaw, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(resolveTextAlignment(alignmentRaw))
                        .frame(maxWidth: .infinity, alignment: resolveAlignment(alignmentRaw))
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .listRowBackground(Color.clear)
                
                Picker("对齐方式", selection: $alignmentRaw) {
                    Text("左对齐").tag("leading")
                    Text("居中").tag("center")
                    Text("右对齐").tag("trailing")
                }
                
                VStack(alignment: .leading) {
                    Text("字体大小: \(Int(fontSizeRaw))")
                    Slider(value: $fontSizeRaw, in: 12...24, step: 1) {
                        Text("字体大小")
                    } minimumValueLabel: {
                        Text("A").font(.system(size: 12))
                    } maximumValueLabel: {
                        Text("A").font(.system(size: 24))
                    }
                }
            }
        }
        .navigationTitle("卡片外观")
    }
    
    private func resolveAlignment(_ raw: String) -> Alignment {
        switch raw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }
    
    private func resolveTextAlignment(_ raw: String) -> TextAlignment {
        switch raw {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }
}
