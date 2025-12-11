import Foundation
import os.log

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#else
#error("ImageStorageService requires UIKit or AppKit")
#endif

private let logger = Logger(subsystem: "com.notbad.reviewkit", category: "ImageStorage")

/// 图片存储服务（async/await）
public actor ImageStorageService {
    @MainActor
    public static let shared = ImageStorageService()
    
    private let config: ReviewKitConfiguration
    /// 图片目录 URL（App Group 内）
    public var imagesDirectoryURL: URL? { config.imagesDirectoryURL }
    /// JPEG 压缩质量（0-1）
    public var compressionQuality: Double = 0.8
    
    @MainActor
    public init(configuration: ReviewKitConfiguration = .shared) {
        self.config = configuration
    }
    
    /// 按复习项 ID 保存图片，返回文件名
    public func saveImage(_ image: PlatformImage, for itemId: UUID, compressionQuality: Double? = nil) async throws -> String {
        let fileName = "\(itemId.uuidString).jpg"
        try await saveImage(image, named: fileName, compressionQuality: compressionQuality)
        return fileName
    }
    
    /// 按指定文件名保存图片
    public func saveImage(_ image: PlatformImage, named fileName: String, compressionQuality: Double? = nil) async throws {
        guard let directoryURL = imagesDirectoryURL else {
            throw ImageStorageError.appGroupNotConfigured
        }
        createImagesDirectoryIfNeeded()
        let fileURL = directoryURL.appendingPathComponent(fileName)
        let quality = compressionQuality ?? self.compressionQuality
        
        try await Task.detached(priority: .userInitiated) {
            #if canImport(UIKit)
            guard let data = image.jpegData(compressionQuality: CGFloat(quality)) else {
                throw ImageStorageError.compressionFailed
            }
            #elseif canImport(AppKit)
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
                throw ImageStorageError.compressionFailed
            }
            #endif
            try data.write(to: fileURL)
        }.value
        logger.info("图片已保存: \(fileName)")
    }

    /// 保存图片数据
    public func saveData(_ data: Data, for itemId: UUID) async throws -> String {
        let fileName = "\(itemId.uuidString).jpg"
        guard let directoryURL = imagesDirectoryURL else {
            throw ImageStorageError.appGroupNotConfigured
        }
        createImagesDirectoryIfNeeded()
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        try await Task.detached(priority: .userInitiated) {
            try data.write(to: fileURL)
        }.value
        logger.info("图片数据已保存: \(fileName)")
        return fileName
    }
    
    /// 加载指定文件名的图片
    public func loadImage(named fileName: String?) async -> PlatformImage? {
        guard let fileName, !fileName.isEmpty else { return nil }
        guard let directoryURL = imagesDirectoryURL else {
            logger.warning("App Group 未配置，无法加载图片")
            return nil
        }
        let fileURL = directoryURL.appendingPathComponent(fileName)
        return await Task.detached { () -> PlatformImage? in
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            #if canImport(UIKit)
            return UIImage(contentsOfFile: fileURL.path)
            #elseif canImport(AppKit)
            return NSImage(contentsOf: fileURL)
            #endif
        }.value
    }

    /// 加载图片数据
    public func loadData(named fileName: String?) async -> Data? {
        guard let fileName, !fileName.isEmpty else { return nil }
        guard let directoryURL = imagesDirectoryURL else { return nil }
        let fileURL = directoryURL.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    /// 按复习项 ID 加载图片
    public func loadImage(for itemId: UUID) async -> PlatformImage? {
        await loadImage(named: "\(itemId.uuidString).jpg")
    }
    
    /// 删除指定文件名的图片
    public func deleteImage(named fileName: String?) async {
        guard let fileName, !fileName.isEmpty else { return }
        guard let directoryURL = imagesDirectoryURL else { return }
        let fileURL = directoryURL.appendingPathComponent(fileName)
        await Task.detached {
            do { try FileManager.default.removeItem(at: fileURL) }
            catch { logger.error("删除图片失败: \(error.localizedDescription)") }
        }.value
    }
    
    /// 批量删除图片
    public func deleteImages(named fileNames: [String?]) async {
        for name in fileNames {
            await deleteImage(named: name)
        }
    }
    
    /// 按复习项 ID 删除图片
    public func deleteImage(for itemId: UUID) async {
        await deleteImage(named: "\(itemId.uuidString).jpg")
    }
    
    /// 判断图片是否存在
    public func imageExists(named fileName: String?) async -> Bool {
        guard let fileName, !fileName.isEmpty else { return false }
        guard let directoryURL = imagesDirectoryURL else { return false }
        let fileURL = directoryURL.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// 获取文件 URL
    public func fileURL(for fileName: String?) async -> URL? {
        guard let fileName, !fileName.isEmpty else { return nil }
        guard let directoryURL = imagesDirectoryURL else { return nil }
        return directoryURL.appendingPathComponent(fileName)
    }
    
    /// 删除所有图片
    public func deleteAllImages() async {
        guard let directoryURL = imagesDirectoryURL else { return }
        await Task.detached {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
                for fileURL in contents { try FileManager.default.removeItem(at: fileURL) }
            } catch {
                logger.error("清理图片失败: \(error.localizedDescription)")
            }
        }.value
    }

    /// 已格式化的存储大小
    public var formattedSize: String {
        get async {
            let bytes = await totalSize()
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: bytes)
        }
    }
    
    /// 图片数量
    public var imageCount: Int {
        get async {
            guard let directoryURL = imagesDirectoryURL else { return 0 }
            do {
                let files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
                return files.count
            } catch {
                return 0
            }
        }
    }
    
    private func totalSize() async -> Int64 {
        guard let directoryURL = imagesDirectoryURL else { return 0 }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.fileSizeKey])
            var total: Int64 = 0
            for file in files {
                let values = try file.resourceValues(forKeys: [.fileSizeKey])
                total += Int64(values.fileSize ?? 0)
            }
            return total
        } catch {
            return 0
        }
    }
    
    @discardableResult
    /// 清理未被引用的孤立图片
    public func cleanupOrphanedImages(validIds: Set<UUID>) async -> Int {
        guard let directoryURL = imagesDirectoryURL else { return 0 }
        return await Task.detached { () -> Int in
            var deletedCount = 0
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
                for fileURL in contents {
                    let fileName = fileURL.deletingPathExtension().lastPathComponent
                    if let uuid = UUID(uuidString: fileName), !validIds.contains(uuid) {
                        try FileManager.default.removeItem(at: fileURL)
                        deletedCount += 1
                        logger.info("已删除孤立图片: \(fileName)")
                    }
                }
            } catch {
                logger.error("清理孤立图片失败: \(error.localizedDescription)")
            }
            return deletedCount
        }.value
    }
    
    private func createImagesDirectoryIfNeeded() {
        guard let directoryURL = imagesDirectoryURL else { return }
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                logger.info("已创建图片目录: \(directoryURL.path)")
            } catch {
                logger.error("创建图片目录失败: \(error.localizedDescription)")
            }
        }
    }
}

/// 图片存储错误类型
public enum ImageStorageError: Error, LocalizedError {
    case appGroupNotConfigured
    case compressionFailed
    case saveFailed(Error)
    
    /// 用户可读的错误描述
    public var errorDescription: String? {
        switch self {
        case .appGroupNotConfigured:
            return "App Group 未配置，无法保存图片到共享目录"
        case .compressionFailed:
            return "图片压缩失败"
        case .saveFailed(let error):
            return "图片保存失败: \(error.localizedDescription)"
        }
    }
}