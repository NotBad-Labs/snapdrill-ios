//
//  UpdateReviewItemUseCaseProtocol.swift
//  NotBad
//
//  Domain Layer - Use Case Protocol
//

import Foundation

// MARK: - UpdateReviewItemUseCaseProtocol

/// 更新错题用例协议
///
/// 负责更新已有错题的信息：
/// - 验证更新数据
/// - 处理图片变更
/// - 保存更新
///
/// ## 使用示例
///
/// ```swift
/// let useCase = dependencies.makeUpdateReviewItemUseCase()
/// try await useCase.execute(
///     itemId: item.id,
///     updates: .init(title: "新标题", difficulty: .hard)
/// )
/// ```
@MainActor
protocol UpdateReviewItemUseCaseProtocol: Sendable {
    
    /// 更新错题
    ///
    /// - Parameters:
    ///   - itemId: 题目 ID
    ///   - updates: 更新内容
    /// - Returns: 更新后的错题
    /// - Throws: 更新失败时抛出错误
    @discardableResult
    func execute(
        itemId: UUID,
        updates: ReviewItemUpdates
    ) async throws -> ReviewItem
}

// MARK: - ReviewItemUpdates

/// 错题更新内容
///
/// 只包含需要更新的字段，`nil` 表示不更新。
struct ReviewItemUpdates: Sendable {
    
    /// 新标题
    var title: String?
    
    /// 新图片数据
    var imageData: Data?
    
    /// 是否删除图片
    var removeImage: Bool
    
    /// 新学科
    var subject: Subject?
    
    /// 新年级
    var grade: Grade?
    
    /// 新难度
    var difficulty: Difficulty?
    
    /// 新错误类型
    var errorType: ErrorType?
    
    /// 新知识点
    var knowledgePoints: [String]?
    
    /// 新备注
    var note: String?
    
    /// 新掌握程度
    var mastery: MasteryLevel?
    
    // MARK: - Initialization
    
    init(
        title: String? = nil,
        imageData: Data? = nil,
        removeImage: Bool = false,
        subject: Subject? = nil,
        grade: Grade? = nil,
        difficulty: Difficulty? = nil,
        errorType: ErrorType? = nil,
        knowledgePoints: [String]? = nil,
        note: String? = nil,
        mastery: MasteryLevel? = nil
    ) {
        self.title = title
        self.imageData = imageData
        self.removeImage = removeImage
        self.subject = subject
        self.grade = grade
        self.difficulty = difficulty
        self.errorType = errorType
        self.knowledgePoints = knowledgePoints
        self.note = note
        self.mastery = mastery
    }
    
    /// 是否有任何更新
    var hasUpdates: Bool {
        title != nil ||
        imageData != nil ||
        removeImage ||
        subject != nil ||
        grade != nil ||
        difficulty != nil ||
        errorType != nil ||
        knowledgePoints != nil ||
        note != nil ||
        mastery != nil
    }
}
