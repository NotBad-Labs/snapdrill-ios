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
        VStack(spacing: 20) {
            // 标题
            InfoCard(title: "标题", icon: "text.alignleft") {
                Text(item.title)
                    .font(.headline)
            }
            
            // 学科和年级
            HStack(spacing: 12) {
                InfoCard(title: "学科", icon: "book.fill") {
                    Text(item.subject.displayName)
                        .font(.subheadline)
                }
                
                InfoCard(title: "年级", icon: "graduationcap.fill") {
                    Text(item.grade.displayName)
                        .font(.subheadline)
                }
            }
            
            // 掌握度
            InfoCard(title: "掌握程度", icon: "chart.line.uptrend.xyaxis") {
                HStack {
                    masteryBadge
                    Spacer()
                    Text("复习 \(item.reviewCount) 次")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 知识点
            if !item.knowledgePoints.isEmpty {
                InfoCard(title: "知识点", icon: "lightbulb.fill") {
                    Text(item.knowledgePoints.rawValue)
                        .font(.subheadline)
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
                VStack(alignment: .leading, spacing: 8) {
                    timeRow(label: "创建时间：", date: item.createdAt)
                    timeRow(label: "更新时间：", date: item.updatedAt)
                }
            }
        }
    }
    
    // MARK: - Private Views
    
    private var masteryBadge: some View {
        let level = MasteryLevel(rawValue: item.masteryLevel) ?? .none
        return HStack(spacing: 6) {
            Image(systemName: level.icon)
            Text(level.detailText)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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
        VStack(spacing: 20) {
            // 标题编辑
            FormField(title: "标题", icon: "text.alignleft") {
                TextField("标题", text: $item.title)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 学科和年级
            HStack(spacing: 12) {
                FormField(title: "学科", icon: "book.fill") {
                    subjectPicker
                }
                
                FormField(title: "年级", icon: "graduationcap.fill") {
                    gradePicker
                }
            }
            
            // 知识点编辑
            FormField(title: "知识点", icon: "lightbulb.fill") {
                TextField("例如: 函数, 导数", text: $item.knowledgePointsRaw)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 笔记编辑
            FormField(title: "笔记/解题思路", icon: "note.text") {
                TextField("记录解题思路、易错点等...", text: $item.note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(5...10)
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 保存按钮
            saveButton
        }
    }
    
    // MARK: - Private Views
    
    private var subjectPicker: some View {
        Menu {
            ForEach(Subject.allCases, id: \.self) { subject in
                Button(subject.displayName) {
                    item.subject = subject
                }
            }
        } label: {
            pickerLabel(text: item.subject.displayName)
        }
    }
    
    private var gradePicker: some View {
        Menu {
            ForEach(Grade.allCases, id: \.self) { grade in
                Button(grade.displayName) {
                    item.grade = grade
                }
            }
        } label: {
            pickerLabel(text: item.grade.displayName)
        }
    }
    
    private func pickerLabel(text: String) -> some View {
        HStack {
            Text(text)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
        }
        .foregroundStyle(.primary)
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var saveButton: some View {
        Button(action: onSave) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("保存修改")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
    }
}

// MARK: - FormField

/// 表单字段组件
struct FormField<Content: View>: View {
    
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            content
        }
    }
}
