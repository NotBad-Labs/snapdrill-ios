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
    
    @State private var showingClearAlert = false
    @State private var showingMail = false
    @State private var isGenerating = false
    
    public init(router: SettingsRouter) {
        self.router = router
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            List {
                // 1. Profile / Search Placeholder
                // Telegram puts Profile at top.
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.gray.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName)
                                .font(.title2.bold())
                            Text("+86 1XX XXXX XXXX") // Mock phone
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 2. Core Settings
                Section {
                    SettingsRow(icon: "bell.fill", color: .red, title: "通知与声音")
                    SettingsRow(icon: "lock.fill", color: .gray, title: "隐私与安全")
                    SettingsRow(icon: "cylinder.split.1x2.fill", color: .green, title: "数据与存储")
                    SettingsRow(icon: "paintpalette.fill", color: .cyan, title: "外观", value: "跟随系统")
                    SettingsRow(icon: "battery.100", color: .orange, title: "省电模式", value: "关闭")
                    SettingsRow(icon: "globe", color: .purple, title: "语言", value: "简体中文")
                }
                
                // 3. Premium / App Specific
                Section {
                    SettingsRow(icon: "star.fill", color: .purple, title: "NotBad 会员", isPremium: true)
                    SettingsRow(icon: "gift.fill", color: .pink, title: "赠送会员")
                }
                
                // 4. Support
                Section {
                    Button {
                        // Action
                    } label: {
                        SettingsRow(icon: "message.fill", color: .orange, title: "提问")
                    }
                    
                    Button {
                        router.path.append(SettingsDestination.licenses) // Reuse for demo
                    } label: {
                         SettingsRow(icon: "questionmark.circle.fill", color: .cyan, title: "NotBad 常见问题")
                    }
                    
                    SettingsRow(icon: "lightbulb.fill", color: .yellow, title: "新功能特性")
                }
                
                // 5. Data Management (Real Features)
                Section("数据") {
                    Button {
                        // Mock action
                    } label: {
                         SettingsRow(icon: "folder.fill", color: .blue, title: "管理学科分类")
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
        }
    }
    
    private func clearAllData() {
        do {
            try modelContext.delete(model: ReviewItemModel.self)
            try modelContext.delete(model: SubjectModel.self)
            // Re-init defaults
            let subjectRepo = SubjectRepository(modelContext: modelContext)
            subjectRepo.initializeDefaultsIfNeeded()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
    
    private func generateMockData() {
        isGenerating = true
        Task {
            let seeder = DataSeeder(modelContext: modelContext)
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
