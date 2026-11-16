import Foundation

enum CapturePipelineFactory {
    /// App 注入点；测试可换 Stub。
    static func makeDefault() -> any CapturePipelineServing {
        CapturePipelineLive()
    }
}