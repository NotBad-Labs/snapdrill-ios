//
//  ItemDetailView.swift
//  NotBad
//
//  详情页：查看/编辑/删除错题
//

import SwiftUI
import SwiftData
import ReviewKit

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var item: ReviewItemModel
    @State private var showImagePicker = false
    @State private var showDeleteAlert = false
    @State private var showSourceSheet = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var editedTitle: String
    @State private var editedNote: String
    @State private var editedImage: UIImage?

    init(item: ReviewItemModel) {
        _item = State(initialValue: item)
        _editedTitle = State(initialValue: item.title)
        _editedNote = State(initialValue: item.note)
    }

    var body: some View {
        Form {
            Section("图片") {
                imageSection
            }

            Section("信息") {
                TextField("标题", text: $editedTitle)
                TextField("笔记", text: $editedNote, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("元数据") {
                HStack {
                    Label("学科", systemImage: "book")
                    Spacer()
                    Text(item.subject.displayName)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("难度", systemImage: "chart.bar")
                    Spacer()
                    Text("\(item.difficulty.rawValue)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("掌握度", systemImage: "checkmark.circle")
                    Spacer()
                    Text("\(item.masteryLevel)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("下次复习", systemImage: "calendar")
                    Spacer()
                    Text(item.nextReviewDate.formatted(date: .abbreviated, time: .omitted))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    saveChanges()
                } label: {
                    Label("保存修改", systemImage: "square.and.arrow.down.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(editedTitle.isEmpty && editedNote.isEmpty && editedImage == nil)

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("删除错题", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("详情")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $editedImage, sourceType: imageSource, allowsEditing: true)
        }
        .confirmationDialog("选择图片来源", isPresented: $showSourceSheet) {
            Button("拍照") { presentPicker(.camera) }
            Button("从相册选择") { presentPicker(.photoLibrary) }
            Button("取消", role: .cancel) {}
        }
        .alert("确认删除？", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) { deleteItem() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后不可恢复。")
        }
        .onChange(of: editedImage) { _, newImage in
            if let image = newImage {
                item.imagePath = ImageStorageService.shared.save(image: image, with: item.id)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var imageSection: some View {
        if let image = editedImage ?? ImageStorageService.shared.load(fileName: item.imagePath) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture { showSourceSheet = true }
        } else {
            Button {
                showSourceSheet = true
            } label: {
                Label("添加图片", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        item.title = editedTitle.isEmpty ? item.title : editedTitle
        item.note = editedNote
        item.markAsUpdated()
        dismiss()
    }

    private func deleteItem() {
        modelContext.delete(item)
        dismiss()
    }

    private func presentPicker(_ source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
        imageSource = source
        showImagePicker = true
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(item: ReviewItemModel(title: "测试题目", note: "笔记"))
            .modelContainer(for: ReviewItemModel.self, inMemory: true)
    }
}
