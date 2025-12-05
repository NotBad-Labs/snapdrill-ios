//
//  AdditionalInfoFormSection.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - Additional Info Form Section

/// 补充信息表单区域
///
/// 独立的 View 结构体，包含：
/// - 知识点输入
/// - 来源选择
/// - 笔记输入
struct AdditionalInfoFormSection: View {
    
    // MARK: - Properties
    
    @Bindable var viewModel: ReviewItemFormViewModel
    
    // MARK: - Body
    
    var body: some View {
        FormCard {
            VStack(spacing: 0) {
                knowledgePointsRow
                sourceRow
                noteRow
            }
        } header: {
            Text("capture_section_additional")
        }
    }
}

// MARK: - Additional Info Rows

private extension AdditionalInfoFormSection {
    
    /// 知识点行
    var knowledgePointsRow: some View {
        FormRow(isLast: false) {
            Text("capture_field_knowledge_points")
        } content: {
            TextField(
                viewModel.subject.knowledgePointsPlaceholder(for: viewModel.grade),
                text: $viewModel.knowledgePointsInput
            )
            .multilineTextAlignment(.trailing)
            .submitLabel(.done)
            .onSubmit {
                hideKeyboard()
            }
        }
    }
    
    /// 来源行
    var sourceRow: some View {
        FormRow(isLast: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Text("capture_field_source")
                Image(systemName: viewModel.source.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } content: {
            Picker("", selection: $viewModel.source) {
                ForEach(SourceCategory.allCases) { category in
                    Section {
                        ForEach(Source.allCases.filter { $0.category == category }) { source in
                            Label(source.displayName, systemImage: source.icon)
                                .tag(source)
                        }
                    } header: {
                        Text(category.displayName)
                    }
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
        }
    }
    
    /// 笔记行
    var noteRow: some View {
        FormRow(isLast: true, alignment: .top) {
            Text("capture_field_note")
                .padding(.top, DesignTokens.Spacing.sm)
        } content: {
            TextField(
                String(localized: "capture_field_note_placeholder"),
                text: $viewModel.note,
                axis: .vertical
            )
            .lineLimit(2...4)
            .multilineTextAlignment(.trailing)
            .submitLabel(.done)
            .onSubmit {
                hideKeyboard()
            }
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
