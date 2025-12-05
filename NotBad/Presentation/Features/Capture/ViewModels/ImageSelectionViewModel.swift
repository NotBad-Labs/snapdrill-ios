//
//  ImageSelectionViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import Observation
import SwiftUI
import PhotosUI

// MARK: - ImageSelectionViewModel

/// 图片选择视图模型
///
/// 负责处理图片选择、压缩、滤镜等操作。
@MainActor
@Observable
final class ImageSelectionViewModel {
    
    // MARK: - State
    
    /// 选中的 PhotosPickerItem
    var selectedItem: PhotosPickerItem?
    
    /// 显示用的 Image
    var selectedImage: Image?
    
    /// 原始 UIImage
    var selectedUIImage: UIImage?
    
    /// 压缩后的图片数据
    var selectedImageData: Data?
    
    /// 是否正在处理图片
    var isProcessing: Bool = false
    
    /// 是否显示相机
    var showCamera: Bool = false
    
    /// 是否显示实时扫描仪
    var showLiveScanner: Bool = false
    
    /// 是否来自实时扫描仪
    var isFromLiveScanner: Bool = false
    
    // MARK: - Actions
    
    /// 处理从相册选择的 Item
    func loadTransferable(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                handlePickedImage(uiImage)
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
    
    /// 处理选中的 UIImage (来自相册、相机或扫描仪)
    func handlePickedImage(_ image: UIImage) {
        self.selectedUIImage = image
        self.selectedImage = Image(uiImage: image)
        
        // 后台压缩图片
        Task.detached(priority: .userInitiated) {
            // 压缩为 JPEG，质量 0.7
            if let data = image.jpegData(compressionQuality: 0.7) {
                await MainActor.run {
                    self.selectedImageData = data
                }
            }
        }
    }
    
    /// 重置状态
    func reset() {
        selectedItem = nil
        selectedImage = nil
        selectedUIImage = nil
        selectedImageData = nil
        isProcessing = false
        isFromLiveScanner = false
    }
}
