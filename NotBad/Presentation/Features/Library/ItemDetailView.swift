//
//  ItemDetailView.swift
//  NotBad
//
//  错题详情页 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData

// MARK: - ItemDetailView

/// 错题详情视图
///
/// 展示和编辑错题的详细信息，包括图片、标题、学科、年级、知识点和笔记。
///
/// ## 功能特性
///
/// - 查看错题完整信息
/// - 编辑错题内容
/// - 删除错题
/// - 显示掌握度和复习次数
///
/// ## 使用示例
///
/// ```swift
/// NavigationStack {
///     ItemDetailView(item: reviewItem)
/// }
/// ```
///
/// ## 设计模式
///
/// - 使用 `@Bindable` 支持双向绑定
/// - 使用 `InfoCard` 组件展示信息
/// - 编辑模式和显示模式分离
struct ItemDetailView: View {
    
    // MARK: - Properties
    
    /// 错题数据（可绑定）
    @Bindable var item: ReviewItem
    
    /// 数据上下文
    @Environment(\.modelContext) private var modelContext
    
    /// 关闭视图
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    /// 是否处于编辑模式
    @State private var isEditing = false
    
    /// 是否显示删除确认
    @State private var showDeleteAlert = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                imagePreview
                
                if isEditing {
                    EditingContent(item: item, onSave: saveChanges)
                } else {
                    DisplayContent(item: item)
                }
            }
            .padding()
        }
        .navigationTitle("错题详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { deleteItem() }
        } message: {
            Text("确定要删除这道错题吗？此操作无法撤销。")
        }
    }
}

// MARK: - Toolbar

private extension ItemDetailView {
    
    /// 工具栏内容
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    isEditing.toggle()
                } label: {
                    Label(
                        isEditing ? "完成编辑" : "编辑",
                        systemImage: isEditing ? "checkmark" : "pencil"
                    )
                }
                
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

// MARK: - Subviews

private extension ItemDetailView {
    
    /// 图片预览
    @ViewBuilder
    var imagePreview: some View {
        if let imageData = item.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        }
    }
}

// MARK: - Actions

private extension ItemDetailView {
    
    /// 保存修改
    func saveChanges() {
        withAnimation {
            item.updatedAt = Date()
            try? modelContext.save()
            isEditing = false
        }
    }
    
    /// 删除错题
    func deleteItem() {
        modelContext.delete(item)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - DisplayContent

/// 显示模式内容
private struct DisplayContent: View {
    
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
private struct EditingContent: View {
    
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
private struct FormField<Content: View>: View {
    
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

// MARK: - InfoCard

/// 信息卡片组件
///
/// 用于展示错题详情的信息卡片。
///
/// ## 使用示例
///
/// ```swift
/// InfoCard(title: "标题", icon: "text.alignleft") {
///     Text("错题标题内容")
/// }
/// ```
struct InfoCard<Content: View>: View {
    
    // MARK: - Properties
    
    /// 卡片标题
    let title: String
    
    /// 图标名称
    let icon: String
    
    /// 卡片内容
    @ViewBuilder let content: Content
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview("Item Detail") {
    NavigationStack {
        ItemDetailView(item: ReviewItem(
            imageData: nil,
            title: "数学-三角函数",
            note: "这是解题思路",
            subject: .math,
            grade: .grade10,
            knowledgePoints: ["函数", "三角"]
        ))
        .modelContainer(for: ReviewItem.self, inMemory: true)
    }
}

#Preview("Info Card") {
    InfoCard(title: "测试标题", icon: "star.fill") {
        Text("测试内容")
    }
    .padding()
}
