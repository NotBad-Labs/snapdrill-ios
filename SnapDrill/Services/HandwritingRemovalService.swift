import CoreImage
import UIKit

/// 阶段 0 完成后替换为真实 Core ML 管线（PRD §10）。
enum HandwritingRemovalService {
    static let failureTimeout: Duration = .seconds(3)

    enum Outcome: Sendable {
        case cleaned(UIImage)
        case fallbackEnhancedOriginal(UIImage, message: String)
    }

    static func process(image: UIImage) async -> Outcome {
        // TODO(阶段0): 接入分割模型，Neural Engine 推理
        try? await Task.sleep(for: .milliseconds(200))
        guard let enhanced = ImageEnhancementService.enhanced(image) else {
            return .fallbackEnhancedOriginal(
                image,
                message: String(localized: "Couldn’t remove handwriting; kept the original.")
            )
        }
        return .fallbackEnhancedOriginal(
            enhanced,
            message: String(localized: "Couldn’t remove handwriting; kept the enhanced original.")
        )
    }
}