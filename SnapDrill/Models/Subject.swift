import Foundation
import SwiftData

/// Mistake notebook subject container (e.g. Math, Physics, English) plus a hidden fallback uncategorized bucket.
@Model
final class Subject {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    var isBuiltin: Bool
    /// PRD §8.6: System fallback bucket ("Uncategorized"), cannot be deleted and hidden on Home when empty.
    var isUncategorizedBucket: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \MistakeItem.subject)
    var mistakes: [MistakeItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "2C5689",
        sortOrder: Int = 0,
        isBuiltin: Bool = false,
        isUncategorizedBucket: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isBuiltin = isBuiltin
        self.isUncategorizedBucket = isUncategorizedBucket
        self.createdAt = createdAt
    }
}
