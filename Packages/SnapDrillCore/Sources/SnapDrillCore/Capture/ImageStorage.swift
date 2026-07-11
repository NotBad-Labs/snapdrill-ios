//
//  ImageStorage.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  图片存储服务，负责将图片持久化到本地文件系统。
//

import UIKit
import ImageIO

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

    // MARK: - Properties

    /// 图片存储根目录
    private let baseDirectory: URL

    // MARK: - Initialization

    /// 创建图片存储服务。
    /// - Parameter baseDirectory: 唯一资料库根目录
    nonisolated public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }

    // MARK: - Public API

    /// 保存图片到本地
    ///
    /// 将 UIImage 压缩为 JPEG 格式并异步写入磁盘。
    /// 大图使用 ImageIO 流式下采样，避免 UIGraphicsImageRenderer 的双倍内存峰值。
    ///
    /// - Parameter image: 要保存的原始图片对象
    /// - Returns: 图片的相对路径 (例如 `"images/123-abc.jpg"`)，可用于后续存入数据库
    /// - Throws: `ImageStorageError` 如果图片数据转换失败或文件写入失败
    nonisolated public func saveImage(_ image: UIImage) async throws -> String {
        guard let data = Self.compressedJPEGData(from: image, maxLongSide: 2000, quality: 0.8) else {
            throw ImageStorageError.invalidImageData
        }

        let base = baseDirectory
        return try await Task.detached {
            let fileManager = FileManager.default
            let imagesDirectory = base.appendingPathComponent("images")

            if !fileManager.fileExists(atPath: imagesDirectory.path) {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            }

            let filename = UUID().uuidString + ".jpg"
            let fileURL = imagesDirectory.appendingPathComponent(filename)
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
    nonisolated public func deleteImage(path: String) async throws {
        guard Self.isSafeRelativeImagePath(path) else {
            SnapDrillLogger.generic.warning("跳过非法图片删除路径: \(path)")
            return
        }
        let base = baseDirectory
        try await Task.detached {
            let fileManager = FileManager.default
            let fileURL = base.appendingPathComponent(path)
            guard fileManager.fileExists(atPath: fileURL.path) else { return }
            try fileManager.removeItem(at: fileURL)
        }.value
    }

    /// 从本地加载图片（同步）
    ///
    /// 仅用于必须同步的上下文（如 UIGraphicsPDFRenderer 闭包）。
    /// SwiftUI View 中请使用 `loadImageAsync(path:)` 避免阻塞主线程。
    ///
    /// - Parameter path: 图片的相对路径 (e.g., "images/xyz.jpg")
    /// - Returns: 加载的 UIImage，如果失败返回 nil
    nonisolated public func loadImage(path: String) -> UIImage? {
        guard Self.isSafeRelativeImagePath(path) else { return nil }
        let fileManager = FileManager.default
        let fileURL = baseDirectory.appendingPathComponent(path)

        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        return UIImage(contentsOfFile: fileURL.path)
    }

    /// 返回已保存图片的文件 URL（不解码图片）。
    ///
    /// 供批量 ZIP 导出等文件级操作使用，避免把已脱敏的存盘 JPEG 解码成 `UIImage`
    /// 再重新编码，降低大批量导出的内存峰值。
    nonisolated public func imageFileURL(path: String) -> URL? {
        guard Self.isSafeRelativeImagePath(path) else { return nil }
        let fileURL = baseDirectory.appendingPathComponent(path)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return fileURL
    }

    /// 从本地加载图片（异步，后台线程）
    ///
    /// 在 `Task.detached` 中执行磁盘 I/O，避免阻塞主线程。
    /// SwiftUI View 中应通过 `.task` + `@State` 配合使用。
    ///
    /// - Parameter path: 图片的相对路径 (e.g., "images/xyz.jpg")
    /// - Returns: 加载的 UIImage，如果失败返回 nil
    nonisolated public func loadImageAsync(path: String) async -> UIImage? {
        await Task.detached(priority: .userInitiated) { [self] in
            self.loadImage(path: path)
        }.value
    }

    /// 从本地加载降采样图片（同步，ImageIO 流式解码）
    ///
    /// 使用 `CGImageSourceCreateThumbnailAtIndex` 流式解码，
    /// 不将全分辨率位图加载到内存（12MP JPEG ~48MB 位图 → 降采样后 ~2MB）。
    /// 适用于 PDF 导出等需要同步访问但不需要全分辨率的场景。
    ///
    /// - Parameters:
    ///   - path: 图片的相对路径 (e.g., "images/xyz.jpg")
    ///   - maxLongSide: 长边像素上限（默认 1200，A4 150dpi 足够）
    /// - Returns: 降采样后的 UIImage，失败时回退到 `loadImage(path:)`
    nonisolated public func loadDownsampledImage(path: String, maxLongSide: Int = 1200) -> UIImage? {
        guard Self.isSafeRelativeImagePath(path) else { return nil }
        let fileManager = FileManager.default
        let fileURL = baseDirectory.appendingPathComponent(path)

        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxLongSide
        ]

        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            // ImageIO 失败时回退到全分辨率加载（可能导致内存峰值偏高）
            SnapDrillLogger.generic.warning("ImageIO 降采样失败，回退到全分辨率加载: \(path)")
            return UIImage(contentsOfFile: fileURL.path)
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - 存储统计

    /// 计算图片目录的总占用字节数
    public func imageDirectorySize() async -> Int64 {
        let imagesDir = baseDirectory.appendingPathComponent("images")
        return await Task.detached(priority: .utility) {
            Self.directorySize(at: imagesDir)
        }.value
    }

    /// 计算指定目录的总字节数（递归遍历所有文件）
    nonisolated private static func directorySize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize { // best-effort: 获取文件大小失败时跳过，继续统计其余文件
                totalSize += Int64(size)
            }
        }
        return totalSize
    }

    nonisolated public static func isSafeRelativeImagePath(_ path: String) -> Bool {
        guard path.hasPrefix("images/"),
              !path.contains("\\") else {
            return false
        }
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count >= 2, components.first == "images" else { return false }
        return components.allSatisfy { component in
            !component.isEmpty && component != "." && component != ".."
        }
    }

    // MARK: - Private Helpers

    /// 将 UIImage 压缩为 JPEG Data，大图通过 ImageIO 流式下采样
    ///
    /// 内存优化策略：
    /// - 无需缩放时：通过 CGImageDestination 直接从 CGImage 编码（剥离 EXIF GPS）
    /// - 需要缩放时：先编码为 JPEG Data，再通过 ImageIO `CGImageSourceCreateThumbnailAtIndex`
    ///   流式解码为目标尺寸的 CGImage，最后通过 CGImageDestination 编码
    ///   避免 UIGraphicsImageRenderer 同时持有原图位图（~48MB@12MP）+ 缩放画布的双倍峰值
    ///
    /// 安全策略：
    /// - 所有路径统一使用 `jpegDataStrippingLocation` 编码最终输出
    /// - CGImageDestination 从 CGImage 编码时不携带 EXIF 元数据（含 GPS 位置），
    ///   确保产品「零个人信息收集」的隐私承诺在图片层面也成立
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - maxLongSide: 长边物理像素上限
    ///   - quality: JPEG 压缩质量（0.0-1.0）
    /// - Returns: 压缩后的 JPEG Data（不含 GPS 元数据），失败返回 nil
    public nonisolated static func compressedJPEGData(from image: UIImage, maxLongSide: CGFloat, quality: CGFloat) -> Data? {
        // 计算物理像素尺寸（image.size 是逻辑点，需乘以 scale）
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longSide = max(pixelWidth, pixelHeight)

        // 无需缩放：直接从 CGImage 编码（剥离 EXIF GPS）
        guard longSide > maxLongSide else {
            return jpegDataStrippingLocation(from: image.cgImage, quality: quality)
        }

        // 需要缩放：先编码为临时 JPEG Data（仅作为 ImageIO 输入，不作最终输出）
        guard let tempData = image.jpegData(compressionQuality: quality),
              let source = CGImageSourceCreateWithData(tempData as CFData, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxLongSide)
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            // fallback：ImageIO 失败时从原始 CGImage 编码（同样剥离 GPS）
            return jpegDataStrippingLocation(from: image.cgImage, quality: quality)
        }

        // 从下采样的 CGImage 编码最终 JPEG Data（CGImage 不携带 EXIF，天然无 GPS）
        return jpegDataStrippingLocation(from: cgImage, quality: quality)
    }

    /// 从 CGImage 编码 JPEG Data，不包含位置元数据
    ///
    /// CGImage 是纯像素数据容器，不携带 EXIF 元数据（与 UIImage 不同）。
    /// 通过 CGImageDestination 直接从 CGImage 编码，确保输出不含 GPS 经纬度、
    /// 设备型号等隐私敏感的 EXIF 字段。
    ///
    /// - Parameters:
    ///   - cgImage: 源像素数据
    ///   - quality: JPEG 压缩质量（0.0-1.0）
    /// - Returns: 不含位置元数据的 JPEG Data，CGImage 为 nil 时返回 nil
    nonisolated private static func jpegDataStrippingLocation(from cgImage: CGImage?, quality: CGFloat) -> Data? {
        guard let cgImage else { return nil }
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData, "public.jpeg" as CFString, 1, nil
        ) else { return nil }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}

/// 图片存储操作错误
public enum ImageStorageError: Error {
    /// 无法将 UIImage 转换为 JPEG 数据（通常表示图片对象已损坏）
    case invalidImageData
}
