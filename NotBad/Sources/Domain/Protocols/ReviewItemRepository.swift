import Foundation
import SwiftData

/// ReviewItem仓库协议
protocol ReviewItemRepository: Sendable {
    /// 创建复习项
    func createReviewItem(_ content: ReviewContent, metadata: ReviewItemMetadata) async throws -> ReviewItem
    
    /// 获取复习项列表
    func getReviewItems(predicate: Predicate<ReviewItem>?, sortBy: [SortDescriptor<ReviewItem>]) async throws -> [ReviewItem]
    
    /// 更新复习项
    func updateReviewItem(_ item: ReviewItem) async throws
    
    /// 删除复习项
    func deleteReviewItem(id: UUID) async throws
    
    /// 根据ID获取复习项
    func getReviewItem(id: UUID) async throws -> ReviewItem?
}

/// 创建复习项用例协议
protocol CreateReviewItemUseCase: Sendable {
    func execute(imageData: Data?, recognizedText: String, userNotes: String, subject: String, tags: [String]) async throws -> ReviewItem
}

/// 获取复习项用例协议
protocol GetReviewItemsUseCase: Sendable {
    func execute(predicate: Predicate<ReviewItem>?, sortBy: [SortDescriptor<ReviewItem>]) async throws -> [ReviewItem]
}
