import Foundation
import SwiftData

/// CloudKit-compatible user-defined mistake cause beyond the 6 built-in options (PRD F-21, F-61).
@Model
final class CustomCause {
    var id: UUID = UUID()
    var name: String = ""
    var sortOrder: Int = 0
    var createdAt: Date = Date.now

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
