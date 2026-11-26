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
        onRequestPhotoLibrary: @escaping ([Data]) -> Void,
        onCancel: @escaping () -> Void
    ) -> UIViewController {
        LiveDocumentCameraController(
            maxPhotos: maxPhotos,
            onFinishBatch: onFinishBatch,
            onRequestPhotoLibrary: onRequestPhotoLibrary,
            onCancel: onCancel
        )
    }

    /// Decodes a compact upright thumbnail via ImageIO so capture views never decode full JPEGs on MainActor.
    nonisolated static func makePageThumbnail(from imageData: Data, maxPixel: Int = 160) -> UIImage? {
        PhotoDataSanitizer.makeThumbnailImage(from: imageData, maxPixel: maxPixel)
    }
}
