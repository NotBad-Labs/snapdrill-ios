//
//  ImageStorageService.swift
//  NotBad
//
//  图片文件存储服务
//
//  将图片存储到 App Groups 共享目录，支持 Widget 访问。
//

import UIKit
import OSLog
import ReviewKit

// MARK: - ImageStorageService

/// 图片存储服务
///
/// 将图片保存到应用文档目录，返回文件名供数据库存储。
/// 解决 SwiftData 存储大图片导致的内存溢出问题。
///
/// ## 使用示例
///
/// ```swift
/// let service = ImageStorageService.shared
///
/// // 保存图片
/// if let fileName = service.save(image: uiImage, with: item.id) {
///     item.imagePath = fileName
/// }
///
/// // 加载图片
/// if let image = service.load(fileName: item.imagePath) {
///     imageView.image = image
/// }
///
/// // 删除图片
/// service.delete(fileName: item.imagePath)
/// ```
final class ImageStorageService: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = ImageStorageService()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    
    /// 图片存储目录（使用 App Groups 共享目录）
    private var imagesDirectory: URL {
        // ✅ 优先使用 App Groups 共享目录，让 Widget 也能访问
        if let sharedURL = PersistenceController.sharedContainerURL {
            return sharedURL.appendingPathComponent("Images", isDirectory: true)
        }
        // Fallback：私有目录（Widget 无法访问）
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("Images", isDirectory: true)
    }
    
    // MARK: - Initialization
    
    init() {
        // 确保目录存在
        do {
            try fileManager.createDirectory(
                at: imagesDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("📁 图片目录: \(imagesDirectory.path)")
        } catch {
            Logger.data.error("创建图片目录失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    
    /// 保存图片到磁盘
    ///
    /// - Parameters:
    ///   - image: UIImage 对象
    ///   - id: 关联的唯一标识符（通常是 ReviewItem.id）
    ///   - compressionQuality: JPEG 压缩质量（0.0-1.0），默认 0.8
    /// - Returns: 保存的文件名，失败返回 nil
    func save(image: UIImage, with id: UUID, compressionQuality: CGFloat = 0.8) -> String? {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            Logger.data.error("图片转换 JPEG 失败")
            return nil
        }
        
        return save(data: data, with: id)
    }
    
    /// 保存图片数据到磁盘
    ///
    /// - Parameters:
    ///   - data: 图片二进制数据
    ///   - id: 关联的唯一标识符
    /// - Returns: 保存的文件名，失败返回 nil
    func save(data: Data, with id: UUID) -> String? {
        let fileName = "\(id.uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL, options: .atomic)
            Logger.data.debug("图片保存成功: \(fileName)")
            return fileName
        } catch {
            Logger.data.error("保存图片失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 从磁盘加载图片
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: UIImage 对象，不存在或加载失败返回 nil
    func load(fileName: String?) -> UIImage? {
        guard let fileName = fileName, !fileName.isEmpty else {
            return nil
        }
        
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            Logger.data.warning("图片文件不存在: \(fileName)")
            return nil
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// 从磁盘加载图片数据
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: 图片数据，不存在或加载失败返回 nil
    func loadData(fileName: String?) -> Data? {
        guard let fileName = fileName, !fileName.isEmpty else {
            return nil
        }
        
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return try? Data(contentsOf: fileURL)
    }
    
    /// 删除图片文件
    ///
    /// - Parameter fileName: 文件名
    func delete(fileName: String?) {
        guard let fileName = fileName, !fileName.isEmpty else {
            return
        }
        
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            Logger.data.debug("图片删除成功: \(fileName)")
        } catch {
            Logger.data.warning("删除图片失败: \(error.localizedDescription)")
        }
    }
    
    /// 批量删除图片
    ///
    /// - Parameter fileNames: 文件名数组
    func delete(fileNames: [String?]) {
        for fileName in fileNames {
            delete(fileName: fileName)
        }
    }
    
    /// 检查图片是否存在
    ///
    /// - Parameter fileName: 文件名
    /// - Returns: 是否存在
    func exists(fileName: String?) -> Bool {
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
    func fileURL(for fileName: String?) -> URL? {
        guard let fileName = fileName, !fileName.isEmpty else {
            return nil
        }
        return imagesDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Cleanup
    
    /// 清理所有图片（危险操作）
    func clearAll() {
        do {
            let files = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            Logger.data.info("已清理所有图片，共 \(files.count) 个")
        } catch {
            Logger.data.error("清理图片失败: \(error.localizedDescription)")
        }
    }
    
    /// 获取图片目录大小（字节）
    func totalSize() -> Int64 {
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
    var formattedSize: String {
        let bytes = totalSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
