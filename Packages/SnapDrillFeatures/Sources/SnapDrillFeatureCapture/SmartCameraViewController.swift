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
import Vision
import SnapDrillCore

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

// MARK: - Camera State Actor (Concurrency Safe)

actor CameraStateActor {
    private var smoothedRect: CGRect?
    private var stabilityCounter: Int = 0
    private let stabilityThreshold = 10
    private let movementThreshold: CGFloat = 0.05
    private var lastUpdateTime: TimeInterval = 0
    
    var lastDetectedRect: CGRect?
    
    func process(target: CGRect?, now: TimeInterval) -> (CGRect?, Bool) {
        // 节流：限制更新频率
        guard now - lastUpdateTime > 0.06 else {
            return (smoothedRect, stabilityCounter > stabilityThreshold)
        }
        lastUpdateTime = now
        
        guard let target = target else {
            stabilityCounter = 0
            return (nil, false)
        }
        
        let newRect: CGRect
        if let current = smoothedRect {
            // 低通滤波器
            let factor: CGFloat = 0.08
            newRect = CGRect(
                x: current.origin.x * (1 - factor) + target.origin.x * factor,
                y: current.origin.y * (1 - factor) + target.origin.y * factor,
                width: current.width * (1 - factor) + target.width * factor,
                height: current.height * (1 - factor) + target.height * factor
            )
            
            // 检查位移变化量判断稳定性
            let delta = abs(newRect.origin.x - current.origin.x) + abs(newRect.origin.y - current.origin.y)
            if delta < movementThreshold {
                stabilityCounter += 1
            } else {
                stabilityCounter = max(0, stabilityCounter - 1)
            }
        } else {
            newRect = target
            stabilityCounter = 0
        }
        
        self.smoothedRect = newRect
        let isStable = stabilityCounter > stabilityThreshold
        
        // 最终输出
        let padded = newRect.insetBy(dx: -0.1, dy: -0.1)
        let finalRect = padded.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        
        self.lastDetectedRect = finalRect
        return (finalRect, isStable)
    }
}

import os // OSAllocatedUnfairLock 所在模块

// MARK: - Camera Session Manager (Non-UI Logic)

// 对整个类标注 @preconcurrency 并不理想，但由于 AVFoundation 类型在当前 iOS SDK 中尚未完成 Sendable 审计，
// 因此放弃显式 Sendable 遵循，改用 Queue 和 Actor 手动管理同步。
final class CameraSessionManager: NSObject {
    
    // AVCaptureSession 在当前 SDK 版本尚未标注 Sendable；
    // 此实例在 sessionQueue 与 visionQueue 上只读访问，nonisolated(unsafe) 是 Swift 6 标准过渡方案
    nonisolated(unsafe) let session = AVCaptureSession()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let visionQueue = DispatchQueue(label: "com.snapdrill.visionQueue", qos: .userInitiated)
    private let sessionQueue = DispatchQueue(label: "com.snapdrill.sessionQueue")
    
    private let stateActor = CameraStateActor()
    
    // 背压控制的原子标志位
    private let isProcessingFrame = OSAllocatedUnfairLock(initialState: false)
    
    // 回调闭包跨越隔离边界，标记为 @Sendable 以满足 Swift 6 严格并发检查。
    // 调用方（SmartCameraViewController）保证在 @MainActor 上分发。
    var onRegionDetected: (@Sendable (CGRect?, Bool) -> Void)?
    var onCapture: (@Sendable (UIImage, CGRect) -> Void)?
    
    override init() {
        super.init()
        configureSession()
    }
    
    func startSession() {
        // 局部捕获 session，避免在 @Sendable 闭包中捕获非 Sendable 的 self
        let capturedSession = session
        sessionQueue.async {
            capturedSession.startRunning()
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // 输入源
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            SnapDrillLogger.generic.info("Error: Unable to access back camera")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // 视频输出
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // 拍照输出
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
    }
    
    private static func extractTargetRect(from observations: [VNTextObservation]) -> CGRect? {
        let validObs = observations.filter { $0.boundingBox.height > 0.02 } // 过滤噪声
        guard !validObs.isEmpty else {
            return nil
        }
        
        // A. 找到"锚点"（距离屏幕中心最近的文本观测）
        let centerPoint = CGPoint(x: 0.5, y: 0.5)
        
        func distance(from box: CGRect, to point: CGPoint) -> CGFloat {
            let boxCenter = CGPoint(x: box.midX, y: box.midY)
            return hypot(boxCenter.x - point.x, boxCenter.y - point.y)
        }
        
        let sortedByDistance = validObs.sorted {
            distance(from: $0.boundingBox, to: centerPoint) < distance(from: $1.boundingBox, to: centerPoint)
        }
        
        guard let anchor = sortedByDistance.first,
              distance(from: anchor.boundingBox, to: centerPoint) < 0.35 else {
            return nil
        }
        
        // B. 聚类邻近文本
        var cluster: [VNTextObservation] = [anchor]
        var currentUnion = anchor.boundingBox
        
        for obs in validObs where obs !== anchor {
            let box = obs.boundingBox
            let distToAnchor = distance(from: box, to: CGPoint(x: anchor.boundingBox.midX, y: anchor.boundingBox.midY))
            
            if distToAnchor < 0.15 { // 仅取近邻
                cluster.append(obs)
                currentUnion = currentUnion.union(box)
            }
        }
        
        return currentUnion
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // 1. 背压策略：如果上一帧仍在处理中，丢弃当前帧
        let canProcess = isProcessingFrame.withLock { state -> Bool in
            if state { return false }
            state = true
            return true
        }
        
        guard canProcess else { return }
        
        // 帧处理完成或交接后释放锁
        defer {
            isProcessingFrame.withLock { $0 = false }
        }
        
        // 2. 严格内存池：将 Vision 管线包裹在 autoreleasepool 中
        autoreleasepool {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let localActor = self.stateActor
            let localCallback = self.onRegionDetected
            let request = VNDetectTextRectanglesRequest { request, _ in
                if let results = request.results as? [VNTextObservation] {
                    let targetRect = Self.extractTargetRect(from: results)
                    let now = Date().timeIntervalSince1970
                    
                    Task {
                        let (finalRect, isStable) = await localActor.process(target: targetRect, now: now)
                        localCallback?(finalRect, isStable)
                    }
                }
            }
            request.reportCharacterBoxes = false
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
            try? handler.perform([request])
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        
        // 3. 降采样：使用 ImageIO 代替 UIImage(data:) 以防止 OOM
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 2048 // 降采样到安全尺寸
        ] as CFDictionary
        
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            SnapDrillLogger.capture.error("Failed to downsample captured photo.")
            return
        }
        
        let image = UIImage(cgImage: cgImage)
        
        // 捕获局部引用，避免在 Task 中捕获非 Sendable 的 self
        let localActor = self.stateActor
        let localCallback = self.onCapture
        
        Task {
            let rect = await localActor.lastDetectedRect ?? CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
            localCallback?(image, rect)
        }
    }
}
