import Foundation
import SwiftData

/// CloudKit-compatible mistake notebook subject container plus hidden fallback uncategorized bucket.
@Model
final class Subject {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "2C5689"
    var sortOrder: Int = 0
    var isBuiltin: Bool = false
    /// PRD §8.6: System fallback bucket ("Uncategorized"), cannot be deleted and hidden on Home when empty.
    var isUncategorizedBucket: Bool = false
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \MistakeItem.subject)
    var mistakes: [MistakeItem]? = []

    var mistakeList: [MistakeItem] {
        get { mistakes ?? [] }
        set { mistakes = newValue }
    }

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
