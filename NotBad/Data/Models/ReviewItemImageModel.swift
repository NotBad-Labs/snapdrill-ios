//
//  ReviewItemImageModel.swift
//  NotBad
//
//  独立的图片存储模型 - 支持懒加载
//

import Foundation
import SwiftData

// MARK: - ReviewItemImageModel

/// 错题图片持久化模型
///
/// 将图片数据与 ReviewItemModel 分离存储，支持按需懒加载。
/// 避免在加载列表时将所有图片数据加载到内存。
///
/// ## 设计原则
///
/// - **独立存储**：图片数据独立于主模型，按需加载
/// - **外部存储**：使用 `.externalStorage` 将大数据存储在文件系统
/// - **一对一关系**：与 ReviewItemModel 通过 reviewItemId 关联
///
/// ## 使用场景
///
/// ```swift
/// // 列表页：不加载图片
/// let items = repository.fetchAll() // imageData 不加载
///
/// // 详情页：按需加载图片
/// let imageData = imageRepository.loadImage(for: item.id)
/// ```
@Model
final class ReviewItemImageModel {
    
    // MARK: - Properties
    
    /// 唯一标识符（与 ReviewItem 共享相同 ID）
    @Attribute(.unique)
    var reviewItemId: UUID
    
    /// 图片数据（外部存储）
    @Attribute(.externalStorage)
    var imageData: Data
    
    /// 创建时间
    var createdAt: Date
    
    // MARK: - Initialization
    
    /// 创建图片存储模型
    ///
    /// - Parameters:
    ///   - reviewItemId: 关联的 ReviewItem ID
    ///   - imageData: 图片数据
    init(reviewItemId: UUID, imageData: Data) {
        self.reviewItemId = reviewItemId
        self.imageData = imageData
        self.createdAt = Date()
    }
}
