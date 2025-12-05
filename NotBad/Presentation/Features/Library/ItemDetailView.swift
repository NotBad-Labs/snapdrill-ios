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
///     ItemDetailView(model: reviewItemModel)
/// }
/// ```
///
/// ## 设计模式
///
/// - 使用 `@Bindable` 绑定 ReviewItemModel (SwiftData)
/// - 通过 ReviewItemMapper 转换为领域实体 ReviewItem 用于只读展示
/// - 使用 `ViewModel` 处理写操作（CQRS）
/// - 编辑模式和显示模式分离
struct ItemDetailView: View {

    // MARK: - Properties

    /// 持久化模型（SwiftData）
    @Bindable var model: ReviewItemModel
    
    /// 领域实体（只读，用于展示）
    private var reviewItem: ReviewItem {
        ReviewItemMapper.toEntity(from: model)
    }

    /// 依赖工厂
    @Environment(\.dependencyFactory) private var dependencyFactory

    /// 关闭视图
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    
    /// ViewModel（处理写操作）
    @State private var viewModel = ItemDetailViewModel()

    /// 是否处于编辑模式
    @State private var isEditing = false

    /// 是否显示删除确认
    @State private var showDeleteAlert = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                imagePreview

                if isEditing {
                    EditingContent(model: model, onSave: saveChanges)
                } else {
                    DisplayContent(reviewItem: reviewItem)
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
        .onAppear {
            if let factory = dependencyFactory {
                viewModel.configure(with: factory)
            }
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
        if let imageData = model.imageData,
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

    /// 保存修改（委托给 ViewModel）
    func saveChanges() {
        withAnimation {
            // 从模型同步到领域实体再保存
            let entity = ReviewItemMapper.toEntity(from: model)
            viewModel.save(entity)
            isEditing = false
        }
    }

    /// 删除错题（委托给 ViewModel）
    func deleteItem() {
        let entity = ReviewItemMapper.toEntity(from: model)
        viewModel.delete(entity)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Item Detail") {
    let model = ReviewItemModel(
        imageData: nil,
        title: "数学-三角函数",
        note: "这是解题思路",
        subjectRaw: Subject.math.rawValue,
        gradeRaw: Grade.grade10.rawValue,
        knowledgePointsRaw: "函数,三角"
    )
    NavigationStack {
        ItemDetailView(model: model)
            .modelContainer(for: ReviewItemModel.self, inMemory: true)
    }
}
