// ImageKit - 图片存储核心库
//
// 提供图片文件的存储、加载、删除功能。
// 支持 iOS (UIKit) 和 macOS (AppKit)。

import Foundation

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
private let maxSaveDimension: CGFloat = 2048
private extension UIImage {
    /// 限制最大边长并保持比例，用于保存前压缩
    func preparingForSave(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
private let maxSaveDimension: CGFloat = 2048
private extension NSImage {
    func preparingForSave(maxDimension: CGFloat) -> NSImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        defer { newImage.unlockFocus() }
        self.draw(in: NSRect(origin: .zero, size: newSize))
        return newImage
    }
}
#endif

import OSLog

// MARK: - Logger Extension

private extension Logger {
    static let imageKit = Logger(subsystem: "com.notbad.imagekit", category: "ImageStorage")
}

// MARK: - ImageStorageService

/// 图片存储服务
///
/// 将图片保存到应用文档目录，返回文件名供数据库存储。
/// 解决 SwiftData 存储大图片导致的内存溢出问题。
/// 线程安全：所有文件操作通过锁保护。
///
/// ## 使用示例
///
/// ```swift
/// let storage = ImageStorageService.shared
///
/// // 保存图片
/// if let fileName = storage.save(image: image, with: item.id) {
///     item.imagePath = fileName
/// }
///
/// // 加载图片
/// if let image = storage.load(fileName: item.imagePath) {
///     imageView.image = image
/// }
///
/// // 删除图片
/// storage.delete(fileName: item.imagePath)
/// ```
public final class ImageStorageService: @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// 共享实例
    public static let shared = ImageStorageService()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let subdirectory: String
    private let lock = NSLock()
    
    /// 图片存储目录
    public var imagesDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent(subdirectory, isDirectory: true)
    }
    
    // MARK: - Initialization
    
    /// 创建图片存储服务
    /// - Parameter subdirectory: 子目录名称，默认 "Images"
    public init(subdirectory: String = "Images") {
        self.subdirectory = subdirectory
        ensureDirectoryExists()
    }
    
    private func ensureDirectoryExists() {
        lock.withLock {
            do {
                try fileManager.createDirectory(
                    at: imagesDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                Logger.imageKit.error("创建图片目录失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Save
    
    #if canImport(UIKit)
    /// 保存 UIImage 到磁盘
    ///
    /// - Parameters:
    ///   - image: UIImage 对象
    ///   - id: 关联的唯一标识符
    ///   - compressionQuality: JPEG 压缩质量（0.0-1.0），默认 0.8
    /// - Returns: 保存的文件名，失败返回 nil
    public func save(image: UIImage, with id: UUID, compressionQuality: CGFloat = 0.8) -> String? {
        let prepared = image.preparingForSave(maxDimension: maxSaveDimension)
        guard let data = prepared.jpegData(compressionQuality: compressionQuality) else {
            Logger.imageKit.error("图片转换 JPEG 失败")
            return nil
        }
        return save(data: data, with: id)
    }
    #endif
    
    #if canImport(AppKit)
    /// 保存 NSImage 到磁盘
    ///
    /// - Parameters:
    ///   - image: NSImage 对象
    ///   - id: 关联的唯一标识符
    ///   - compressionQuality: JPEG 压缩质量（0.0-1.0），默认 0.8
    /// - Returns: 保存的文件名，失败返回 nil
    public func save(image: NSImage, with id: UUID, compressionQuality: CGFloat = 0.8) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
            Logger.imageKit.error("图片转换 JPEG 失败")
            return nil
        }
        return save(data: data, with: id)
    }
    #endif
    
    /// 保存图片数据到磁盘
    ///
    /// - Parameters:
    ///   - data: 图片二进制数据
    ///   - id: 关联的唯一标识符
    /// - Returns: 保存的文件名，失败返回 nil
    public func save(data: Data, with id: UUID) -> String? {
        let fileName = "\(id.uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        return lock.withLock {
            do {
                try data.write(to: fileURL, options: .atomic)
                Logger.imageKit.debug("图片保存成功: \(fileName)")
                return fileName
            } catch {
                Logger.imageKit.error("保存图片失败: \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    // MARK: - Load
    
    /// 从磁盘加载图片
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: 图片对象，不存在或加载失败返回 nil
    public func load(fileName: String?) -> PlatformImage? {
        guard let fileName = fileName, !fileName.isEmpty else {
            return nil
        }
        
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            Logger.imageKit.warning("图片文件不存在: \(fileName)")
            return nil
        }
        
        #if canImport(UIKit)
        return UIImage(contentsOfFile: fileURL.path)
        #elseif canImport(AppKit)
        return NSImage(contentsOfFile: fileURL.path)
        #endif
    }
    
    /// 从磁盘加载图片数据
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: 图片数据，不存在或加载失败返回 nil
    public func loadData(fileName: String?) -> Data? {
        guard let fileName = fileName, !fileName.isEmpty else {
            return nil
        }
        
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return try? Data(contentsOf: fileURL)
    }
    
    // MARK: - Delete
    
    /// 删除图片文件
    ///
    /// - Parameter fileName: 文件名
    public func delete(fileName: String?) {
        guard let fileName = fileName, !fileName.isEmpty else {
            return
        }
        
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        lock.withLock {
            do {
                try fileManager.removeItem(at: fileURL)
                Logger.imageKit.debug("图片删除成功: \(fileName)")
            } catch {
                Logger.imageKit.warning("删除图片失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 批量删除图片
    ///
    /// - Parameter fileNames: 文件名数组
    public func delete(fileNames: [String?]) {
        for fileName in fileNames {
            delete(fileName: fileName)
        }
    }
    
    // MARK: - Query
    
    /// 检查图片是否存在
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: 是否存在
    public func exists(fileName: String?) -> Bool {
        guard let fileName = fileName, !fileName.isEmpty else {
            return false
        }
        
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// 获取图片文件的完整 URL
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: 文件 URL
    public func fileURL(for fileName: String?) -> URL? {
        guard let fileName = fileName, !fileName.isEmpty else {
            return nil
        }
        return imagesDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Cleanup & Stats
    
    /// 清理所有图片（危险操作）
    public func clearAll() {
        lock.withLock {
            do {
                let files = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
                for file in files {
                    try fileManager.removeItem(at: file)
                }
                Logger.imageKit.info("已清理所有图片，共 \(files.count) 个")
            } catch {
                Logger.imageKit.error("清理图片失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 获取图片目录大小（字节）
    public func totalSize() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var total: Int64 = 0
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                total += Int64(attributes.fileSize ?? 0)
            }
            return total
        } catch {
            return 0
        }
    }
    
    /// 格式化的存储大小
    public var formattedSize: String {
        let bytes = totalSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// 获取图片数量
    public var imageCount: Int {
        do {
            let files = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
            return files.count
        } catch {
            return 0
        }
    }
}
