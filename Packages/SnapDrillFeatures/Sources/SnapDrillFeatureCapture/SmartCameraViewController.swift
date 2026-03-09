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
class SmartCameraViewController: UIViewController {
    
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
        // Setup Preview
        let preview = AVCaptureVideoPreviewLayer(session: manager.session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview
        
        // Setup Callbacks
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
        
        // Start Session
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
        // Throttle updates
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
            // Low Pass Filter
            let factor: CGFloat = 0.08
            newRect = CGRect(
                x: current.origin.x * (1 - factor) + target.origin.x * factor,
                y: current.origin.y * (1 - factor) + target.origin.y * factor,
                width: current.width * (1 - factor) + target.width * factor,
                height: current.height * (1 - factor) + target.height * factor
            )
            
            // Check delta for stability
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
        
        // Final Output
        let padded = newRect.insetBy(dx: -0.1, dy: -0.1)
        let finalRect = padded.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        
        self.lastDetectedRect = finalRect
        return (finalRect, isStable)
    }
}

import os // For OSAllocatedUnfairLock

// MARK: - Camera Session Manager (Non-UI Logic)

// Applying @preconcurrency to the whole class isn't ideal, but since AVFoundation types
// aren't fully audited for Sendable yet in early iOS SDKs, we drop the explicit Sendable conformance
// and manage synchronization manually via Queues and Actors.
final class CameraSessionManager: NSObject {
    
    // AVCaptureSession 在当前 SDK 版本尚未标注 Sendable；
    // 此实例在 sessionQueue 与 visionQueue 上只读访问，nonisolated(unsafe) 是 Swift 6 标准过渡方案
    nonisolated(unsafe) let session = AVCaptureSession()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let visionQueue = DispatchQueue(label: "com.snapdrill.visionQueue", qos: .userInitiated)
    private let sessionQueue = DispatchQueue(label: "com.snapdrill.sessionQueue")
    
    private let stateActor = CameraStateActor()
    
    // Atomic Flag for Backpressure
    private let isProcessingFrame = OSAllocatedUnfairLock(initialState: false)
    
    // The callbacks cross boundaries, so we mark the closures as @Sendable to satisfy
    // Swift 6 strict concurrency checks during the Task jump. 
    // The calling context (SmartCameraViewController) guarantees @MainActor dispatch.
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
        
        // Input
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            SnapDrillLogger.generic.info("Error: Unable to access back camera")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Video Output
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // Photo Output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
    }
    
    private static func extractTargetRect(from observations: [VNTextObservation]) -> CGRect? {
        let validObs = observations.filter { $0.boundingBox.height > 0.02 } // Filter noise
        guard !validObs.isEmpty else {
            return nil
        }
        
        // A. Find "Anchor" (Observation closest to center screen)
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
        
        // B. Cluster Neighbors
        var cluster: [VNTextObservation] = [anchor]
        var currentUnion = anchor.boundingBox
        
        for obs in validObs where obs !== anchor {
            let box = obs.boundingBox
            let distToAnchor = distance(from: box, to: CGPoint(x: anchor.boundingBox.midX, y: anchor.boundingBox.midY))
            
            if distToAnchor < 0.15 { // Close neighbors only
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
        
        // 1. Backpressure Strategy: Drop frames if we are still processing
        let canProcess = isProcessingFrame.withLock { state -> Bool in
            if state { return false }
            state = true
            return true
        }
        
        guard canProcess else { return }
        
        // Release the lock when the frame processing is fully handed over or completed
        defer {
            isProcessingFrame.withLock { $0 = false }
        }
        
        // 2. Strict Memory Pool: Wrap Vision pipeline in autoreleasepool
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
        
        // 3. Downsampling: Use ImageIO instead of UIImage(data:) to prevent OOM
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 2048 // Downsample to safe dimension
        ] as CFDictionary
        
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            SnapDrillLogger.capture.error("Failed to downsample captured photo.")
            return
        }
        
        let image = UIImage(cgImage: cgImage)
        
        // Capture local references to avoid capturing non-Sendable `self` in the Task
        let localActor = self.stateActor
        let localCallback = self.onCapture
        
        Task {
            let rect = await localActor.lastDetectedRect ?? CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
            localCallback?(image, rect)
        }
    }
}
