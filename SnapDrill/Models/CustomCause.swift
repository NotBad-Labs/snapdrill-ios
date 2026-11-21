import Foundation
import SwiftData

/// User-defined mistake cause beyond the 6 built-in MistakeCause options (PRD F-21, F-61).
@Model
final class CustomCause {
    var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
