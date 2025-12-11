import Foundation
import CoreGraphics
import OSLog

#if canImport(UIKit)
import UIKit
private let maxSaveDimension: CGFloat = 2048
private extension UIImage {
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

private extension Logger {
    static let captureKitImage = Logger(subsystem: "com.notbad.capturekit", category: "ImageStorage")
}

/// 基于文件系统的图片存储 actor。
///
/// 默认根目录为应用 Documents；宿主可通过 `directoryProvider` 注入 App Group
/// 目录，与 ReviewKit 对齐。
///
/// ## 性能优化
/// - LRU 缓存：内存缓存最近使用的图片，减少磁盘 I/O
/// - 缓存容量：默认 20 张图片，可配置
public actor ImageStorageService: ImageStorageClient {
    public typealias DirectoryProvider = () throws -> URL
    
    private let directoryProvider: DirectoryProvider
    private let subdirectory: String
    private let defaultCompressionQuality: Double
    private var cachedDirectory: URL?
    
    // MARK: - LRU Cache
    
    /// LRU 图片缓存
    private var imageCache: [String: CacheEntry] = [:]
    /// 缓存访问顺序（最近使用的在前）
    private var accessOrder: [String] = []
    /// 最大缓存数量
    private let maxCacheSize: Int
    
    /// 缓存条目
    private struct CacheEntry {
        let image: PlatformImage
        let data: Data
        var lastAccess: Date
    }
    
    /// 初始化
    /// - Parameters:
    ///   - directoryProvider: 返回根目录的提供者，可用于传入 App Group 容器
    ///   - subdirectory: 图片子目录名称
    ///   - compressionQuality: 默认 JPEG 压缩质量
    ///   - maxCacheSize: 最大缓存图片数量（默认 20）
    public init(
        directoryProvider: @escaping DirectoryProvider = ImageStorageService.defaultDocumentsDirectory,
        subdirectory: String = "Images",
        compressionQuality: Double = 0.8,
        maxCacheSize: Int = 20
    ) {
        self.directoryProvider = directoryProvider
        self.subdirectory = subdirectory
        self.defaultCompressionQuality = compressionQuality
        self.maxCacheSize = max(1, maxCacheSize)
    }
    
    // MARK: - Save
    
    /// 保存图片（自动压缩、缩放）
    /// - Parameters:
    ///   - image: 图片对象
    ///   - id: 业务 ID
    ///   - compressionQuality: 压缩质量（优先使用调用方传入，fallback 为默认值）
    /// - Returns: 文件名（含扩展名）
    public func saveImage(
        _ image: PlatformImage,
        id: UUID,
        compressionQuality: CGFloat = 0.8
    ) async throws -> String {
        let quality = compressionQuality.isFinite ? compressionQuality : CGFloat(defaultCompressionQuality)
        let data: Data
        #if canImport(UIKit)
        let prepared = image.preparingForSave(maxDimension: maxSaveDimension)
        guard let jpeg = prepared.jpegData(compressionQuality: quality) else {
            throw ImageStorageClientError.compressionFailed
        }
        data = jpeg
        #elseif canImport(AppKit)
        let prepared = image.preparingForSave(maxDimension: maxSaveDimension)
        guard let tiffData = prepared.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            throw ImageStorageClientError.compressionFailed
        }
        data = jpeg
        #endif
        return try await saveData(data, id: id)
    }
    
