//
//  ReviewAppearanceSettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习卡片外观设置页（从 SettingsView.swift 拆分）
//

import SwiftUI
import SnapDrillCore

/// 复习卡片外观设置页
///
/// 允许用户自定义卡片正面（题目）和背面（答案）的对齐方式与字体大小。
struct ReviewAppearanceSettingsView: View {
    
    // MARK: - Properties
    
    @Binding var alignmentRaw: String
    @Binding var fontSizeRaw: Double
    @Binding var frontAlignmentRaw: String
    @Binding var frontFontSizeRaw: Double
    
    // MARK: - Body
    
    var body: some View {
        Form {
            // MARK: - 卡片正面

            Section(L10n.Settings.cardFrontSection) {
                HStack {
                    Text(L10n.Settings.cardFrontPreview)
                        .font(.system(size: frontFontSizeRaw, weight: .bold, design: .serif))
                        .multilineTextAlignment(resolveTextAlignment(frontAlignmentRaw))
                        .frame(maxWidth: .infinity, alignment: resolveAlignment(frontAlignmentRaw))
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .listRowBackground(Color.clear)

                Picker(L10n.Settings.alignment, selection: $frontAlignmentRaw) {
                    Text(L10n.Settings.alignLeft).tag("leading")
                    Text(L10n.Settings.alignCenter).tag("center")
                    Text(L10n.Settings.alignRight).tag("trailing")
                }

                VStack(alignment: .leading) {
                    Text(L10n.Settings.fontSizeLabel(Int(frontFontSizeRaw)))
                    Slider(value: $frontFontSizeRaw, in: 20...48, step: 1) {
                        Text(L10n.Settings.fontSize)
                    } minimumValueLabel: {
                        Text("A").font(.system(size: 14))
                    } maximumValueLabel: {
                        Text("A").font(.system(size: 24))
                    }
                    .accessibilityValue(L10n.Accessibility.fontSizeValue(Int(frontFontSizeRaw)))
                }
            }

            // MARK: - 卡片背面

            Section(L10n.Settings.cardBackSection) {
                HStack {
                    Text(L10n.Settings.cardBackPreview)
                        .font(.system(size: fontSizeRaw, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(resolveTextAlignment(alignmentRaw))
                        .frame(maxWidth: .infinity, alignment: resolveAlignment(alignmentRaw))
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .listRowBackground(Color.clear)

                Picker(L10n.Settings.alignment, selection: $alignmentRaw) {
                    Text(L10n.Settings.alignLeft).tag("leading")
                    Text(L10n.Settings.alignCenter).tag("center")
                    Text(L10n.Settings.alignRight).tag("trailing")
                }

                VStack(alignment: .leading) {
                    Text(L10n.Settings.fontSizeLabel(Int(fontSizeRaw)))
                    Slider(value: $fontSizeRaw, in: 12...24, step: 1) {
                        Text(L10n.Settings.fontSize)
                    } minimumValueLabel: {
                        Text("A").font(.system(size: 12))
                    } maximumValueLabel: {
                        Text("A").font(.system(size: 24))
                    }
                    .accessibilityValue(L10n.Accessibility.fontSizeValue(Int(fontSizeRaw)))
                }
            }
        }
        .navigationTitle(L10n.Settings.cardAppearanceTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Private Helpers

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
