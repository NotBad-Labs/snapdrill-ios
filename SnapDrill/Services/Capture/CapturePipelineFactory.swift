import Foundation

/// Central factory assembling live or stub capture pipelines cleanly.
enum CapturePipelineFactory {
    static func makeLivePipeline() -> CapturePipelineServing {
        CapturePipelineLive()
    }

    static func makeStubPipeline() -> CapturePipelineServing {
        CapturePipelineStub()
    }

    static func makeCameraAccessChecker() -> CameraAccessChecking {
        CameraAccessService()
    }

    static func makeDraftStore() -> CaptureDraftPersisting {
        CaptureDraftStore()
    }
}
