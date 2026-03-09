//
//  ImageStorage.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  图片存储服务，负责将图片持久化到本地文件系统。
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
// 非 iOS 平台编译 stub（swift test 使用）。
// struct 天然满足 Sendable，无需 @unchecked 绕过编译器检查。
public struct UIImage: Sendable {
    public init?(data: Data) { return nil }
    public init?(contentsOfFile: String) { return nil }
    public func jpegData(compressionQuality: Double) -> Data? { return nil }
}
#endif

/// 图片存储服务
///
/// 负责将图片数据持久化到应用的沙盒目录 (`Documents/images/`)。
/// 该服务只处理文件 I/O，不涉及业务逻辑。
///
/// ## 目录结构
/// 所有图片都存储在 Documents 目录下的 `images` 子目录中：
/// ```text
/// AppSandbox/
/// └── Documents/
///     └── images/
///         ├── <UUID>.jpg
///         └── ...
/// ```
public struct ImageStorage: Sendable {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    /// 保存图片到本地
    ///
    /// 将 UIImage 压缩为 JPEG 格式并异步写入磁盘。
    ///
    /// - Parameter image: 要保存的原始图片对象
    /// - Returns: 图片的相对路径 (例如 `"images/123-abc.jpg"`)，可用于后续存入数据库
    /// - Throws: `ImageStorageError` 如果图片数据转换失败或文件写入失败
    public func saveImage(_ image: UIImage) async throws -> String {
        let resized = Self.resizedIfNeeded(image, maxLongSide: 2000)
        guard let data = resized.jpegData(compressionQuality: 0.8) else {
            throw ImageStorageError.invalidImageData
        }
        
        return try await Task.detached {
            // Ensure directory exists
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imagesDirectory = documentsURL.appendingPathComponent("images")
            
            if !fileManager.fileExists(atPath: imagesDirectory.path) {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            }
            
            // Generate filename
            let filename = UUID().uuidString + ".jpg"
            let fileURL = imagesDirectory.appendingPathComponent(filename)
            
            // Write to disk
            try data.write(to: fileURL)
            
            return "images/" + filename
        }.value
    }
    
    /// 删除本地图片
    ///
    /// Apple 官方文档明确要求文件 I/O 必须异步执行，避免阻塞主线程。
    /// 与 `saveImage` 保持一致，通过 `Task.detached` 在后台线程执行文件删除。
    ///
    /// - Parameter path: 图片的相对路径 (e.g., "images/xyz.jpg")
    /// - Throws: 文件删除失败时抛出 FileManager 错误；文件不存在时静默返回
    public func deleteImage(path: String) async throws {
        try await Task.detached {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(path)
            guard fileManager.fileExists(atPath: fileURL.path) else { return }
            try fileManager.removeItem(at: fileURL)
        }.value
    }

    /// 从本地加载图片
    /// - Parameter path: 图片的相对路径 (e.g., "images/xyz.jpg")
    /// - Returns: 加载的 UIImage，如果失败返回 nil
    public func loadImage(path: String) -> UIImage? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(path)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        return UIImage(contentsOfFile: fileURL.path)
    }

    // MARK: - Private Helpers

    #if canImport(UIKit)
    /// 长边物理像素超过 maxLongSide 时等比缩放，否则原图返回
    ///
    /// - Note: 使用 `format.scale = 1.0` 确保按物理像素而非逻辑点渲染，
    ///   避免 UIGraphicsImageRenderer 默认使用屏幕 scale（@3x）导致图片反而放大。
    static func resizedIfNeeded(_ image: UIImage, maxLongSide: CGFloat) -> UIImage {
        // 计算物理像素尺寸（image.size 是逻辑点，需乘以 scale）
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longSide = max(pixelWidth, pixelHeight)
        guard longSide > maxLongSide else { return image }

        let ratio = maxLongSide / longSide
        let newSize = CGSize(width: pixelWidth * ratio, height: pixelHeight * ratio)

        // scale = 1.0：输出尺寸即物理像素，不受屏幕 scale 影响
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #else
    /// 非 UIKit 平台 stub，直接返回原图
    static func resizedIfNeeded(_ image: UIImage, maxLongSide: CGFloat) -> UIImage {
        image
    }
    #endif
}

/// 图片存储操作错误
public enum ImageStorageError: Error {
    /// 无法将 UIImage 转换为 JPEG 数据（通常表示图片对象已损坏）
    case invalidImageData
}
