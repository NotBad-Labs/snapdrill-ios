//
//  ImageCompressor.swift
//  NotBad
//
//  图片压缩工具
//

import UIKit

// MARK: - ImageCompressor

/// 图片压缩工具
///
/// 提供图片压缩和缩放功能，用于优化存储空间。
///
/// ## 使用示例
///
/// ```swift
/// let image = UIImage(named: "photo")!
/// if let data = ImageCompressor.compress(image) {
///     // 使用压缩后的数据
/// }
/// ```
///
/// ## 压缩策略
///
/// 1. **尺寸限制**：超过最大尺寸时等比缩放
/// 2. **质量压缩**：使用 JPEG 压缩，默认质量 0.7
///
/// - Note: 使用 `enum` 实现单例模式，避免实例化
enum ImageCompressor {
    
    // MARK: - Configuration
    
    /// 默认压缩质量（0.0-1.0）
    static let defaultQuality: CGFloat = 0.7
    
    /// 默认最大尺寸（像素）
    static let defaultMaxDimension: CGFloat = 2048
    
    // MARK: - Public API
    
    /// 压缩图片
    ///
    /// 如果图片尺寸超过最大限制，会先等比缩放再压缩。
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - quality: JPEG 压缩质量，默认 0.7
    ///   - maxDimension: 最大边长（像素），默认 2048
    /// - Returns: 压缩后的 JPEG 数据，失败返回 nil
    static func compress(
        _ image: UIImage,
        quality: CGFloat = defaultQuality,
        maxDimension: CGFloat = defaultMaxDimension
    ) -> Data? {
        let resized = resize(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: quality)
    }
    
    /// 仅缩放图片（不压缩）
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - maxDimension: 最大边长（像素）
    /// - Returns: 缩放后的图片
    static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // 如果尺寸已在限制内，直接返回
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        // 计算缩放比例
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        
        // 使用现代 API 绘制
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// 估算压缩后的文件大小（KB）
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - quality: 压缩质量
    /// - Returns: 估算的文件大小（KB）
    static func estimateSize(_ image: UIImage, quality: CGFloat = defaultQuality) -> Int {
        guard let data = image.jpegData(compressionQuality: quality) else { return 0 }
        return data.count / 1024
    }
}
