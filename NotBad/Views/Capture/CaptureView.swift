//
//  CaptureView.swift
//  NotBad
//
//  错题录入视图
//

import SwiftUI

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("图片") {
                    imageSection
                }
                
                Section("信息") {
                    TextField("标题", text: $title)
                }
                
                Section {
                    Button("保存") {
                        saveItem()
                    }
                    .disabled(title.isEmpty && selectedImage == nil)
                }
            }
            .navigationTitle("录入错题")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var imageSection: some View {
        if let image = selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .onTapGesture { showImagePicker = true }
                .accessibilityLabel("已选择的图片")
                .accessibilityHint("点击更换图片")
        } else {
            Button("选择图片") {
                showImagePicker = true
            }
            .accessibilityHint("从相册选择错题图片")
        }
    }
    
    // MARK: - Actions
    
    private func saveItem() {
        let item = ReviewItemModel(title: title)
        
        // 保存图片到磁盘
        if let image = selectedImage {
            item.imagePath = ImageStorageService.shared.save(image: image, with: item.id)
        }
        
        modelContext.insert(item)
        
        // 重置
        title = ""
        selectedImage = nil
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
