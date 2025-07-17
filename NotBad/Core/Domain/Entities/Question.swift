//
//  Question.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation
import SwiftData

@Model
class Question {
    @Attribute(.unique) var id: UUID
    var content: String
    var answer: String
    var createdAt: Date
    @Attribute var tags: [String]  // ← 添加 @Attribute
    var wrongReason: String?  // 错因，可选
    var difficulty: Int       // 难度，1-5分
    var isReviewed: Bool
    var reviewedAt: Date?
    var reviewCount: Int

    init(
        id: UUID = UUID(),
        content: String,
        answer: String,
        createdAt: Date = .now,
        tags: [String] = [],
        wrongReason: String? = nil,
        difficulty: Int = 3,
        isReviewed: Bool = false,
        reviewedAt: Date? = nil,
        reviewCount: Int = 0
    ) {
        self.id = id
        self.content = content
        self.answer = answer
        self.createdAt = createdAt
        self.tags = tags
        self.wrongReason = wrongReason
        self.difficulty = difficulty
        self.isReviewed = isReviewed
        self.reviewedAt = reviewedAt
        self.reviewCount = reviewCount
    }
}
