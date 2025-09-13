//
//  CreateReviewItemUseCase.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation

// MARK: - 创建复习项用例实现
/// 创建复习项用例的具体实现
/// 遵循Clean Architecture的Application层设计原则
class CreateReviewItemUseCaseImpl: CreateReviewItemUseCase {
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    /// 执行创建复习项操作
    func execute(_ request: CreateReviewItemRequest) async throws -> CreateReviewItemResponse {
        // 1. 验证输入数据
        try validateRequest(request)
        
        // 2. 创建复习项实体
        let reviewItem = createReviewItem(from: request)
        
        // 3. 保存到仓储
        do {
            let createdItem = try await repository.create(reviewItem)
            return CreateReviewItemResponse(reviewItem: createdItem)
        } catch {
            throw ReviewItemUseCaseError.repositoryError("创建复习项失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 私有方法
    
    /// 验证创建请求
    private func validateRequest(_ request: CreateReviewItemRequest) throws {
        guard !request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReviewItemUseCaseError.validationFailed("标题不能为空")
        }
        
        guard !request.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReviewItemUseCaseError.validationFailed("题目不能为空")
        }
        
        guard !request.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReviewItemUseCaseError.validationFailed("科目不能为空")
        }
        
        // 验证标题长度
        if request.title.count > 100 {
            throw ReviewItemUseCaseError.validationFailed("标题长度不能超过100个字符")
        }
        
        // 验证题目长度
        if request.question.count > 5000 {
            throw ReviewItemUseCaseError.validationFailed("题目长度不能超过5000个字符")
        }
    }
    
    /// 从请求创建复习项实体
    private func createReviewItem(from request: CreateReviewItemRequest) -> ReviewItem {
        let content = ReviewContent(
            title: request.title,
            question: request.question,
            answer: request.answer,
            explanation: request.explanation,
            imageData: request.imageData,
            subject: request.subject,
            difficulty: request.difficulty,
            tags: request.tags
        )
        
        let metadata = ReviewMetadata(
            ownerId: request.ownerId,
            source: request.source
        )
        
        return ReviewItem(
            content: content,
            metadata: metadata
        )
    }
}
