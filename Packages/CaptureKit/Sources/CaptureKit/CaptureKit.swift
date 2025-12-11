// CaptureKit - 录入能力层
//
// 提供完整的错题录入链路：
// - 图片存储与管理 (ImageStorageService)
// - OCR 文字识别 (OCRService)
// - 统一录入服务 (CaptureService)
//
// ## 快速开始
//
// ```swift
// import CaptureKit
//
// // 使用统一服务
// let result = try await CaptureService.shared.process(
//     image: selectedImage,
//     itemId: newItem.id
// )
//
// // 或单独使用 OCR
// let text = try await OCRService.shared.recognizeText(from: image)
//
// // 或单独使用图片存储
// let fileName = ImageStorageService.shared.save(image: image, with: id)
// ```

// Re-export all public types
@_exported import struct Foundation.UUID
@_exported import struct Foundation.URL
@_exported import struct Foundation.Data
