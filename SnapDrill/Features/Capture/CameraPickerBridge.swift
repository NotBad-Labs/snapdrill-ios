import SwiftUI
import UIKit

/// SwiftUI host for the live batch document scanner (the AVFoundation/Vision implementation lives in Services/Capture).
struct CameraPickerBridge: UIViewControllerRepresentable {
    let maxPhotos: Int
    let onFinishBatch: ([Data]) -> Void
    let onRequestPhotoLibrary: () -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        CapturePipelineFactory.makeLiveDocumentCameraViewController(
            maxPhotos: maxPhotos,
            onFinishBatch: onFinishBatch,
            onRequestPhotoLibrary: onRequestPhotoLibrary,
            onCancel: onCancel
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
