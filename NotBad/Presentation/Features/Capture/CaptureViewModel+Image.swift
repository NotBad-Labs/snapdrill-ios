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
    /// - Parameter image: 选中的 UIImage
    func handlePickedImage(_ image: UIImage) {
        selectedUIImage = image
        selectedImage = Image(uiImage: image)

        // 使用 ImageCompressor 压缩图片
        selectedImageData = ImageCompressor.compress(image)

        // 更新步骤
        currentStep = .recognize

        // 自动触发 OCR
        if title.isEmpty {
            Task {
                await recognizeText()
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
