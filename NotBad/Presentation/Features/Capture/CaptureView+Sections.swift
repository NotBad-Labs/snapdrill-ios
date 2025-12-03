//
//  CaptureView+Sections.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import SwiftUI
import PhotosUI

// MARK: - Form Sections

extension CaptureView {
    /// 基本信息区域（标题、学科、年级）
    func basicInfoSection(viewModel: CaptureViewModel) -> some View {
        FormCard {
            VStack(spacing: 0) {
                // 标题（必填）
                FormRow(isLast: false) {
                    HStack {
                        Text("capture_field_title")
                            .foregroundStyle(.primary)
                        Text("*")
                            .foregroundStyle(Color.brand.error)
                        Spacer()
                    }
                } content: {
                    TextField(
                        viewModel.subject.titlePlaceholder(for: viewModel.grade),
                        text: .init(
                            get: { viewModel.title },
                            set: { viewModel.title = $0 }
                        )
                    )
                    .multilineTextAlignment(.trailing)
                    .submitLabel(.done)
                    .onSubmit {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }

                // 学科
                FormRow(isLast: false) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text("capture_field_subject")
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if viewModel.subjectWasAutoSelected {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(Color.brand.primary)
                        }
                    }
                } content: {
                    let currentRegion = EducationSystemManager.shared.currentRegion
                    Picker("", selection: .init(
                        get: { viewModel.subject },
                        set: { newSubject in
                            viewModel.subject = newSubject
                            viewModel.subjectWasAutoSelected = false
                            // 如果当前年级不适用于新学科，自动调整到适用的第一个年级
                            if !newSubject.isApplicable(for: viewModel.grade, in: currentRegion) {
                                if let firstApplicableGrade = newSubject.applicableGrades(for: currentRegion).first {
                                    viewModel.grade = firstApplicableGrade
                                }
                            }
                        }
                    )) {
                        ForEach(Subject.allCases) { subject in
                            Text(subject.displayName)
                                .tag(subject)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }

                // 年级（仅显示当前学科在当前教育地区适用的年级）
                FormRow(isLast: true) {
                    Text("capture_field_grade")
                } content: {
                    let currentRegion = EducationSystemManager.shared.currentRegion
                    Picker("", selection: .init(
                        get: { viewModel.grade },
                        set: { viewModel.grade = $0 }
                    )) {
                        ForEach(viewModel.subject.applicableGrades(for: currentRegion)) { grade in
                            Text(grade.displayName)
                                .tag(grade)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }
            }
        } header: {
            Text("capture_section_basic")
        }
    }

    /// 补充信息区域（知识点、笔记）
    func additionalInfoSection(viewModel: CaptureViewModel) -> some View {
        FormCard {
            VStack(spacing: 0) {
                // 知识点
                FormRow(isLast: false) {
                    Text("capture_field_knowledge_points")
                } content: {
                    TextField(
                        viewModel.subject.knowledgePointsPlaceholder(for: viewModel.grade),
                        text: .init(
                            get: { viewModel.knowledgePointsInput },
                            set: { viewModel.knowledgePointsInput = $0 }
                        )
                    )
                    .multilineTextAlignment(.trailing)
                    .submitLabel(.done)
                    .onSubmit {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }

                // 笔记
                FormRow(isLast: true, alignment: .top) {
                    Text("capture_field_note")
                        .padding(.top, DesignTokens.Spacing.sm)
                } content: {
                    TextField(
                        String(localized: "capture_field_note_placeholder"),
                        text: .init(
                            get: { viewModel.note },
                            set: { viewModel.note = $0 }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .multilineTextAlignment(.trailing)
                    .submitLabel(.done)
                    .onSubmit {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        } header: {
            Text("capture_section_additional")
        }
    }
}

// MARK: - FormCard

/// 表单卡片容器
struct FormCard<Content: View, Header: View>: View {
    @ViewBuilder let content: () -> Content
    @ViewBuilder let header: () -> Header

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            header()
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, DesignTokens.Spacing.sm)

            content()
                .background(Color.semantic.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
    }
}

// MARK: - FormRow

/// 表单行
struct FormRow<Label: View, Content: View>: View {
    let isLast: Bool
    var alignment: VerticalAlignment = .center
    @ViewBuilder let label: () -> Label
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: alignment) {
                label()
                    .font(.body)
                Spacer()
                content()
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.md)

            if !isLast {
                Divider()
                    .padding(.leading, DesignTokens.Spacing.md)
            }
        }
    }
}
