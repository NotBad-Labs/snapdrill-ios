//
//  ImageRepositoryProtocol.swift
//  NotBad
//
//  图片仓库协议 - 支持按需加载
//

import Foundation

// MARK: - ImageRepositoryProtocol

/// 图片仓库协议
///
/// 定义图片数据的加载和存储接口。
/// 图片与 ReviewItem 分离存储，支持懒加载。
///
/// ## 设计原则
///
/// - **按需加载**：只在需要显示时加载图片数据
/// - **内存友好**：避免一次性加载所有图片到内存
/// - **异步操作**：支持异步加载大文件
///
/// ## 使用示例
///
/// ```swift
/// // 详情页加载图片
/// if let imageData = await imageRepository.loadImage(for: item.id) {
///     imageView.image = UIImage(data: imageData)
/// }
///
/// // 保存图片
/// try await imageRepository.saveImage(imageData, for: item.id)
/// ```
@MainActor
protocol ImageRepositoryProtocol: AnyObject, Sendable {
    
    // MARK: - Load Operations
    
    /// 加载指定 ReviewItem 的图片数据
    ///
    /// - Parameter reviewItemId: ReviewItem 的 ID
    /// - Returns: 图片数据，不存在则返回 nil
    func loadImage(for reviewItemId: UUID) -> Data?
    
    /// 检查是否存在图片
    ///
    /// - Parameter reviewItemId: ReviewItem 的 ID
    /// - Returns: 是否存在图片
    func hasImage(for reviewItemId: UUID) -> Bool
    
    // MARK: - Save Operations
    
    /// 保存图片数据
    ///
    /// - Parameters:
    ///   - imageData: 图片数据
    ///   - reviewItemId: 关联的 ReviewItem ID
    /// - Throws: 保存失败时抛出错误
    func saveImage(_ imageData: Data, for reviewItemId: UUID) throws
    
    /// 更新图片数据
    ///
    /// - Parameters:
    ///   - imageData: 新的图片数据
    ///   - reviewItemId: 关联的 ReviewItem ID
    /// - Throws: 更新失败时抛出错误
    func updateImage(_ imageData: Data, for reviewItemId: UUID) throws
    
    // MARK: - Delete Operations
    
    /// 删除图片数据
    ///
    /// - Parameter reviewItemId: ReviewItem 的 ID
    /// - Throws: 删除失败时抛出错误
    func deleteImage(for reviewItemId: UUID) throws
    
    /// 批量删除图片数据
    ///
    /// - Parameter reviewItemIds: ReviewItem ID 列表
    /// - Throws: 删除失败时抛出错误
    func deleteImages(for reviewItemIds: [UUID]) throws
}
