//
//  CaptureViewModel+Image.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import PhotosUI
import SwiftUI

// MARK: - Image Actions

extension CaptureViewModel {
    /// 处理选中的图片
    ///
    /// 图片压缩在后台线程执行，避免阻塞主线程导致 UI 卡顿。
    /// 对于 4K/1200 万像素照片，压缩操作可能耗时 0.5-2 秒。
    ///
    /// - Parameter image: 选中的 UIImage
    func handlePickedImage(_ image: UIImage) {
        // 立即更新预览（UIImage -> Image 转换很快）
        selectedUIImage = image
        selectedImage = Image(uiImage: image)
        
        // 显示加载状态
        isProcessingImage = true
        
        // 在后台线程执行 JPEG 压缩
        Task.detached(priority: .userInitiated) { [weak self] in
            // 压缩图片（耗时操作）
            let compressedData = ImageCompressor.compress(image)
            
            // 回到主线程更新状态
            await MainActor.run { [weak self] in
                guard let self else { return }
                
                self.selectedImageData = compressedData
                self.isProcessingImage = false
                
                // 更新步骤
                self.currentStep = .recognize
                
                // 自动触发 OCR
                if self.title.isEmpty {
                    Task {
                        await self.recognizeText()
                    }
                }
            }
        }
    }

    /// 从 PhotosPicker 加载图片
    func loadTransferable(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        handlePickedImage(uiImage)
    }

    /// 清除已选图片
    func clearImage() {
        selectedItem = nil
        selectedImage = nil
        selectedImageData = nil
        selectedUIImage = nil
        currentStep = .selectImage
    }
}
