import Foundation
import SwiftData

/// CloudKit-compatible topic, exam, or textbook unit tag attached to MistakeItem records.
@Model
final class MistakeTag {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \MistakeItem.tags)
    var mistakes: [MistakeItem]? = []

    var mistakeList: [MistakeItem] {
        get { mistakes ?? [] }
        set { mistakes = newValue }
    }

    init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
