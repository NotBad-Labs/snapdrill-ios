//
//  BasicInfoFormSection.swift
//  NotBad
//
//  Created for NotBad K12 错题本
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
    
    @Bindable var viewModel: ReviewItemFormViewModel
    
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
                Text("capture_field_review_item_type")
                Image(systemName: viewModel.reviewItemType.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                Text("capture_review_item_type_objective")
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
                Text("capture_review_item_type_subjective")
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
                Text("capture_review_item_type_comprehensive")
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
                    Label {
                        Text(diff.displayName)
                    } icon: {
                        Image(systemName: diff.icon)
                    }
                    .tag(diff)
                }
            }
            .pickerStyle(.menu)
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
