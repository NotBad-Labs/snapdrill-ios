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
        .navigationTitle("detail_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert("detail_delete_confirm_title", isPresented: $showDeleteAlert) {
            Button("common_cancel", role: .cancel) {}
            Button("common_delete", role: .destructive) { deleteItem() }
        } message: {
            Text("detail_delete_confirm_message")
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
                        isEditing ? String(localized: "detail_finish_editing") : String(localized: "detail_edit"),
                        systemImage: isEditing ? "checkmark" : "pencil"
                    )
                }

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("common_delete", systemImage: "trash")
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
