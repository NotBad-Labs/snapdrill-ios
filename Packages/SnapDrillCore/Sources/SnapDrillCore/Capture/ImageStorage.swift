//
//  ImageStorage.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  图片存储服务，负责将图片持久化到本地文件系统。
//

import Darwin
import ImageIO
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

    typealias ImagePublisher = @Sendable (
        _ bytes: Data,
        _ staging: DurableRegularFilePublisher.RelativeFile,
        _ destination: DurableRegularFilePublisher.RelativeFile,
        _ root: URL
    ) throws -> Void

    // MARK: - Properties

    /// 图片存储根目录（Profile 隔离目录）
    private let baseDirectory: URL
    private let publishImage: ImagePublisher

    // MARK: - Initialization

    /// 创建 Profile 隔离的图片存储服务（生产路径）
    /// - Parameters:
    ///   - baseDirectory: Profile 图片根目录（如 `profiles/<id>/`）
    ///   - scope: Profile 隔离作用域（用于日志/调试）
    nonisolated public init(baseDirectory: URL, scope: ProfileScope) {
        self.baseDirectory = baseDirectory
        publishImage = Self.publishImageLive
    }

    /// 使用显式根目录创建图片存储服务（备份、测试或 Preview 路径）
    /// - Parameter baseDirectory: 图片存储根目录
    nonisolated public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
        publishImage = Self.publishImageLive
    }

    nonisolated init(baseDirectory: URL, publishImage: @escaping ImagePublisher) {
        self.baseDirectory = baseDirectory
        self.publishImage = publishImage
    }

    /// 判断数据库/备份中的图片路径是否为唯一允许的规范格式。
    ///
    /// 仅接受恰好两段的 `images/<filename>.jpg`；文件名不要求 UUID，
    /// 但必须包含 `.jpg` 前的非空名称。
    public nonisolated static func isValidImagePath(_ path: String) -> Bool {
        guard !path.contains("\\"), !path.contains("\0") else { return false }

        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count == 2,
              components[0] == "images" else {
            return false
        }

        let filename = components[1]
        return filename.hasSuffix(".jpg") && filename.dropLast(4).isEmpty == false
    }

    // MARK: - Public API

    /// 保存图片到本地
    ///
    /// 将 UIImage 规范化为 canonical JPEG 并异步、持久地发布到磁盘。
    ///
    /// - Parameter image: 要保存的原始图片对象
    /// - Returns: 图片的相对路径 (例如 `"images/123-abc.jpg"`)，可用于后续存入数据库
    /// - Throws: `ImageStorageError` 如果图片数据转换失败或文件写入失败
    nonisolated public func saveImage(_ image: UIImage) async throws -> String {
        let base = baseDirectory
        let publish = publishImage
        return try await Task.detached {
            let fileManager = FileManager.default
            let data: Data
            do {
                data = try CanonicalJPEG.encode(image)
            } catch {
                throw ImageStorageError.invalidImageData
            }
            _ = try Self.prepareStorageDirectory(base, fileManager: fileManager)
            let identifier = UUID().uuidString.lowercased()
            let filename = identifier + ".jpg"
            let stagingName = "." + identifier + ".staging"
            let staging = try DurableRegularFilePublisher.RelativeFile(
                parentComponents: ["images"],
                fileName: stagingName
            )
            let destination = try DurableRegularFilePublisher.RelativeFile(
                parentComponents: ["images"],
                fileName: filename
            )
            guard let imagesDescriptor = Self.openImagesDirectory(beneath: base) else {
                throw ImageStorageError.publicationFailed
            }
            defer { _ = Darwin.close(imagesDescriptor) }
            guard Self.pathIsAbsent(named: stagingName, in: imagesDescriptor),
                  Self.pathIsAbsent(named: filename, in: imagesDescriptor) else {
                throw ImageStorageError.publicationFailed
            }
            do {
                try publish(data, staging, destination, base)
            } catch let error as DurableRegularFilePublicationError
                where error.outcome == .publicationOutcomeUncertain {
                Self.removeStagingFileIfPresent(stagingName, in: imagesDescriptor)
                guard Self.reconcilePublishedFile(named: filename, expected: data, in: imagesDescriptor) else {
                    throw ImageStorageError.publicationOutcomeUncertain
                }
            } catch {
                Self.removeStagingFileIfPresent(stagingName, in: imagesDescriptor)
                throw ImageStorageError.publicationFailed
            }
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
        guard let fileURL = validatedFileURL(for: path) else {
            SnapDrillLogger.generic.warning("跳过非法图片删除路径: \(path)")
            return
        }
        let base = baseDirectory
        try await Task.detached {
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: fileURL.path) else { return }
            guard Self.isTrustedStorageDirectory(base), Self.isRegularImageFile(at: fileURL) else {
                SnapDrillLogger.generic.warning("跳过非普通图片文件删除: \(path)")
                return
            }
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
        guard let fileURL = existingRegularFileURL(for: path) else { return nil }

        return UIImage(contentsOfFile: fileURL.path)
    }

    /// 返回已保存图片的文件 URL（不解码图片）。
    ///
    /// 供批量 ZIP 导出等文件级操作使用，避免把已脱敏的存盘 JPEG 解码成 `UIImage`
    /// 再重新编码，降低大批量导出的内存峰值。
    nonisolated public func imageFileURL(path: String) -> URL? {
        existingRegularFileURL(for: path)
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
        guard let fileURL = existingRegularFileURL(for: path) else { return nil }

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
        guard Self.isTrustedStorageDirectory(baseDirectory) else { return 0 }
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

    nonisolated private func validatedFileURL(for path: String) -> URL? {
        guard Self.isValidImagePath(path) else { return nil }
        return baseDirectory.appendingPathComponent(path)
    }

    nonisolated private func existingRegularFileURL(for path: String) -> URL? {
        guard let fileURL = validatedFileURL(for: path),
              Self.isTrustedStorageDirectory(baseDirectory),
              FileManager.default.fileExists(atPath: fileURL.path),
              Self.isRegularImageFile(at: fileURL) else {
            return nil
        }
        return fileURL
    }

    nonisolated private static func isRegularImageFile(at url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]) else {
            return false
        }
        return values.isRegularFile == true && values.isSymbolicLink != true
    }

    nonisolated private static func isTrustedStorageDirectory(_ baseDirectory: URL) -> Bool {
        let imagesDirectory = baseDirectory.appendingPathComponent("images", isDirectory: true)
        return isRegularDirectory(at: baseDirectory) && isRegularDirectory(at: imagesDirectory)
    }

    nonisolated private static func prepareStorageDirectory(
        _ baseDirectory: URL,
        fileManager: FileManager
    ) throws -> URL {
        if fileManager.fileExists(atPath: baseDirectory.path) {
            guard isRegularDirectory(at: baseDirectory) else {
                throw ImageStorageError.unsafeStorageDirectory
            }
        } else {
            try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
        let imagesDirectory = baseDirectory.appendingPathComponent("images", isDirectory: true)
        if fileManager.fileExists(atPath: imagesDirectory.path) {
            guard isRegularDirectory(at: imagesDirectory) else {
                throw ImageStorageError.unsafeStorageDirectory
            }
        } else {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: false)
            } catch {
                guard isRegularDirectory(at: imagesDirectory) else { throw error }
            }
        }
        return imagesDirectory
    }

    nonisolated private static func isRegularDirectory(at url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]) else {
            return false
        }
        return values.isDirectory == true && values.isSymbolicLink != true
    }

    // MARK: - Private Helpers

    /// 将 UIImage 编码为唯一 canonical JPEG；失败返回 nil 以保持现有调用契约。
    public nonisolated static func compressedJPEGData(from image: UIImage, maxLongSide: CGFloat, quality: CGFloat) -> Data? {
        guard maxLongSide.isFinite,
              (1...CGFloat(CanonicalJPEG.maximumDimension)).contains(maxLongSide) else { return nil }
        return try? CanonicalJPEG.encode(
            image,
            maxLongSide: Int(maxLongSide.rounded(.down)),
            quality: quality
        )
    }

    nonisolated private static func publishImageLive(
        _ bytes: Data,
        staging: DurableRegularFilePublisher.RelativeFile,
        destination: DurableRegularFilePublisher.RelativeFile,
        root: URL
    ) throws {
        try DurableRegularFilePublisher().publish(
            bytes,
            staging: staging,
            destination: destination,
            beneath: root,
            isExcludedFromBackup: false
        )
    }

    nonisolated private static func openImagesDirectory(beneath root: URL) -> Int32? {
        let rootDescriptor = root.path.withCString {
            Darwin.open($0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard rootDescriptor >= 0 else { return nil }
        defer { _ = Darwin.close(rootDescriptor) }
        let flags = O_RDONLY | O_DIRECTORY | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH | O_CLOEXEC
        let imagesDescriptor = "images".withCString { Darwin.openat(rootDescriptor, $0, flags) }
        return imagesDescriptor >= 0 ? imagesDescriptor : nil
    }

    nonisolated private static func reconcilePublishedFile(
        named name: String,
        expected: Data,
        in imagesDescriptor: Int32
    ) -> Bool {
        let flags = O_RDONLY | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH | O_UNIQUE | O_CLOEXEC
        let descriptor = name.withCString { Darwin.openat(imagesDescriptor, $0, flags) }
        guard descriptor >= 0 else { return false }
        defer { _ = Darwin.close(descriptor) }
        var metadata = stat()
        guard Darwin.fstat(descriptor, &metadata) == 0,
              metadata.st_mode & S_IFMT == S_IFREG,
              metadata.st_nlink == 1,
              metadata.st_size >= 0,
              pathMetadata(named: name, in: imagesDescriptor).map({ sameFile($0, metadata) }) == true else {
            return false
        }
        guard metadata.st_size == off_t(expected.count),
              let data = readExactBytes(descriptor: descriptor, byteCount: expected.count) else { return false }
        var finalMetadata = stat()
        guard Darwin.fstat(descriptor, &finalMetadata) == 0,
              sameFile(finalMetadata, metadata),
              finalMetadata.st_size == metadata.st_size,
              pathMetadata(named: name, in: imagesDescriptor).map({ sameFile($0, finalMetadata) }) == true else {
            return false
        }
        return data == expected
    }

    nonisolated private static func readExactBytes(descriptor: Int32, byteCount: Int) -> Data? {
        var data = Data(count: byteCount)
        let succeeded = data.withUnsafeMutableBytes { buffer in
            guard let address = buffer.baseAddress else { return byteCount == 0 }
            var offset = 0
            while offset < buffer.count {
                let count = Darwin.read(descriptor, address.advanced(by: offset), buffer.count - offset)
                if count > 0 {
                    offset += count
                } else if count == 0 || errno != EINTR {
                    return false
                }
            }
            var trailing: UInt8 = 0
            return Darwin.read(descriptor, &trailing, 1) == 0
        }
        return succeeded ? data : nil
    }

    nonisolated private static func removeStagingFileIfPresent(_ name: String, in imagesDescriptor: Int32) {
        guard name.hasPrefix("."), name.hasSuffix(".staging") else { return }
        let flags = O_RDONLY | O_NOFOLLOW_ANY | O_RESOLVE_BENEATH | O_UNIQUE | O_CLOEXEC
        let descriptor = name.withCString { Darwin.openat(imagesDescriptor, $0, flags) }
        guard descriptor >= 0 else { return }
        defer { _ = Darwin.close(descriptor) }
        var metadata = stat()
        guard Darwin.fstat(descriptor, &metadata) == 0,
              metadata.st_mode & S_IFMT == S_IFREG,
              metadata.st_nlink == 1,
              pathMetadata(named: name, in: imagesDescriptor).map({ sameFile($0, metadata) }) == true else { return }
        let result = name.withCString { Darwin.unlinkat(imagesDescriptor, $0, 0) }
        if result == 0 { _ = Darwin.fsync(imagesDescriptor) }
    }

    nonisolated private static func pathMetadata(named name: String, in directory: Int32) -> stat? {
        var metadata = stat()
        let flags = AT_SYMLINK_NOFOLLOW_ANY | AT_RESOLVE_BENEATH | AT_UNIQUE
        let result = name.withCString { Darwin.fstatat(directory, $0, &metadata, flags) }
        return result == 0 ? metadata : nil
    }

    nonisolated private static func pathIsAbsent(named name: String, in directory: Int32) -> Bool {
        var metadata = stat()
        let flags = AT_SYMLINK_NOFOLLOW_ANY | AT_RESOLVE_BENEATH | AT_UNIQUE
        let result = name.withCString { Darwin.fstatat(directory, $0, &metadata, flags) }
        return result != 0 && errno == ENOENT
    }

    nonisolated private static func sameFile(_ lhs: stat, _ rhs: stat) -> Bool {
        lhs.st_dev == rhs.st_dev && lhs.st_ino == rhs.st_ino
    }

}

/// 图片存储操作错误
public nonisolated enum ImageStorageError: Error, Equatable, Sendable {
    /// 无法将 UIImage 转换为 JPEG 数据（通常表示图片对象已损坏）
    case invalidImageData
    /// 图片目录不是普通目录（例如目录本身是符号链接）
    case unsafeStorageDirectory
    /// 文件未发布；调用方可安全重试。
    case publicationFailed
    /// rename 后结果无法证明，保留未引用节点等待 reconciliation。
    case publicationOutcomeUncertain
}
