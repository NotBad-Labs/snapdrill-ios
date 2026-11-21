import Foundation
import SwiftData

/// User-defined topic, exam, or textbook unit tag attached to MistakeItem records.
@Model
final class MistakeTag {
    var id: UUID
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \MistakeItem.tags)
    var mistakes: [MistakeItem] = []

    init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
