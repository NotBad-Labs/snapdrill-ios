import Foundation
import UIKit

/// 创建复习项用例实现
@MainActor
class CreateReviewItemUseCaseImpl: CreateReviewItemUseCase {
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    nonisolated func execute(imageData: Data?, recognizedText: String, userNotes: String, subject: String, tags: [String]) async throws -> ReviewItem {
        // 1. 创建ReviewContent
        let content = ReviewContent(
            imageData: imageData,
            recognizedText: recognizedText,
            userNotes: userNotes,
            subject: subject,
            tags: tags,
            difficulty: .medium // 默认中等难度
        )
        
        // 2. 创建ReviewItemMetadata
        let metadata = ReviewItemMetadata(
            ownerId: await getCurrentUserId(),
            parentShareStatus: .none,
            parentAccessRevokedAt: nil,
            sharedWithClassIds: [],
            isArchived: false
        )
        
        // 3. 保存到数据库
        let reviewItem = try await self.repository.createReviewItem(content, metadata: metadata)
        
        return reviewItem
    }
    
    private func getCurrentUserId() async -> UUID {
        // TODO: 实现用户ID获取逻辑
        // 目前返回一个固定的UUID，后续需要集成用户认证系统
        return UUID()
    }
}

/// 获取复习项用例实现
@MainActor
class GetReviewItemsUseCaseImpl: GetReviewItemsUseCase {
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    nonisolated func execute(predicate: Predicate<ReviewItem>?, sortBy: [SortDescriptor<ReviewItem>]) async throws -> [ReviewItem] {
        return try await self.repository.getReviewItems(predicate: predicate, sortBy: sortBy)
    }
}
