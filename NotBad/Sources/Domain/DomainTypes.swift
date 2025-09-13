//
//  DomainTypes.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/9/12.
//

import Foundation

// MARK: - 前向声明和简化数据模型
/// 用于CloudKit同步的简化复习项数据模型
/// 这个模型避免了复杂的关联和嵌套结构，便于CloudKit处理
public struct SimpleReviewItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var questionText: String
    public var answerText: String
    public var subject: String
    public var difficultyLevel: DifficultyLevel
    public var masteryLevel: MasteryLevel
    public var tags: [String]
    public var imageURLs: [String]
    public let createdAt: Date
    public var updatedAt: Date
    public var lastReviewedAt: Date?
    
    public init(
        id: UUID = UUID(),
        title: String,
        questionText: String,
        answerText: String = "",
        subject: String = "",
        difficultyLevel: DifficultyLevel = .medium,
        masteryLevel: MasteryLevel = .notMastered,
        tags: [String] = [],
        imageURLs: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastReviewedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.questionText = questionText
        self.answerText = answerText
        self.subject = subject
        self.difficultyLevel = difficultyLevel
        self.masteryLevel = masteryLevel
        self.tags = tags
        self.imageURLs = imageURLs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastReviewedAt = lastReviewedAt
    }
}

// MARK: - SimpleReviewItem Conversion Extensions
extension SimpleReviewItem {
    /// 从原始ReviewItem转换为SimpleReviewItem
    public init(from reviewItem: ReviewItem) {
        self.init(
            id: reviewItem.id,
            title: reviewItem.content.title,
            questionText: reviewItem.content.question,
            answerText: reviewItem.content.answer ?? "",
            subject: reviewItem.content.subject,
            difficultyLevel: reviewItem.content.difficulty,
            masteryLevel: reviewItem.masteryLevel,
            tags: reviewItem.content.tags,
            imageURLs: [], // 简化：暂时不处理图片
            createdAt: reviewItem.metadata.createdAt,
            updatedAt: reviewItem.metadata.updatedAt,
            lastReviewedAt: nil // 简化：从学习历史中获取会更复杂
        )
    }
    
    /// 转换为完整的ReviewItem
    public func toReviewItem() -> ReviewItem {
        let content = ReviewContent(
            title: self.title,
            question: self.questionText,
            answer: self.answerText.isEmpty ? nil : self.answerText,
            subject: self.subject,
            difficulty: self.difficultyLevel,
            tags: self.tags
        )
        
        let metadata = ReviewMetadata(
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            ownerId: UUID() // 简化：使用默认UUID，实际应该传入真实的用户ID
        )
        
        return ReviewItem(
            id: self.id,
            content: content,
            metadata: metadata,
            studyHistory: [],
            masteryLevel: self.masteryLevel
        )
    }
}

// MARK: - 枚举类型定义
// 注意：MasteryLevel 和 ParentShareStatus 已在 ReviewItem.swift 中定义

public enum StudyResult: String, Codable, CaseIterable {
    case correct = "correct"
    case incorrect = "incorrect"
    case partial = "partial"
    case skipped = "skipped"
}

// MARK: - 错误类型定义
public enum NetworkError: Error {
    case noConnection
    case timeout
    case invalidResponse
}

public enum SyncError: Error {
    case conflictDetected
    case quotaExceeded
    case cloudKitUnavailable
}
