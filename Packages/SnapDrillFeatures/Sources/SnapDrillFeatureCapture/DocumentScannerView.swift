//
//  DocumentScannerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  基于 VisionKit 的文档扫描视图 (VNDocumentCameraViewController 封装)。
//

import SwiftUI
@preconcurrency import VisionKit
import UIKit
import SnapDrillCore

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
    
    // MARK: - Properties
    
    /// 扫描完成回调
    ///
    /// 当用户点击”保存”且至少有一页文档被扫描时调用。
    /// - Parameter images: 所有已扫描页面的图片列表（已矫正、裁剪）。
    var onCompletion: @MainActor ([UIImage]) -> Void

    /// 取消回调
    ///
    /// 当用户点击”取消”按钮时调用。
    var onCancel: @MainActor () -> Void

    /// 错误回调
    ///
    /// 当扫描过程发生系统错误时调用。
    var onError: @MainActor (Error) -> Void
    
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
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onCompletion: onCompletion,
            onCancel: onCancel,
            onError: onError
        )
    }
}

// Coordinator 使用 defaultIsolation(MainActor) 保护闭包属性；
// VisionKit delegate 回调方法标注 nonisolated，在方法内显式跳回主线程。
final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    let onCompletion: @MainActor ([UIImage]) -> Void
    let onCancel: @MainActor () -> Void
    let onError: @MainActor (Error) -> Void

    init(
        onCompletion: @escaping @MainActor ([UIImage]) -> Void,
        onCancel: @escaping @MainActor () -> Void,
        onError: @escaping @MainActor (Error) -> Void
    ) {
        self.onCompletion = onCompletion
        self.onCancel = onCancel
        self.onError = onError
    }

    #if !targetEnvironment(simulator)
    nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        let pageCount = scan.pageCount
        guard pageCount >= 1 else {
            Task { @MainActor [self] in
                controller.dismiss(animated: true) {
                    self.onCancel()
                }
            }
            return
        }

        // 提取全部页面并压缩（原图单张 5-10MB，压缩后 ~200KB，避免多页 OOM）
        let images = (0 ..< pageCount).map { index -> UIImage in
            let original = scan.imageOfPage(at: index)
            if let data = ImageStorage.compressedJPEGData(from: original, maxLongSide: 2000, quality: 0.8),
               let compressed = UIImage(data: data) {
                return compressed
            }
            return original
        }
        Task { @MainActor [self] in
            controller.dismiss(animated: true) {
                self.onCompletion(images)
            }
        }
    }

    nonisolated func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        Task { @MainActor [self] in
            controller.dismiss(animated: true) {
                self.onCancel()
            }
        }
    }

    nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        Task { @MainActor [self] in
            controller.dismiss(animated: true) {
                self.onError(error)
            }
        }
    }
    #endif
}
