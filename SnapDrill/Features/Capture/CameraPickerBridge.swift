import SwiftUI
import UIKit

/// UIImagePickerController wrapper for camera capture (keeps AVFoundation out of Features/Capture).
struct CameraPickerBridge: UIViewControllerRepresentable {
    let onCapture: (Data?) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerBridge

        init(parent: CameraPickerBridge) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            let data = image?.jpegData(compressionQuality: 0.90)
            parent.dismiss()
            parent.onCapture(data)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
            parent.onCapture(nil)
        }
    }
}
