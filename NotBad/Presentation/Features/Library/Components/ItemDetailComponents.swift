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

    let item: ReviewItem

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // 标题
            InfoCard(title: "标题", icon: "text.alignleft") {
                Text(item.title)
                    .font(.headline)
            }

            // 学科和年级
            HStack(spacing: DesignTokens.Spacing.md) {
                InfoCard(title: "学科", icon: "book.fill") {
                    HStack {
                        Image(systemName: item.subject.icon)
                            .foregroundStyle(item.subject.color)
                        Text(item.subject.displayName)
                            .font(.subheadline)
                    }
                }

                InfoCard(title: "年级", icon: "graduationcap.fill") {
                    Text(item.grade.displayName)
                        .font(.subheadline)
                }
            }

            // 难度和题型
            HStack(spacing: DesignTokens.Spacing.md) {
                InfoCard(title: "难度", icon: "star.fill") {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < item.difficulty.rawValue ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(item.difficulty.color)
                        }
                    }
                }

                InfoCard(title: "题型", icon: "doc.text.fill") {
                    HStack {
                        Image(systemName: item.questionType.icon)
                            .foregroundStyle(Color.brand.primary)
                        Text(item.questionType.displayName)
                            .font(.subheadline)
                    }
                }
            }

            // 来源
            InfoCard(title: "来源", icon: "folder.fill") {
                HStack {
                    Image(systemName: item.source.icon)
                        .foregroundStyle(Color.brand.secondary)
                    Text(item.source.displayName)
                        .font(.subheadline)
                }
            }

            // 掌握度
            InfoCard(title: String(localized: "detail_mastery_level"), icon: "chart.line.uptrend.xyaxis") {
                HStack {
                    masteryBadge
                    Spacer()
                    Text(String(format: String(localized: "detail_review_count"), item.reviewCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 知识点
            if !item.knowledgePoints.isEmpty {
                InfoCard(title: String(localized: "detail_knowledge_points"), icon: "lightbulb.fill") {
                    FlowLayout(spacing: DesignTokens.Spacing.sm) {
                        ForEach(item.knowledgePoints.items, id: \.self) { point in
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
            if !item.note.isEmpty {
                InfoCard(title: "笔记/解题思路", icon: "note.text") {
                    Text(item.note)
                        .font(.body)
                }
            }

            // 时间信息
            InfoCard(title: "时间信息", icon: "clock.fill") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    timeRow(label: "创建时间：", date: item.createdAt)
                    timeRow(label: "更新时间：", date: item.updatedAt)
                    timeRow(label: "下次复习：", date: item.nextReviewDate)
                }
            }
        }
    }

    // MARK: - Private Views

    private var masteryBadge: some View {
        let level = MasteryLevel(rawValue: item.masteryLevel) ?? .none
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
struct EditingContent: View {

    @Bindable var item: ReviewItem
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // 标题编辑
            FormField(title: "标题", icon: "text.alignleft") {
                TextField("标题", text: $item.title)
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
                    questionTypePicker
                }
            }

            // 来源
            FormField(title: "来源", icon: "folder.fill") {
                sourcePicker
            }

            // 知识点编辑
            FormField(title: "知识点", icon: "lightbulb.fill") {
                TextField("例如: 函数, 导数", text: $item.knowledgePointsRaw)
                    .textFieldStyle(.plain)
                    .padding(DesignTokens.Spacing.lg)
                    .background(Color.semantic.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            }

            // 笔记编辑
            FormField(title: "笔记/解题思路", icon: "note.text") {
                TextField("记录解题思路、易错点等...", text: $item.note, axis: .vertical)
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

    private var subjectPicker: some View {
        Menu {
            ForEach(EducationSystemManager.shared.currentSystem.subjectIds, id: \.self) { id in
                if let subject = Subject(rawValue: id) {
                    Button(EducationSystemManager.shared.subjectDisplayName(for: id)) {
                        item.subject = subject
                    }
                }
            }
        } label: {
            pickerLabel(text: EducationSystemManager.shared.subjectDisplayName(for: item.subjectRaw))
        }
    }

    private var gradePicker: some View {
        Menu {
            ForEach(EducationSystemManager.shared.currentSystem.gradeIds, id: \.self) { id in
                if let grade = Grade(rawValue: id) {
                    Button(EducationSystemManager.shared.gradeDisplayName(for: id)) {
                        item.grade = grade
                    }
                }
            }
        } label: {
            pickerLabel(text: EducationSystemManager.shared.gradeDisplayName(for: item.gradeRaw))
        }
    }

    private var difficultyPicker: some View {
        Menu {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                Button {
                    item.difficulty = difficulty
                } label: {
                    Label(difficulty.displayName, systemImage: difficulty.icon)
                }
            }
        } label: {
            pickerLabel(text: item.difficulty.displayName, color: item.difficulty.color)
        }
    }

    private var questionTypePicker: some View {
        Menu {
            ForEach(ReviewItemType.allCases, id: \.self) { type in
                Button {
                    item.questionType = type
                } label: {
                    Label(type.displayName, systemImage: type.icon)
                }
            }
        } label: {
            pickerLabel(text: item.questionType.displayName)
        }
    }

    private var sourcePicker: some View {
        Menu {
            ForEach(Source.allCases, id: \.self) { source in
                Button {
                    item.source = source
                } label: {
                    Label(source.displayName, systemImage: source.icon)
                }
            }
        } label: {
            pickerLabel(text: item.source.displayName)
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
