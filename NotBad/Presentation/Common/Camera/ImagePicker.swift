//
//  ImagePicker.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import UIKit

// MARK: - ImagePicker

/// 相机/相册图片选择器
///
/// 封装 `UIImagePickerController`，提供 SwiftUI 友好的接口。
///
/// ## 使用示例
///
/// ```swift
/// struct ContentView: View {
///     @State private var showCamera = false
///     @State private var selectedImage: UIImage?
///
///     var body: some View {
///         Button("拍照") {
///             showCamera = true
///         }
///         .sheet(isPresented: $showCamera) {
///             ImagePicker(sourceType: .camera) { image in
///                 selectedImage = image
///             }
///         }
///     }
/// }
/// ```
///
/// - Note: 使用相机需要在 Info.plist 添加 `NSCameraUsageDescription`
struct ImagePicker: UIViewControllerRepresentable {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// 图片来源类型
    let sourceType: UIImagePickerController.SourceType

    /// 是否允许编辑
    var allowsEditing: Bool = false

    /// 图片选择回调
    let onImagePicked: (UIImage) -> Void

    /// 取消回调（可选）
    var onCancel: (() -> Void)?

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = allowsEditing

        // 相机模式下的额外配置
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraFlashMode = .auto
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 无需更新
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    /// 协调器，处理 UIImagePickerController 的代理回调
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        private let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // 根据是否允许编辑选择图片
            let key: UIImagePickerController.InfoKey = parent.allowsEditing ? .editedImage : .originalImage

            if let image = info[key] as? UIImage {
                // 修正图片方向
                let correctedImage = image.fixedOrientation()
                parent.onImagePicked(correctedImage)
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel?()
            parent.dismiss()
        }
    }
}

// MARK: - ImagePicker Convenience Initializers

extension ImagePicker {

    /// 创建相机选择器
    ///
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - onImagePicked: 图片选择回调
    /// - Returns: 配置好的 ImagePicker
    static func camera(
        allowsEditing: Bool = false,
        onImagePicked: @escaping (UIImage) -> Void
    ) -> ImagePicker {
        ImagePicker(
            sourceType: .camera,
            allowsEditing: allowsEditing,
            onImagePicked: onImagePicked
        )
    }

    /// 创建相册选择器
    ///
    /// - Parameters:
    ///   - allowsEditing: 是否允许编辑
    ///   - onImagePicked: 图片选择回调
    /// - Returns: 配置好的 ImagePicker
    static func photoLibrary(
        allowsEditing: Bool = false,
        onImagePicked: @escaping (UIImage) -> Void
    ) -> ImagePicker {
        ImagePicker(
            sourceType: .photoLibrary,
            allowsEditing: allowsEditing,
            onImagePicked: onImagePicked
        )
    }
}

// MARK: - ImagePicker Availability

extension ImagePicker {

    /// 检查相机是否可用
    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// 检查相册是否可用
    static var isPhotoLibraryAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
}

// MARK: - UIImage Extension

private extension UIImage {

    /// 修正图片方向
    ///
    /// 相机拍摄的图片可能带有方向元数据，此方法将其转换为正确方向。
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}
