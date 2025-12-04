//
//  ThumbnailCache.swift
//  NotBad
//
//  缩略图内存缓存
//
//  解决问题：列表快速滚动时，相同图片反复解码导致内存抖动和 CPU 占用
//
//  解决方案：使用 NSCache 缓存解码后的缩略图
//  - 自动内存管理（内存紧张时自动清理）
//  - 按 ReviewItem ID 作为 Key
//  - 最大缓存 100 张缩略图
//

import UIKit

// MARK: - Thumbnail Cache

/// 缩略图内存缓存
///
/// 使用 `NSCache` 自动管理内存，避免列表滚动时重复解码图片。
///
/// ## 使用示例
///
/// ```swift
/// // 检查缓存
/// if let cached = ThumbnailCache.shared.thumbnail(for: item.id) {
///     return cached
/// }
///
/// // 解码后存入缓存
/// let thumbnail = decodeImage(data)
/// ThumbnailCache.shared.setThumbnail(thumbnail, for: item.id)
/// ```
///
/// ## 内存管理
///
/// - 最大缓存 100 张图片
/// - 单张图片最大 500KB
/// - 系统内存紧张时自动清理
final class ThumbnailCache: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = ThumbnailCache()
    
    // MARK: - Private Properties
    
    /// NSCache 自动管理内存
    private let cache = NSCache<NSString, UIImage>()
    
    // MARK: - Initialization
    
    private init() {
        // 配置缓存限制
        cache.countLimit = 100  // 最多 100 张图片
        cache.totalCostLimit = 50 * 1024 * 1024  // 最大 50MB
        
        // 监听内存警告
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearCache()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public API
    
    /// 获取缓存的缩略图
    ///
    /// - Parameter id: ReviewItem 的 UUID
    /// - Returns: 缓存的缩略图，如果不存在返回 nil
    func thumbnail(for id: UUID) -> UIImage? {
        cache.object(forKey: id.uuidString as NSString)
    }
    
    /// 缓存缩略图
    ///
    /// - Parameters:
    ///   - image: 缩略图
    ///   - id: ReviewItem 的 UUID
    func setThumbnail(_ image: UIImage, for id: UUID) {
        // 计算图片占用内存（近似值）
        let cost = Int(image.size.width * image.size.height * 4)  // RGBA
        cache.setObject(image, forKey: id.uuidString as NSString, cost: cost)
    }
    
    /// 移除指定项目的缓存
    ///
    /// - Parameter id: ReviewItem 的 UUID
    func removeThumbnail(for id: UUID) {
        cache.removeObject(forKey: id.uuidString as NSString)
    }
    
    /// 清空所有缓存
    func clearCache() {
        cache.removeAllObjects()
    }
}
