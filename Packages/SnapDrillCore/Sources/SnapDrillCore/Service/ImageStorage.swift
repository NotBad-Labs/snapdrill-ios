//
//  ImageStorage.swift
//  SnapDrillService
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  图片存储服务，负责将图片持久化到本地文件系统。
//

import UIKit

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
    
    public init() {}
    
    /// 保存图片到本地
    ///
    /// 将 UIImage 压缩为 JPEG 格式并异步写入磁盘。
    ///
    /// - Parameter image: 要保存的原始图片对象
    /// - Returns: 图片的相对路径 (例如 `"images/123-abc.jpg"`)，可用于后续存入数据库
    /// - Throws: `ImageStorageError` 如果图片数据转换失败或文件写入失败
    public func saveImage(_ image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
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
}

public enum ImageStorageError: Error {
    case invalidImageData
}
