//
//  ThumbnailCache.swift
//  NotBad
//
//  二级缩略图缓存（内存 + 磁盘）
//
//  解决问题：
//  1. 列表快速滚动时，相同图片反复解码导致内存抖动和 CPU 占用
//  2. App 冷启动后，内存缓存清空，需要重新解码大图
//
//  解决方案：两级缓存架构
//  - L1: 内存缓存 (NSCache) - 热数据，快速访问
//  - L2: 磁盘缓存 (Library/Caches/Thumbnails) - 持久化，冷启动加速
//

import UIKit
import OSLog

// MARK: - Thumbnail Cache

/// 二级缩略图缓存
///
/// 使用内存 + 磁盘两级缓存，优化列表滚动和冷启动性能。
///
/// ## 缓存策略
///
/// 1. **读取顺序**: 内存 → 磁盘 → 原图解码
/// 2. **写入**: 同时写入内存和磁盘
/// 3. **清理**: 磁盘缓存超过阈值时自动清理老文件
///
/// ## 使用示例
///
/// ```swift
/// // 检查缓存（自动处理两级查找）
/// if let cached = await ThumbnailCache.shared.thumbnail(for: item.id) {
///     return cached
/// }
///
/// // 生成并缓存缩略图
/// let thumbnail = generateThumbnail(from: imageData)
/// await ThumbnailCache.shared.setThumbnail(thumbnail, for: item.id)
/// ```
///
/// ## 性能特性
///
/// - 内存缓存: 最大 100 张 / 50MB
/// - 磁盘缓存: 最大 200MB，超限自动清理
/// - 缩略图尺寸: 300x300 JPEG (质量 0.7)
///
/// - Note: 使用 Swift actor 确保线程安全，替代 `@unchecked Sendable`
actor ThumbnailCache {
    
    // MARK: - Singleton
    
    static let shared = ThumbnailCache()
    
    // MARK: - Configuration
    
    /// 缩略图最大尺寸
    private let thumbnailSize: CGFloat = 300
    
    /// JPEG 压缩质量
    private let jpegQuality: CGFloat = 0.7
    
    /// 磁盘缓存最大容量 (200MB)
    private let maxDiskCacheSize: Int = 200 * 1024 * 1024
    
    // MARK: - L1: Memory Cache
    
    /// 内存缓存 (NSCache 自动管理)
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // MARK: - L2: Disk Cache
    
    /// 磁盘缓存目录
    private let diskCacheURL: URL
    
    /// 文件管理器
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    private init() {
        // 配置内存缓存限制
        memoryCache.countLimit = 100  // 最多 100 张图片
        memoryCache.totalCostLimit = 50 * 1024 * 1024  // 最大 50MB
        
        // 配置磁盘缓存目录
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDir.appendingPathComponent("Thumbnails", isDirectory: true)
        
        // 创建目录
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // 监听内存警告
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.clearMemoryCache() }
        }
        
        // 启动时检查磁盘缓存大小
        Task { [weak self] in
            await self?.trimDiskCacheIfNeeded()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public API
    
    /// 获取缓存的缩略图（两级查找）
    ///
    /// - Parameter id: ReviewItem 的 UUID
    /// - Returns: 缓存的缩略图，如果不存在返回 nil
    func thumbnail(for id: UUID) -> UIImage? {
        let key = id.uuidString as NSString
        
        // L1: 检查内存缓存
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }
        
        // L2: 检查磁盘缓存
        let fileURL = diskCacheURL.appendingPathComponent("\(id.uuidString).jpg")
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // 回写到内存缓存
            setMemoryCache(image, for: id)
            // 更新文件访问时间（用于 LRU 清理）
            try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
            return image
        }
        
        return nil
    }
    
    /// 异步获取缩略图（推荐用于 UI）
    ///
    /// - Parameter id: ReviewItem 的 UUID
    /// - Returns: 缓存的缩略图
    func thumbnailAsync(for id: UUID) async -> UIImage? {
        // L1: 先检查内存
        let key = id.uuidString as NSString
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }
        
        // L2: 磁盘读取
        let fileURL = diskCacheURL.appendingPathComponent("\(id.uuidString).jpg")
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // 回写到内存缓存
            setMemoryCache(image, for: id)
            // 更新访问时间
            try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
            return image
        }
        
        return nil
    }
    
    /// 缓存缩略图（同时写入内存和磁盘）
    ///
    /// - Parameters:
    ///   - image: 缩略图
    ///   - id: ReviewItem 的 UUID
    func setThumbnail(_ image: UIImage, for id: UUID) {
        // L1: 写入内存
        setMemoryCache(image, for: id)
        
        // L2: 写入磁盘
        writeToDisk(image, for: id)
    }
    
    /// 从原图数据生成并缓存缩略图
    ///
    /// - Parameters:
    ///   - imageData: 原图数据
    ///   - id: ReviewItem 的 UUID
    /// - Returns: 生成的缩略图
    func generateAndCache(from imageData: Data, for id: UUID) -> UIImage? {
        // 先检查缓存
        if let cached = thumbnail(for: id) {
            return cached
        }
        
        guard let original = UIImage(data: imageData) else {
            return nil
        }
        
        // 生成缩略图
        let thumbnail = createThumbnail(from: original)
        
        // 缓存到内存和磁盘
        setMemoryCache(thumbnail, for: id)
        writeToDisk(thumbnail, for: id)
        
        return thumbnail
    }
    
    /// 移除指定项目的缓存
    ///
    /// - Parameter id: ReviewItem 的 UUID
    func removeThumbnail(for id: UUID) {
        // 移除内存缓存
        memoryCache.removeObject(forKey: id.uuidString as NSString)
        
        // 移除磁盘缓存
        let fileURL = diskCacheURL.appendingPathComponent("\(id.uuidString).jpg")
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// 清空内存缓存
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        Logger.performance.debug("ThumbnailCache: 内存缓存已清空")
    }
    
    /// 清空所有缓存（内存 + 磁盘）
    func clearAllCache() {
        clearMemoryCache()
        
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        Logger.performance.info("ThumbnailCache: 所有缓存已清空")
    }
    
    /// 获取磁盘缓存大小
    func diskCacheSize() -> Int {
        calculateDiskCacheSize()
    }
    
    // MARK: - Private Helpers
    
    private func setMemoryCache(_ image: UIImage, for id: UUID) {
        let cost = Int(image.size.width * image.size.height * 4)  // RGBA
        memoryCache.setObject(image, forKey: id.uuidString as NSString, cost: cost)
    }
    
    private func writeToDisk(_ image: UIImage, for id: UUID) {
        guard let data = image.jpegData(compressionQuality: jpegQuality) else { return }
        
        let fileURL = diskCacheURL.appendingPathComponent("\(id.uuidString).jpg")
        try? data.write(to: fileURL, options: .atomic)
    }
    
    private func createThumbnail(from original: UIImage) -> UIImage {
        let scale = min(thumbnailSize / original.size.width, thumbnailSize / original.size.height, 1.0)
        let newSize = CGSize(
            width: original.size.width * scale,
            height: original.size.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            original.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func calculateDiskCacheSize() -> Int {
        guard let enumerator = fileManager.enumerator(
            at: diskCacheURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        var totalSize = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += size
            }
        }
        return totalSize
    }
    
    private func trimDiskCacheIfNeeded() {
        let currentSize = calculateDiskCacheSize()
        guard currentSize > maxDiskCacheSize else { return }
        
        Logger.performance.info("ThumbnailCache: 磁盘缓存超限 (\(currentSize / 1024 / 1024)MB)，开始清理...")
        
        // 获取所有缓存文件，按修改时间排序
        guard let enumerator = fileManager.enumerator(
            at: diskCacheURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        var files: [(url: URL, date: Date, size: Int)] = []
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
               let size = values.fileSize,
               let date = values.contentModificationDate {
                files.append((fileURL, date, size))
            }
        }
        
        // 按修改时间排序（最旧的在前）
        files.sort { $0.date < $1.date }
        
        // 删除最旧的文件，直到低于阈值的 80%
        let targetSize = maxDiskCacheSize * 80 / 100
        var freedSize = 0
        var deletedCount = 0
        
        for file in files {
            if currentSize - freedSize <= targetSize {
                break
            }
            try? fileManager.removeItem(at: file.url)
            freedSize += file.size
            deletedCount += 1
        }
        
        Logger.performance.info("ThumbnailCache: 已清理 \(deletedCount) 个文件，释放 \(freedSize / 1024 / 1024)MB")
    }
}
