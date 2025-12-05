//
//  SpotlightIndexService.swift
//  NotBad
//
//  Core Spotlight 索引服务
//
//  让用户可以从 iOS 系统搜索直接找到错题
//

import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import UIKit
import OSLog

// MARK: - SpotlightIndexService

/// Core Spotlight 索引服务
///
/// 将错题内容索引到系统搜索，用户可以：
/// - 在主屏幕下拉搜索错题关键词
/// - 点击搜索结果直达错题详情页
///
/// ## 功能特性
///
/// - 自动索引新增/更新的错题
/// - 删除错题时移除索引
/// - 支持批量索引和清理
/// - 索引内容包括：标题、笔记、知识点、学科
///
/// ## 使用示例
///
/// ```swift
/// // 索引单个错题
/// SpotlightIndexService.shared.index(item)
///
/// // 删除索引
/// SpotlightIndexService.shared.removeIndex(for: item)
///
/// // 批量重建索引
/// await SpotlightIndexService.shared.reindexAll(items)
/// ```
@MainActor
final class SpotlightIndexService {
    
    // MARK: - Singleton
    
    static let shared = SpotlightIndexService()
    
    private init() {}
    
    // MARK: - Constants
    
    /// 索引域标识符
    private let domainIdentifier = "com.notbad.reviewitem"
    
    /// 内容类型
    private let contentType = UTType.text
    
    // MARK: - Indexing
    
    /// 索引单个错题
    ///
    /// - Parameter item: 要索引的错题
    func index(_ item: ReviewItem) {
        let searchableItem = createSearchableItem(from: item)
        
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { error in
            if let error {
                Logger.search.error("Spotlight 索引失败: \(error.localizedDescription)")
            } else {
                Logger.search.debug("Spotlight 已索引: \(item.title)")
            }
        }
    }
    
    /// 批量索引错题
    ///
    /// - Parameter items: 要索引的错题列表
    func index(_ items: [ReviewItem]) {
        guard !items.isEmpty else { return }
        
        let searchableItems = items.map { createSearchableItem(from: $0) }
        
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error {
                Logger.search.error("Spotlight 批量索引失败: \(error.localizedDescription)")
            } else {
                Logger.search.info("Spotlight 已索引 \(items.count) 条错题")
            }
        }
    }
    
    /// 更新错题索引
    ///
    /// - Parameter item: 要更新的错题
    func update(_ item: ReviewItem) {
        // 索引操作会自动覆盖相同 ID 的项
        index(item)
    }
    
    /// 移除单个错题的索引
    ///
    /// - Parameter item: 要移除索引的错题
    func removeIndex(for item: ReviewItem) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: [item.id.uuidString]
        ) { error in
            if let error {
                Logger.search.error("Spotlight 删除索引失败: \(error.localizedDescription)")
            } else {
                Logger.search.debug("Spotlight 已删除索引: \(item.title)")
            }
        }
    }
    
    /// 移除多个错题的索引
    ///
    /// - Parameter items: 要移除索引的错题列表
    func removeIndex(for items: [ReviewItem]) {
        let identifiers = items.map { $0.id.uuidString }
        
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: identifiers
        ) { error in
            if let error {
                Logger.search.error("Spotlight 批量删除索引失败: \(error.localizedDescription)")
            } else {
                Logger.search.info("Spotlight 已删除 \(items.count) 条索引")
            }
        }
    }
    
    /// 清除所有索引
    func clearAllIndexes() {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [domainIdentifier]
        ) { error in
            if let error {
                Logger.search.error("Spotlight 清除索引失败: \(error.localizedDescription)")
            } else {
                Logger.search.info("Spotlight 已清除所有索引")
            }
        }
    }
    
    /// 重建所有索引
    ///
    /// - Parameter items: 所有错题
    func reindexAll(_ items: [ReviewItem]) async {
        // 先清除旧索引
        await withCheckedContinuation { continuation in
            CSSearchableIndex.default().deleteSearchableItems(
                withDomainIdentifiers: [domainIdentifier]
            ) { _ in
                continuation.resume()
            }
        }
        
        // 重新索引
        index(items)
        Logger.search.info("Spotlight 重建索引完成: \(items.count) 条")
    }
    
    // MARK: - Private Helpers
    
    /// 创建可搜索项
    private func createSearchableItem(from item: ReviewItem) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: contentType)
        
        // 基本信息
        attributeSet.title = item.title
        attributeSet.contentDescription = createDescription(for: item)
        
        // 关键词（用于搜索匹配）
        var keywords = item.knowledgePoints.items
        keywords.append(item.subject.displayName)
        keywords.append(item.grade.displayName)
        if !item.note.isEmpty {
            // 提取笔记中的关键词（前 100 个字符）
            let noteKeywords = String(item.note.prefix(100))
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count > 1 }
            keywords.append(contentsOf: noteKeywords.prefix(10))
        }
        attributeSet.keywords = keywords
        
        // 缩略图（如果有图片）
        if let imageData = item.imageData,
           let image = UIImage(data: imageData) {
            // 生成小缩略图用于搜索结果显示
            let thumbnail = generateThumbnail(from: image, maxSize: 120)
            attributeSet.thumbnailData = thumbnail
        }
        
        // 时间戳
        attributeSet.contentCreationDate = item.createdAt
        attributeSet.contentModificationDate = item.updatedAt
        
        // 自定义属性
        attributeSet.subject = item.subject.displayName
        
        return CSSearchableItem(
            uniqueIdentifier: item.id.uuidString,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
    }
    
    /// 创建搜索结果描述
    private func createDescription(for item: ReviewItem) -> String {
        var parts: [String] = []
        
        // 学科和年级
        parts.append("\(item.subject.displayName) · \(item.grade.displayName)")
        
        // 知识点
        if !item.knowledgePoints.isEmpty {
            parts.append("知识点: \(item.knowledgePoints.items.prefix(3).joined(separator: ", "))")
        }
        
        // 笔记预览
        if !item.note.isEmpty {
            let preview = String(item.note.prefix(50))
            parts.append(preview)
        }
        
        return parts.joined(separator: "\n")
    }
    
    /// 生成缩略图
    private func generateThumbnail(from image: UIImage, maxSize: CGFloat) -> Data? {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return thumbnail.jpegData(compressionQuality: 0.6)
    }
}

// MARK: - Deep Link Handling

extension SpotlightIndexService {
    
    /// 处理 Spotlight 搜索结果点击
    ///
    /// - Parameter userActivity: 用户活动
    /// - Returns: 错题 ID（如果是 Spotlight 搜索结果）
    static func handleSpotlightActivity(_ userActivity: NSUserActivity) -> UUID? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              let uuid = UUID(uuidString: identifier) else {
            return nil
        }
        
        Logger.search.debug("Spotlight 点击: \(identifier)")
        return uuid
    }
}

