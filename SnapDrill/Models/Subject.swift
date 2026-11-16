import Foundation
import SwiftData

@Model
final class Subject {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    var isBuiltin: Bool
    /// PRD §8.6 — 系统保底「未分类」，不可删（无题时不展示）
    var isUncategorizedBucket: Bool
    var createdAt: Date

  @Relationship(deleteRule: .nullify, inverse: \MistakeItem.subject)
    var mistakes: [MistakeItem]

    init(
        name: String,
        colorHex: String,
        sortOrder: Int,
        isBuiltin: Bool = false,
        isUncategorizedBucket: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isBuiltin = isBuiltin
        self.isUncategorizedBucket = isUncategorizedBucket
        self.createdAt = .now
        self.mistakes = []
    }

    var mistakeCount: Int { mistakes.count }
}