    /// 保存图片数据
    /// - Parameters:
    ///   - data: 图片数据
    ///   - id: 业务 ID
    /// - Returns: 文件名（含扩展名）
    public func saveData(_ data: Data, id: UUID) async throws -> String {
        let fileName = "\(id.uuidString).jpg"
        let directory = try ensureDirectory()
        let fileURL = directory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            Logger.captureKitImage.debug("Saved image: \(fileName)")
            return fileName
        } catch {
            throw ImageStorageClientError.saveFailed(error)
        }
    }
    
    // MARK: - Load
    
    /// 加载图片（带缓存）
    /// - Parameter fileName: 文件名
    /// - Returns: 图片对象或 nil
    public func loadImage(named fileName: String?) async -> PlatformImage? {
        guard let fileName, !fileName.isEmpty else { return nil }
        
        // 检查缓存
        if let cached = imageCache[fileName] {
            updateAccessOrder(for: fileName)
            Logger.captureKitImage.debug("Image cache hit: \(fileName)")
            return cached.image
        }
        
        // 从磁盘加载
        guard let directory = try? ensureDirectory() else { return nil }
        let fileURL = directory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        #if canImport(UIKit)
        guard let image = UIImage(contentsOfFile: fileURL.path) else { return nil }
        #elseif canImport(AppKit)
        guard let image = NSImage(contentsOf: fileURL) else { return nil }
        #endif
        
        // 缓存图片
        if let data = try? Data(contentsOf: fileURL) {
            cacheImage(image, data: data, fileName: fileName)
        }
        
        Logger.captureKitImage.debug("Image loaded from disk: \(fileName)")
        return image
    }
    
    /// 加载图片数据（带缓存）
    /// - Parameter fileName: 文件名
    /// - Returns: 数据或 nil
    public func loadData(named fileName: String?) async -> Data? {
        guard let fileName, !fileName.isEmpty else { return nil }
        
        // 检查缓存
        if let cached = imageCache[fileName] {
            updateAccessOrder(for: fileName)
            Logger.captureKitImage.debug("Data cache hit: \(fileName)")
            return cached.data
        }
        
        // 从磁盘加载
        guard let directory = try? ensureDirectory() else { return nil }
        let fileURL = directory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        
        // 尝试缓存（如果能创建图片）
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            cacheImage(image, data: data, fileName: fileName)
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: data) {
            cacheImage(image, data: data, fileName: fileName)
        }
        #endif
        
        return data
    }
    
    // MARK: - Delete
    
    /// 删除单个图片
    /// - Parameter fileName: 文件名
    public func deleteImage(named fileName: String?) async {
        guard let fileName, !fileName.isEmpty else { return }
        
        // 从缓存移除
        imageCache.removeValue(forKey: fileName)
        accessOrder.removeAll { $0 == fileName }
        
        guard let directory = try? ensureDirectory() else { return }
        let fileURL = directory.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: fileURL)
            Logger.captureKitImage.debug("Deleted image: \(fileName)")
        } catch {
            Logger.captureKitImage.warning("Failed to delete image: \(error.localizedDescription)")
        }
    }
    
    /// 批量删除图片
    /// - Parameter fileNames: 文件名列表
    public func deleteImages(named fileNames: [String?]) async {
        for name in fileNames {
            await deleteImage(named: name)
        }
    }
    
    // MARK: - Query
    
    /// 判断图片是否存在
    /// - Parameter fileName: 文件名
    /// - Returns: 是否存在
    public func exists(named fileName: String?) async -> Bool {
        guard let fileName, !fileName.isEmpty else { return false }
        guard let directory = try? ensureDirectory() else { return false }
        let fileURL = directory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /// 获取图片 URL
    /// - Parameter fileName: 文件名
    /// - Returns: 完整 URL 或 nil
    public func fileURL(for fileName: String?) async -> URL? {
        guard let fileName, !fileName.isEmpty else { return nil }
        guard let directory = try? ensureDirectory() else { return nil }
        return directory.appendingPathComponent(fileName)
    }
    
    // MARK: - Cleanup & Stats
    
    /// 清空目录下所有图片
    public func clearAll() async {
        // 清空缓存
        imageCache.removeAll()
        accessOrder.removeAll()
        
        guard let directory = try? ensureDirectory() else { return }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            Logger.captureKitImage.info("Cleared images: \(files.count)")
        } catch {
            Logger.captureKitImage.error("Failed to clear images: \(error.localizedDescription)")
        }
    }
    
    /// 清空内存缓存
    public func clearCache() {
        imageCache.removeAll()
        accessOrder.removeAll()
        Logger.captureKitImage.info("Cleared image cache")
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
            guard let directory = try? ensureDirectory() else { return 0 }
            do {
                let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                return files.count
            } catch {
                return 0
            }
        }
    }
    
    private func totalSize() async -> Int64 {
        guard let directory = try? ensureDirectory() else { return 0 }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
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
    
    // MARK: - Directory helpers
    
    private func ensureDirectory() throws -> URL {
        if let cachedDirectory { return cachedDirectory }
        let base = try directoryProvider()
        let directory = base.appendingPathComponent(subdirectory, isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            Logger.captureKitImage.info("Created image directory: \(directory.path)")
        }
        cachedDirectory = directory
        return directory
    }
    
    public static func defaultDocumentsDirectory() throws -> URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ImageStorageClientError.directoryUnavailable
        }
        return url
    }
    
    // MARK: - Cache Management
    
    /// 缓存图片
    private func cacheImage(_ image: PlatformImage, data: Data, fileName: String) {
        // 如果已存在，更新访问时间
        if imageCache[fileName] != nil {
            updateAccessOrder(for: fileName)
            return
        }
        
        // 检查是否需要淘汰
        if imageCache.count >= maxCacheSize {
            evictLeastRecentlyUsed()
        }
        
        // 添加到缓存
        imageCache[fileName] = CacheEntry(image: image, data: data, lastAccess: Date())
        accessOrder.insert(fileName, at: 0)
    }
    
    /// 更新访问顺序（移到最前）
    private func updateAccessOrder(for fileName: String) {
        accessOrder.removeAll { $0 == fileName }
        accessOrder.insert(fileName, at: 0)
        imageCache[fileName]?.lastAccess = Date()
    }
    
    /// 淘汰最近最少使用的图片
    private func evictLeastRecentlyUsed() {
        guard let lru = accessOrder.last else { return }
        imageCache.removeValue(forKey: lru)
        accessOrder.removeLast()
        Logger.captureKitImage.debug("Evicted LRU image: \(lru)")
    }
}

