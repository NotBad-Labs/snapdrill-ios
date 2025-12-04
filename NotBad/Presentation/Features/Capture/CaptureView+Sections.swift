//
//  CaptureView+Sections.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//
//  ⚠️ 注意：此文件已废弃，表单组件已迁移到独立文件：
//  - BasicInfoFormSection.swift
//  - AdditionalInfoFormSection.swift
//  - ReviewItemContentFormSection (错题内容)
//
//  FormCard 和 FormRow 已迁移到 Common/Components/
//

import SwiftUI

// MARK: - Basic Info Form Section

/// 基本信息表单区域
///
/// 独立的 View 结构体，包含：
/// - 标题（必填）
/// - 学科选择
/// - 年级选择
/// - 题型选择
/// - 难度选择
struct BasicInfoFormSection: View {
    
    // MARK: - Properties
    
    @Bindable var viewModel: CaptureViewModel
    
    // MARK: - Body
    
    var body: some View {
        FormCard {
            VStack(spacing: 0) {
                titleRow
                subjectRow
                gradeRow
                reviewItemTypeRow
                difficultyRow
            }
        } header: {
            Text("capture_section_basic")
        }
    }
}

// MARK: - Basic Info Rows

private extension BasicInfoFormSection {
    
    /// 标题行（必填）
    var titleRow: some View {
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
                text: $viewModel.title
            )
            .multilineTextAlignment(.trailing)
            .submitLabel(.done)
            .onSubmit {
                hideKeyboard()
            }
        }
    }
    
    /// 学科行
    var subjectRow: some View {
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
            Picker("", selection: $viewModel.subject) {
                ForEach(Subject.allCases) { subject in
                    Text(subject.displayName)
                        .tag(subject)
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
            .onChange(of: viewModel.subject) { _, newSubject in
                handleSubjectChange(newSubject)
            }
        }
    }
    
    /// 年级行
    var gradeRow: some View {
        let currentRegion = EducationSystemManager.shared.currentRegion
        return FormRow(isLast: false) {
            Text("capture_field_grade")
        } content: {
            Picker("", selection: $viewModel.grade) {
                ForEach(viewModel.subject.applicableGrades(for: currentRegion)) { grade in
                    Text(grade.displayName)
                        .tag(grade)
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
        }
    }
    
    /// 题型行
    var reviewItemTypeRow: some View {
        FormRow(isLast: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Text("capture_field_question_type")
                Image(systemName: viewModel.reviewItemType.icon)
                    .font(.caption)
                    .foregroundStyle(viewModel.reviewItemType.color)
            }
        } content: {
            Picker("", selection: $viewModel.reviewItemType) {
                reviewItemTypePickerContent
            }
            .pickerStyle(.menu)
            .tint(.primary)
        }
    }
    
    /// 题型选择器内容
    @ViewBuilder
    var reviewItemTypePickerContent: some View {
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
    
    /// 难度行
    var difficultyRow: some View {
        FormRow(isLast: true) {
            Text("capture_field_difficulty")
        } content: {
            Picker("", selection: $viewModel.difficulty) {
                ForEach(Difficulty.allCases) { diff in
                    Text(String(repeating: "★", count: diff.stars) + " " + diff.displayName)
                        .tag(diff)
                }
            }
            .pickerStyle(.menu)
            .tint(viewModel.difficulty.color)
        }
    }
    
    /// 处理学科变更
    func handleSubjectChange(_ newSubject: Subject) {
        let currentRegion = EducationSystemManager.shared.currentRegion
        viewModel.subjectWasAutoSelected = false
        
        // 如果当前年级不适用于新学科，自动调整
        if !newSubject.isApplicable(for: viewModel.grade, in: currentRegion) {
            if let firstApplicableGrade = newSubject.applicableGrades(for: currentRegion).first {
                viewModel.grade = firstApplicableGrade
            }
        }
        
        // 如果当前题型不适用于新学科，自动调整
        if !viewModel.reviewItemType.isApplicable(to: newSubject) {
            viewModel.reviewItemType = ReviewItemType.types(for: newSubject).first ?? .other
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

// MARK: - Additional Info Form Section

/// 补充信息表单区域
///
/// 独立的 View 结构体，包含：
/// - 知识点输入
/// - 来源选择
/// - 笔记输入
struct AdditionalInfoFormSection: View {
    
    // MARK: - Properties
    
    @Bindable var viewModel: CaptureViewModel
    
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
                    .foregroundStyle(viewModel.source.color)
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

// MARK: - ReviewItem Content Form Section

/// 错题内容表单区域
///
/// 独立的 View 结构体，包含：
/// - 错题内容文本编辑器
/// - 字数统计
struct ReviewItemContentFormSection: View {
    
    // MARK: - Properties
    
    @Bindable var viewModel: CaptureViewModel
    
    // MARK: - Body
    
    var body: some View {
        FormCard {
            ZStack(alignment: .topLeading) {
                if viewModel.recognizedText.isEmpty {
                    Text("capture_question_content_placeholder")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, DesignTokens.Spacing.sm + 4)
                        .padding(.vertical, DesignTokens.Spacing.sm + 8)
                }
                
                TextEditor(text: $viewModel.recognizedText)
                    .font(.body)
                    .frame(minHeight: 120, maxHeight: 200)
                    .padding(DesignTokens.Spacing.sm)
                    .scrollContentBackground(.hidden)
            }
        } header: {
            HStack {
                Text("capture_section_question_content")
                Spacer()
                if !viewModel.recognizedText.isEmpty {
                    Text("\(viewModel.recognizedText.count)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
