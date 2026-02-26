//
//  ImageCropperView.swift
//  SnapDrillUI
//
//  Shared component,//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  图片裁剪视图，基于 Mantis 库封装 (或其他裁剪库)。
//

import SwiftUI
import UIKit
#if canImport(UIKit)
import Mantis
#endif

/// 9-Grid Image Cropper using Mantis library
///
/// Features:
/// - Robust cropping with rotation, aspect ratios, and more
/// - Powered by Mantis (https://github.com/guoyingqi/Mantis)
#if canImport(UIKit)
public struct ImageCropperView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    let originalImage: UIImage
    // Changed to public for external access
    public var onCrop: (UIImage) -> Void
    public var onCancel: () -> Void
    
    public init(originalImage: UIImage, onCrop: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.originalImage = originalImage
        self.onCrop = onCrop
        self.onCancel = onCancel
    }
    
    // MARK: - UIViewControllerRepresentable
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(onCrop: onCrop, onCancel: onCancel)
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.cropToolbarConfig.mode = .normal
        
        let cropViewController = Mantis.cropViewController(image: originalImage, config: config)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    public class Coordinator: NSObject, CropViewControllerDelegate {
        var onCrop: (UIImage) -> Void
        var onCancel: () -> Void
        
        public init(onCrop: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onCrop = onCrop
            self.onCancel = onCancel
        }
        
        public func cropViewControllerDidCrop(
            _ cropViewController: CropViewController,
            cropped: UIImage,
            transformation: Transformation,
            cropInfo: CropInfo
        ) {
            onCrop(cropped)
        }
        
        public func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
            onCancel()
        }
        
        public func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
            onCancel()
        }
        
        public func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {
        }
        
        public func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
        }
    }
}
#else
public struct ImageCropperView: View {
    public init(originalImage: Any, onCrop: @escaping (Any) -> Void, onCancel: @escaping () -> Void) {}
    public var body: some View {
        Text("Image cropping is only supported on iOS")
    }
}
#endif
