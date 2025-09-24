//
//  PhotoLibraryView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI
import PhotosUI

/// 照片库选择视图
/// 使用PhotosUI选择照片
struct PhotoLibraryView: View {
    @ObservedObject var viewModel: CaptureViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let imageData = selectedImageData,
                   let uiImage = UIImage(data: imageData) {
                    // 显示选中的图片预览
                    VStack(spacing: 20) {
                        Text("选中的照片")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        
                        HStack(spacing: 20) {
                            Button("重新选择") {
                                selectedPhotoItem = nil
                                selectedImageData = nil
                            }
                            .buttonStyle(.bordered)
                            
                            Button("使用此照片") {
                                handleSelectedImage(imageData)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                } else {
                    // 照片选择器
                    VStack(spacing: 30) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("从相册选择照片")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images
                        ) {
                            Text("选择照片")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle("选择照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedPhotoItem) { oldItem, newItem in
            Task {
                if let newItem = newItem {
                    await loadImageData(from: newItem)
                }
            }
        }
    }
    
    /// 加载图片数据
    private func loadImageData(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            print("无法加载图片数据")
            return
        }
        
        await MainActor.run {
            selectedImageData = data
        }
    }
    
    /// 处理选中的图片
    private func handleSelectedImage(_ imageData: Data) {
        // 关闭照片库界面
        dismiss()
        
        // 交由ViewModel处理
        if let image = UIImage(data: imageData) {
            viewModel.handleSelectedImage(image)
        }
    }

#if DEBUG
    // MARK: - Test Hooks (DEBUG only)
    /// 供单元测试直接驱动选择图片处理路径，增加对 View 内部逻辑的覆盖
    func _test_handleSelectedImage(_ data: Data) {
        handleSelectedImage(data)
    }

    /// 供单元测试设置选中图片数据，以便覆盖预览分支
    func _test_setSelectedImageData(_ data: Data?) {
        selectedImageData = data
    }
#endif
}

#Preview {
    let coordinator = CaptureCoordinator()
    let vm = CaptureViewModel(captureUseCase: ServiceContainer.shared.captureReviewItemUseCase, coordinator: coordinator)
    PhotoLibraryView(viewModel: vm)
}