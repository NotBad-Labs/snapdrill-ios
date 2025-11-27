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
                        Text("appearance_dynamic_font")
                        Text("appearance_dynamic_font_description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "textformat.size")
                        .foregroundStyle(Color.brand.primary)
                }
            }
        } header: {
            Text("appearance_section_display")
        } footer: {
            Text("appearance_display_footer")
        }
    }
    
    // MARK: - Accessibility Section
    
    private var accessibilitySection: some View {
        Section {
            Toggle(isOn: $reduceMotion) {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("appearance_reduce_motion")
                        Text("appearance_reduce_motion_description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "figure.walk.motion")
                        .foregroundStyle(Color.brand.secondary)
                }
            }
        } header: {
            Text("appearance_section_accessibility")
        } footer: {
            Text("appearance_accessibility_footer")
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        Section("appearance_section_preview") {
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    colorPreviewCard(Color.brand.primary, String(localized: "appearance_color_primary"))
                    colorPreviewCard(Color.brand.secondary, String(localized: "appearance_color_secondary"))
                    colorPreviewCard(Color.brand.success, String(localized: "appearance_color_success"))
                }
                
                HStack(spacing: DesignTokens.Spacing.md) {
                    colorPreviewCard(Color.brand.warning, String(localized: "appearance_color_warning"))
                    colorPreviewCard(Color.brand.error, String(localized: "appearance_color_error"))
                    colorPreviewCard(.gray, String(localized: "appearance_color_neutral"))
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
