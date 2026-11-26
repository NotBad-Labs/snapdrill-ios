import Foundation
import UIKit

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

    /// Live batch document scanner (AVFoundation + Vision stay inside Services/Capture).
    @MainActor
    static func makeLiveDocumentCameraViewController(
        maxPhotos: Int,
        onFinishBatch: @escaping ([Data]) -> Void,
        onRequestPhotoLibrary: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> UIViewController {
        LiveDocumentCameraController(
            maxPhotos: maxPhotos,
            onFinishBatch: onFinishBatch,
            onRequestPhotoLibrary: onRequestPhotoLibrary,
            onCancel: onCancel
        )
    }
}
