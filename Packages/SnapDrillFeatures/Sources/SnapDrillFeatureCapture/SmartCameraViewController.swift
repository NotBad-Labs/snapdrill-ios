//
//  SmartCameraViewController.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  相机控制器 (UIKit)，管理 AVCaptureSession 及其数据流。
//

import UIKit
@preconcurrency import AVFoundation

/// 智能相机控制器
///
/// 负责管理相机 UI 和 Vision 结果的展示。
/// 具体的 Session 管理和 Vision 处理委托给 `CameraSessionManager`。
final class SmartCameraViewController: UIViewController {
    
    // MARK: - API
    
    var onRegionDetected: ((CGRect?, Bool) -> Void)?
    var onCapture: ((UIImage, CGRect) -> Void)?
    
    // MARK: - Private Properties
    
    private let manager = CameraSessionManager()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupManager()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    // MARK: - Actions
    
    func capturePhoto() {
        manager.capturePhoto()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .black
    }
    
    private func setupManager() {
        // 设置预览层
        let preview = AVCaptureVideoPreviewLayer(session: manager.session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview
        
        // 设置回调
        manager.onRegionDetected = { [weak self] rect, isStable in
            Task { @MainActor in
                self?.onRegionDetected?(rect, isStable)
            }
        }
        
        manager.onCapture = { [weak self] image, rect in
            Task { @MainActor in
                self?.onCapture?(image, rect)
            }
        }
        
        // 启动会话
        manager.startSession()
    }
}

