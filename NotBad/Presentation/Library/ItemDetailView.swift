//
//  ItemDetailView.swift
//  NotBad
//
//  错题详情页 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: ReviewItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 图片预览
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                }
                
                // 信息卡片
                if isEditing {
                    editingContent
                } else {
                    displayContent
                }
            }
            .padding()
        }
        .navigationTitle("错题详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isEditing.toggle()
                    } label: {
                        Label(isEditing ? "完成编辑" : "编辑", systemImage: isEditing ? "checkmark" : "pencil")
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
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("确定要删除这道错题吗？此操作无法撤销。")
        }
    }
    
    // MARK: - 显示模式
    
    private var displayContent: some View {
        VStack(spacing: 20) {
            // 标题
            InfoCard(title: "标题", icon: "text.alignleft") {
                Text(item.title)
                    .font(.headline)
            }
            
            // 学科和年级
            HStack(spacing: 12) {
                InfoCard(title: "学科", icon: "book.fill") {
                    Text(item.subject)
                        .font(.subheadline)
                }
                
                InfoCard(title: "年级", icon: "graduationcap.fill") {
                    Text(item.grade)
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
            
            // 标签
            if !item.tags.isEmpty {
                InfoCard(title: "知识点标签", icon: "tag.fill") {
                    Text(item.tags)
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
                    HStack {
                        Text("创建时间：")
                            .foregroundStyle(.secondary)
                        Text(item.createdAt, style: .date)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("更新时间：")
                            .foregroundStyle(.secondary)
                        Text(item.updatedAt, style: .date)
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    // MARK: - 编辑模式
    
    private var editingContent: some View {
        VStack(spacing: 20) {
            // 标题编辑
            VStack(alignment: .leading, spacing: 8) {
                Label("标题", systemImage: "text.alignleft")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("标题", text: $item.title)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 学科和年级
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("学科", systemImage: "book.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        ForEach(["语文", "数学", "英语", "物理", "化学", "生物", "历史", "地理", "政治", "其他"], id: \.self) { subject in
                            Button(subject) {
                                item.subject = subject
                            }
                        }
                    } label: {
                        HStack {
                            Text(item.subject)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(.primary)
                        .padding()
                        .background(.background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("年级", systemImage: "graduationcap.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        ForEach(["小学", "七年级", "八年级", "九年级", "高一", "高二", "高三", "大学", "成人"], id: \.self) { grade in
                            Button(grade) {
                                item.grade = grade
                            }
                        }
                    } label: {
                        HStack {
                            Text(item.grade)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(.primary)
                        .padding()
                        .background(.background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            // 标签编辑
            VStack(alignment: .leading, spacing: 8) {
                Label("知识点标签", systemImage: "tag.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("例如: 函数, 导数", text: $item.tags)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 笔记编辑
            VStack(alignment: .leading, spacing: 8) {
                Label("笔记/解题思路", systemImage: "note.text")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("记录解题思路、易错点等...", text: $item.note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(5...10)
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 保存按钮
            Button {
                saveChanges()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("保存修改")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
            }
        }
    }
    
    // MARK: - 辅助视图
    
    private var masteryBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: masteryIcon)
            Text(masteryText)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(masteryColor.opacity(0.1))
        .foregroundStyle(masteryColor)
        .clipShape(Capsule())
    }
    
    private var masteryIcon: String {
        switch item.masteryLevel {
        case 3: return "checkmark.seal.fill"
        case 2: return "checkmark.circle.fill"
        case 1: return "questionmark.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
    
    private var masteryText: String {
        switch item.masteryLevel {
        case 3: return "已掌握"
        case 2: return "熟悉"
        case 1: return "模糊"
        default: return "不会"
        }
    }
    
    private var masteryColor: Color {
        switch item.masteryLevel {
        case 3: return .green
        case 2: return .mint
        case 1: return .orange
        default: return .red
        }
    }
    
    // MARK: - 逻辑处理
    
    private func saveChanges() {
        withAnimation {
            item.updatedAt = Date()
            try? modelContext.save()
            isEditing = false
        }
    }
    
    private func deleteItem() {
        modelContext.delete(item)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - 信息卡片组件

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
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

#Preview {
    NavigationStack {
        ItemDetailView(item: ReviewItem(
            imageData: nil,
            title: "数学-三角函数",
            note: "这是解题思路",
            subject: "数学",
            grade: "高一",
            tags: "函数, 三角"
        ))
        .modelContainer(for: ReviewItem.self, inMemory: true)
    }
}
