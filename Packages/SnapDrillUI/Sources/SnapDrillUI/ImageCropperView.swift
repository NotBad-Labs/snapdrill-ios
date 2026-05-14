//
//  ImageCropperView.swift
//  SnapDrillUI
//
//  Shared component,//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  图片裁剪视图，基于 Mantis 库封装 (或其他裁剪库)。
//

import SwiftUI
import UIKit
import Mantis

/// 九宫格图片裁剪视图，基于 Mantis 库封装
///
/// Features:
/// - Robust cropping with rotation, aspect ratios, and more
/// - Powered by Mantis (https://github.com/guoyingqi/Mantis)
public struct ImageCropperView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    let originalImage: UIImage
    // Changed to public for external access
    /// 裁剪完成后的回调，参数为裁剪后的图片
    public var onCrop: (UIImage) -> Void
    /// 用户取消裁剪时的回调
    public var onCancel: () -> Void
    
    /// 创建图片裁剪视图
    /// - Parameters:
    ///   - originalImage: 待裁剪的原始图片
    ///   - onCrop: 裁剪完成后的回调，参数为裁剪后的 `UIImage`
    ///   - onCancel: 用户取消裁剪时的回调
    public init(originalImage: UIImage, onCrop: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.originalImage = originalImage
        self.onCrop = onCrop
        self.onCancel = onCancel
    }
    
    // MARK: - UIViewControllerRepresentable

    /// 创建并返回 Mantis 代理协调器
    public func makeCoordinator() -> Coordinator {
        Coordinator(onCrop: onCrop, onCancel: onCancel)
    }

    /// 创建 Mantis CropViewController 实例
    public func makeUIViewController(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.cropToolbarConfig.mode = .normal

        let cropViewController = Mantis.cropViewController(image: originalImage, config: config)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }

    /// 状态更新时调用，图片裁剪视图无需动态更新
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }

    /// Mantis 裁剪事件代理
    public final class Coordinator: NSObject, CropViewControllerDelegate {
        var onCrop: (UIImage) -> Void
        var onCancel: () -> Void
        
        /// 创建裁剪代理协调器
        /// - Parameters:
        ///   - onCrop: 裁剪完成回调
        ///   - onCancel: 取消/失败回调
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
