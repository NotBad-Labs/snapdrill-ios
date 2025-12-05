//
//  ItemDetailComponents.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData

// MARK: - DisplayContent

/// 显示模式内容
struct DisplayContent: View {

    let reviewItem: ReviewItem

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // 标题
            InfoCard(title: "标题", icon: "text.alignleft") {
                Text(reviewItem.title)
                    .font(.headline)
            }

            // 学科和年级
            HStack(spacing: DesignTokens.Spacing.md) {
                InfoCard(title: "学科", icon: "book.fill") {
                    HStack {
                        Image(systemName: reviewItem.subject.icon)
                            .foregroundStyle(reviewItem.subject.color)
                        Text(reviewItem.subject.displayName)
                            .font(.subheadline)
                    }
                }

                InfoCard(title: "年级", icon: "graduationcap.fill") {
                    Text(reviewItem.grade.displayName)
                        .font(.subheadline)
                }
            }

            // 难度和题型
            HStack(spacing: DesignTokens.Spacing.md) {
                InfoCard(title: "难度", icon: reviewItem.difficulty.icon) {
                    HStack(spacing: 2) {
                        Text(reviewItem.difficulty.displayName)
                            .font(.subheadline)
                        Text("(\(reviewItem.difficulty.stars)星)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                InfoCard(title: "题型", icon: "doc.text.fill") {
                    HStack {
                        Image(systemName: reviewItem.reviewItemType.icon)
                            .foregroundStyle(Color.brand.primary)
                        Text(reviewItem.reviewItemType.displayName)
                            .font(.subheadline)
                    }
                }
            }

            // 来源
            InfoCard(title: "来源", icon: "folder.fill") {
                HStack {
                    Image(systemName: reviewItem.source.icon)
                        .foregroundStyle(Color.brand.secondary)
                    Text(reviewItem.source.displayName)
                        .font(.subheadline)
                }
            }

            // 错误类型（仅当不是默认值时显示）
            if reviewItem.errorType != .other {
                InfoCard(title: "错误原因", icon: "exclamationmark.triangle.fill") {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            Image(systemName: reviewItem.errorType.icon)
                                .foregroundStyle(reviewItem.errorType.color)
                            Text(reviewItem.errorType.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text(reviewItem.errorType.suggestion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 掌握度
            InfoCard(title: String(localized: "detail_mastery_level"), icon: "chart.line.uptrend.xyaxis") {
                HStack {
                    masteryBadge
                    Spacer()
                    Text(String(format: String(localized: "detail_review_count"), reviewItem.reviewCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 知识点
            if !reviewItem.knowledgePoints.isEmpty {
                InfoCard(title: String(localized: "detail_knowledge_points"), icon: "lightbulb.fill") {
                    FlowLayout(spacing: DesignTokens.Spacing.sm) {
                        ForEach(reviewItem.knowledgePoints.items, id: \.self) { point in
                            Text(point)
                                .font(.caption)
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                                .padding(.vertical, DesignTokens.Spacing.xs)
                                .background(Color.brand.primary.opacity(0.1))
                                .foregroundStyle(Color.brand.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // 笔记
            if !reviewItem.note.isEmpty {
                InfoCard(title: "笔记/解题思路", icon: "note.text") {
                    Text(reviewItem.note)
                        .font(.body)
                }
            }

            // 时间信息
            InfoCard(title: "时间信息", icon: "clock.fill") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    timeRow(label: "创建时间：", date: reviewItem.createdAt)
                    timeRow(label: "更新时间：", date: reviewItem.updatedAt)
                    timeRow(label: "下次复习：", date: reviewItem.nextReviewDate)
                }
            }
        }
    }

    // MARK: - Private Views

    private var masteryBadge: some View {
        let level = MasteryLevel(rawValue: reviewItem.masteryLevel) ?? .none
        return HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: level.icon)
            Text(level.detailText)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(level.color.opacity(0.1))
        .foregroundStyle(level.color)
        .clipShape(Capsule())
    }

    private func timeRow(label: String, date: Date) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Text(date, style: .date)
        }
        .font(.caption)
    }
}

// MARK: - EditingContent

/// 编辑模式内容
/// 使用 ReviewItemModel 进行双向绑定编辑
struct EditingContent: View {

    @Bindable var model: ReviewItemModel
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // 标题编辑
            FormField(title: "标题", icon: "text.alignleft") {
                TextField("标题", text: $model.title)
                    .textFieldStyle(.plain)
                    .padding(DesignTokens.Spacing.lg)
                    .background(Color.semantic.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            }

            // 学科和年级
            HStack(spacing: DesignTokens.Spacing.md) {
                FormField(title: "学科", icon: "book.fill") {
                    subjectPicker
                }

                FormField(title: "年级", icon: "graduationcap.fill") {
                    gradePicker
                }
            }

            // 难度和题型
            HStack(spacing: DesignTokens.Spacing.md) {
                FormField(title: "难度", icon: "star.fill") {
                    difficultyPicker
                }

                FormField(title: "题型", icon: "doc.text.fill") {
                    reviewItemTypePicker
                }
            }

            // 来源
            FormField(title: "来源", icon: "folder.fill") {
                sourcePicker
            }

            // 错误原因
            FormField(title: "错误原因", icon: "exclamationmark.triangle.fill") {
                errorTypePicker
            }

            // 知识点编辑
            FormField(title: "知识点", icon: "lightbulb.fill") {
                TextField("例如: 函数, 导数", text: $model.knowledgePointsRaw)
                    .textFieldStyle(.plain)
                    .padding(DesignTokens.Spacing.lg)
                    .background(Color.semantic.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            }

            // 笔记编辑
            FormField(title: "笔记/解题思路", icon: "note.text") {
                TextField("记录解题思路、易错点等...", text: $model.note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(5...10)
                    .padding(DesignTokens.Spacing.lg)
                    .background(Color.semantic.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            }

            // 保存按钮
            saveButton
        }
    }

    // MARK: - Private Views
    
    /// 当前难度（从 raw 值转换）
    private var currentDifficulty: Difficulty {
        Difficulty(rawValue: model.difficultyRaw) ?? .medium
    }
    
    /// 当前题型
    private var currentReviewItemType: ReviewItemType {
        ReviewItemType(rawValue: model.reviewItemTypeRaw) ?? .other
    }
    
    /// 当前来源
    private var currentSource: Source {
        Source(rawValue: model.sourceRaw) ?? .other
    }
    
    /// 当前错误类型
    private var currentErrorType: ErrorType {
        ErrorType(rawValue: model.errorTypeRaw) ?? .other
    }

    private var subjectPicker: some View {
        Menu {
            ForEach(EducationSystemManager.shared.currentSystem.subjectIds, id: \.self) { id in
                if let subject = Subject(rawValue: id) {
                    Button(EducationSystemManager.shared.subjectDisplayName(for: id)) {
                        model.subjectRaw = subject.rawValue
                    }
                }
            }
        } label: {
            pickerLabel(text: EducationSystemManager.shared.subjectDisplayName(for: model.subjectRaw))
        }
    }

    private var gradePicker: some View {
        Menu {
            ForEach(EducationSystemManager.shared.currentSystem.gradeIds, id: \.self) { id in
                if let grade = Grade(rawValue: id) {
                    Button(EducationSystemManager.shared.gradeDisplayName(for: id)) {
                        model.gradeRaw = grade.rawValue
                    }
                }
            }
        } label: {
            pickerLabel(text: EducationSystemManager.shared.gradeDisplayName(for: model.gradeRaw))
        }
    }

    private var difficultyPicker: some View {
        Menu {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                Button {
                    model.difficultyRaw = difficulty.rawValue
                } label: {
                    Label(difficulty.displayName, systemImage: difficulty.icon)
                }
            }
        } label: {
            pickerLabel(text: currentDifficulty.displayName)
        }
    }

    private var reviewItemTypePicker: some View {
        Menu {
            ForEach(ReviewItemType.allCases, id: \.self) { type in
                Button {
                    model.reviewItemTypeRaw = type.rawValue
                } label: {
                    Label(type.displayName, systemImage: type.icon)
                }
            }
        } label: {
            pickerLabel(text: currentReviewItemType.displayName)
        }
    }

    private var sourcePicker: some View {
        Menu {
            ForEach(Source.allCases, id: \.self) { source in
                Button {
                    model.sourceRaw = source.rawValue
                } label: {
                    Label(source.displayName, systemImage: source.icon)
                }
            }
        } label: {
            pickerLabel(text: currentSource.displayName)
        }
    }

    private var errorTypePicker: some View {
        Menu {
            // 按分类分组显示
            ForEach(ErrorCategory.allCases, id: \.self) { category in
                Section {
                    ForEach(ErrorType.types(in: category), id: \.self) { errorType in
                        Button {
                            model.errorTypeRaw = errorType.rawValue
                        } label: {
                            Label(errorType.displayName, systemImage: errorType.icon)
                        }
                    }
                } header: {
                    Text(category.displayName)
                }
            }
        } label: {
            pickerLabel(text: currentErrorType.displayName, color: currentErrorType.color)
        }
    }

    private func pickerLabel(text: String, color: Color? = nil) -> some View {
        HStack {
            Text(text)
                .foregroundStyle(color ?? .primary)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }

    private var saveButton: some View {
        Button(action: onSave) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("detail_save_changes")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [Color.brand.primary, Color.brand.primary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(DesignTokens.Shadow.medium)
        }
        .accessibleButton("保存修改")
    }
}

// MARK: - FormField

/// 表单字段组件
struct FormField<Content: View>: View {

    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            content
        }
    }
}
