import Foundation
import SwiftData

enum CapturePipelineFactory {
    /// App 注入点；测试可换 `CapturePipelineStub`。
    @MainActor
    static func makeDefault(modelContext: ModelContext) -> any CapturePipelineServing {
        CapturePipelineLive.make(modelContext: modelContext)
    }
}