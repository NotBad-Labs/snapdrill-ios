//
//  CreateReviewItemUseCase.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation

// MARK: - 创建复习项用例
/// 创建复习项的用例，封装创建复习项的业务逻辑
/// 遵循Clean Architecture的Application层设计原则
class CreateReviewItemUseCase {
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    /// 执行创建复习项操作
    /// - Parameter request: 创建请求
    /// - Returns: 创建成功的复习项
    /// - Throws: 创建失败时抛出错误
    func execute(_ request: CreateReviewItemRequest) async throws -> ReviewItem {
        // 1. 验证输入数据
        try validateRequest(request)
        
        // 2. 创建复习项实体
        let reviewItem = createReviewItem(from: request)
        
        // 3. 保存到仓储
        let createdItem = try await repository.create(reviewItem)
        
        return createdItem
    }
    
    // MARK: - 私有方法
    
    /// 验证创建请求
    private func validateRequest(_ request: CreateReviewItemRequest) throws {
        guard !request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CreateReviewItemError.invalidTitle("标题不能为空")
        }
        
        guard !request.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CreateReviewItemError.invalidQuestion("题目不能为空")
        }
        
        guard !request.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CreateReviewItemError.invalidSubject("科目不能为空")
        }
        
        // 验证标题长度
        if request.title.count > 100 {
            throw CreateReviewItemError.invalidTitle("标题长度不能超过100个字符")
        }
        
        // 验证题目长度
        if request.question.count > 5000 {
            throw CreateReviewItemError.invalidQuestion("题目长度不能超过5000个字符")
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

// MARK: - 创建复习项请求
/// 创建复习项的请求参数
struct CreateReviewItemRequest {
    let title: String
    let question: String
    let answer: String?
    let explanation: String?
    let imageData: Data?
    let subject: String
    let difficulty: DifficultyLevel
    let tags: [String]
    let ownerId: UUID
    let source: ItemSource
    
    init(
        title: String,
        question: String,
        answer: String? = nil,
        explanation: String? = nil,
        imageData: Data? = nil,
        subject: String,
        difficulty: DifficultyLevel = .medium,
        tags: [String] = [],
        ownerId: UUID,
        source: ItemSource = .manual
    ) {
        self.title = title
        self.question = question
        self.answer = answer
        self.explanation = explanation
        self.imageData = imageData
        self.subject = subject
        self.difficulty = difficulty
        self.tags = tags
        self.ownerId = ownerId
        self.source = source
    }
}

// MARK: - 创建复习项错误类型
/// 创建复习项操作可能出现的错误类型
enum CreateReviewItemError: Error, LocalizedError {
    case invalidTitle(String)
    case invalidQuestion(String)
    case invalidSubject(String)
    case invalidAnswer(String)
    case invalidImageData(String)
    case repositoryError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidTitle(let message):
            return "标题无效: \(message)"
        case .invalidQuestion(let message):
            return "题目无效: \(message)"
        case .invalidSubject(let message):
            return "科目无效: \(message)"
        case .invalidAnswer(let message):
            return "答案无效: \(message)"
        case .invalidImageData(let message):
            return "图片数据无效: \(message)"
        case .repositoryError(let message):
            return "存储错误: \(message)"
        }
    }
}
