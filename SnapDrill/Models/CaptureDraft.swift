import Foundation
import SwiftData

/// PRD §8.6 — 步骤 2/3 未保存草稿
@Model
final class CaptureDraft {
    var id: UUID
    var updatedAt: Date
    var stepRaw: Int
    var payloadJSON: Data?

    init(step: CaptureDraftStep) {
        self.id = UUID()
        self.updatedAt = .now
        self.stepRaw = step.rawValue
    }

    var step: CaptureDraftStep {
        get { CaptureDraftStep(rawValue: stepRaw) ?? .crop }
        set {
            stepRaw = newValue.rawValue
            updatedAt = .now
        }
    }
}

enum CaptureDraftStep: Int, Codable {
    case crop = 2
    case info = 3
}