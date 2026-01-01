//
//  DocumentScannerView.swift
//  NotBadFeatureCapture
//
//  Created by Yiming Liao on 2025/12/30.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  基于 VisionKit 的文档扫描视图 (VNDocumentCameraViewController 封装)。
//

import SwiftUI
@preconcurrency import VisionKit
import UIKit

/// 原生文档扫描视图
///
/// 一个 `UIViewControllerRepresentable` 封装，集成了 Apple 的 VisionKit 文档扫描器。
///
/// ## 功能特性
/// - **自动边缘检测**: 自动识别文档轮廓。
/// - **透视矫正**: 将倾斜拍摄的文档拉直。
/// - **图像增强**: 提供黑白、彩色、照片等滤镜模式。
///
/// ## 使用注意
/// - 此视图仅在真机上有效。在模拟器上会显示 `ContentUnavailableView` 占位符。
/// - 必须通过 `.sheet` 或 `.fullScreenCover` 模态呈现，不建议推入导航栈。
struct DocumentScannerView: UIViewControllerRepresentable {
    
    /// 扫描完成回调
    ///
    /// 当用户点击“保存”且至少有一页文档被扫描时调用。
    /// - Parameter image: 处理后的文档图片（已矫正、裁剪）。
    var onCompletion: (UIImage) -> Void
    
    /// 取消回调
    ///
    /// 当用户点击“取消”按钮时调用。
    var onCancel: () -> Void
    
    /// 错误回调
    ///
    /// 当扫描过程发生系统错误时调用。
    var onError: (Error) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        #if targetEnvironment(simulator)
        return UIHostingController(
            rootView: ContentUnavailableView(
                "不支持模拟器",
                systemImage: "camera.fill",
                description: Text("请在真机上使用文档扫描仪")
            )
        )
        #else
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
        #endif
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
@MainActor
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onCompletion: onCompletion,
            onCancel: onCancel,
            onError: onError
        )
    }
}

class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate, @unchecked Sendable {
    let onCompletion: (UIImage) -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void
    
    init(onCompletion: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.onCompletion = onCompletion
        self.onCancel = onCancel
        self.onError = onError
    }
    
    #if !targetEnvironment(simulator)
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        // 1. Extract data synchronously (we are on Main Thread at runtime, so this is safe)
        let pageCount = scan.pageCount
        guard pageCount >= 1 else {
            Task { @MainActor in
                controller.dismiss(animated: true) {
                    self.onCancel()
                }
            }
            return
        }
        
        let image = scan.imageOfPage(at: pageCount - 1)
        
        // 2. perform UI updates on MainActor using extracted Sendable data (UIImage)
        Task { @MainActor in
            controller.dismiss(animated: true) {
                self.onCompletion(image)
            }
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        Task { @MainActor in
            controller.dismiss(animated: true) {
                self.onCancel()
            }
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        Task { @MainActor in
            controller.dismiss(animated: true) {
                self.onError(error)
            }
        }
    }
    #endif
}
