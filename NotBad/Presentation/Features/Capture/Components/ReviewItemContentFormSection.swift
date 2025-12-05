//
//  ReviewItemContentFormSection.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - ReviewItem Content Form Section

/// 错题内容表单区域
///
/// 独立的 View 结构体，包含：
/// - 错题内容文本编辑器
/// - 字数统计
struct ReviewItemContentFormSection: View {
    
    // MARK: - Properties
    
    @Bindable var ocrVM: OCRViewModel
    
    // MARK: - Body
    
    var body: some View {
        FormCard {
            ZStack(alignment: .topLeading) {
                if ocrVM.recognizedText.isEmpty {
                    Text("capture_review_item_content_placeholder")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, DesignTokens.Spacing.sm + 4)
                        .padding(.vertical, DesignTokens.Spacing.sm + 8)
                }
                
                TextEditor(text: $ocrVM.recognizedText)
                    .font(.body)
                    .frame(minHeight: 120, maxHeight: 200)
                    .padding(DesignTokens.Spacing.sm)
                    .scrollContentBackground(.hidden)
            }
        } header: {
            HStack {
                Text("capture_section_review_item_content")
                Spacer()
                if !ocrVM.recognizedText.isEmpty {
                    Text("\(ocrVM.recognizedText.count)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
