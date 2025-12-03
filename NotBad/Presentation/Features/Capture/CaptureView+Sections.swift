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
    /// 基本信息区域（标题、学科、年级、题型）
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
                            // 如果当前题型不适用于新学科，自动调整
                            if !viewModel.questionType.isApplicable(to: newSubject) {
                                viewModel.questionType = ReviewItemType.types(for: newSubject).first ?? .other
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
                FormRow(isLast: false) {
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
                
                // 题型（根据学科动态筛选）
                FormRow(isLast: false) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text("capture_field_question_type")
                        Image(systemName: viewModel.questionType.icon)
                            .font(.caption)
                            .foregroundStyle(viewModel.questionType.color)
                    }
                } content: {
                    Picker("", selection: .init(
                        get: { viewModel.questionType },
                        set: { viewModel.questionType = $0 }
                    )) {
                        // 按类别分组显示
                        let applicableTypes = ReviewItemType.types(for: viewModel.subject)
                        
                        // 客观题
                        let objectiveTypes = applicableTypes.filter { $0.isObjective }
                        if !objectiveTypes.isEmpty {
                            Section {
                                ForEach(objectiveTypes, id: \.self) { type in
                                    Label(type.displayName, systemImage: type.icon)
                                        .tag(type)
                                }
                            } header: {
                                Text("capture_question_type_objective")
                            }
                        }
                        
                        // 主观题
                        let subjectiveTypes = applicableTypes.filter { $0.isSubjective }
                        if !subjectiveTypes.isEmpty {
                            Section {
                                ForEach(subjectiveTypes, id: \.self) { type in
                                    Label(type.displayName, systemImage: type.icon)
                                        .tag(type)
                                }
                            } header: {
                                Text("capture_question_type_subjective")
                            }
                        }
                        
                        // 综合题
                        let comprehensiveTypes = applicableTypes.filter { $0.isComprehensive }
                        if !comprehensiveTypes.isEmpty {
                            Section {
                                ForEach(comprehensiveTypes, id: \.self) { type in
                                    Label(type.displayName, systemImage: type.icon)
                                        .tag(type)
                                }
                            } header: {
                                Text("capture_question_type_comprehensive")
                            }
                        }
                        
                        // 其他
                        Section {
                            Label(ReviewItemType.other.displayName, systemImage: ReviewItemType.other.icon)
                                .tag(ReviewItemType.other)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }
                
                // 难度（星星数量表示难度等级：1星最简单，5星最难）
                FormRow(isLast: true) {
                    Text("capture_field_difficulty")
                } content: {
                    Picker("", selection: .init(
                        get: { viewModel.difficulty },
                        set: { viewModel.difficulty = $0 }
                    )) {
                        ForEach(Difficulty.allCases) { difficulty in
                            // 用文字拼接星星，绕过 Label icon 只显示一个的限制
                            Text(String(repeating: "★", count: difficulty.stars) + " " + difficulty.displayName)
                                .tag(difficulty)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(viewModel.difficulty.color)
                }
            }
        } header: {
            Text("capture_section_basic")
        }
    }

    /// 补充信息区域（知识点、来源、笔记）
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
                
                // 来源
                FormRow(isLast: false) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text("capture_field_source")
                        Image(systemName: viewModel.source.icon)
                            .font(.caption)
                            .foregroundStyle(viewModel.source.color)
                    }
                } content: {
                    Picker("", selection: .init(
                        get: { viewModel.source },
                        set: { viewModel.source = $0 }
                    )) {
                        // 按分类分组显示
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
