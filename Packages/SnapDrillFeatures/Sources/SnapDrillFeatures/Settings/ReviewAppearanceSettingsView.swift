//
//  ReviewAppearanceSettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习卡片外观设置页（从 SettingsView.swift 拆分）
//

import SwiftUI

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
