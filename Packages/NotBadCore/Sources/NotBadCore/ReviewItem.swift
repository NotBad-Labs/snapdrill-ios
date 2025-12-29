import Foundation

/// 表示一个高价值的复习题目实体
public struct ReviewItem: Sendable, Identifiable, Codable {
    public let id: UUID
    public var content: String
    public var imagePath: String?
    public var createdAt: Date
    public var lastReviewedAt: Date?
    
    public init(
        id: UUID = UUID(),
        content: String,
        imagePath: String? = nil,
        createdAt: Date = Date(),
        lastReviewedAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.imagePath = imagePath
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
    }
}

/// 题目所属的学科类型
public enum Subject: String, Sendable, Codable, CaseIterable {
    case mathematics = "math"
    case physics = "physics"
    case chemistry = "chemistry"
    case english = "english"
    case other = "other"
}
