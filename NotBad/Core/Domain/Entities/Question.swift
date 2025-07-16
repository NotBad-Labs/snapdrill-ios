import Foundation
import SwiftData

@Model
class Question {
    @Attribute(.unique) var id: UUID
    var content: String
    var answer: String
    var createdAt: Date
    var tags: [String]

    init(
        id: UUID = UUID(),
        content: String,
        answer: String,
        createdAt: Date = .now,
        tags: [String] = []
    ) {
        self.id = id
        self.content = content
        self.answer = answer
        self.createdAt = createdAt
        self.tags = tags
    }
}