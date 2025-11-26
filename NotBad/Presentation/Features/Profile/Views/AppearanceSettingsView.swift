//
//  AppearanceSettingsView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - AppearanceSettingsView

/// 外观设置视图
///
/// 管理应用主题和显示设置。
struct AppearanceSettingsView: View {
    
    // MARK: - State
    
    @AppStorage("colorScheme") private var colorScheme = ColorSchemeOption.system
    @AppStorage("useDynamicType") private var useDynamicType = true
    @AppStorage("reduceMotion") private var reduceMotion = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            themeSection
            displaySection
            accessibilitySection
            previewSection
        }
        .navigationTitle("外观设置")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        Section("主题") {
            ForEach(ColorSchemeOption.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        colorScheme = option
                    }
                } label: {
                    HStack {
                        Label(option.displayName, systemImage: option.icon)
                            .foregroundStyle(.primary)
                        Spacer()
                        if colorScheme == option {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.brand.primary)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Display Section
    
    private var displaySection: some View {
        Section {
            Toggle(isOn: $useDynamicType) {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("动态字体")
                        Text("跟随系统字体大小设置")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "textformat.size")
                        .foregroundStyle(Color.brand.primary)
                }
            }
        } header: {
            Text("显示")
        } footer: {
            Text("开启后应用会根据系统设置自动调整字体大小。")
        }
    }
    
    // MARK: - Accessibility Section
    
    private var accessibilitySection: some View {
        Section {
            Toggle(isOn: $reduceMotion) {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("减少动画")
                        Text("简化界面动画效果")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "figure.walk.motion")
                        .foregroundStyle(Color.brand.secondary)
                }
            }
        } header: {
            Text("辅助功能")
        } footer: {
            Text("开启后会减少过渡动画，提高界面响应速度。")
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        Section("预览") {
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    colorPreviewCard(Color.brand.primary, "主色")
                    colorPreviewCard(Color.brand.secondary, "辅色")
                    colorPreviewCard(Color.brand.success, "成功")
                }
                
                HStack(spacing: DesignTokens.Spacing.md) {
                    colorPreviewCard(Color.brand.warning, "警告")
                    colorPreviewCard(Color.brand.error, "错误")
                    colorPreviewCard(.gray, "中性")
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }
    
    private func colorPreviewCard(_ color: Color, _ name: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(color)
                .frame(height: 40)
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - ColorSchemeOption

enum ColorSchemeOption: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
