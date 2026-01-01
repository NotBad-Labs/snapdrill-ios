//
//  SmartCameraViewController.swift
//  NotBadFeatureCapture
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  相机控制器 (UIKit)，管理 AVCaptureSession 及其数据流。
//

import UIKit
import AVFoundation
import Vision

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

// MARK: - Camera Session Manager (Non-UI Logic)

class CameraSessionManager: NSObject, @unchecked Sendable {
    
    let session = AVCaptureSession()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let visionQueue = DispatchQueue(label: "com.notbad.visionQueue", qos: .userInitiated)
    private let sessionQueue = DispatchQueue(label: "com.notbad.sessionQueue")
    
    // Smoothing & Stability
    private var smoothedRect: CGRect?
    private var stabilityCounter: Int = 0
    private let stabilityThreshold = 10 // Number of stable frames to trigger "Green"
    private let movementThreshold: CGFloat = 0.05 // Tolerance for considering "still"
    
    // Callback now includes isStable flag
    var onRegionDetected: ((CGRect?, Bool) -> Void)?
    var onCapture: ((UIImage, CGRect) -> Void)?
    
    private var lastDetectedRect: CGRect?
    private var lastUpdateTime: TimeInterval = 0
    
    override init() {
        super.init()
        configureSession()
    }
    
    func startSession() {
        sessionQueue.async {
            self.session.startRunning()
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
            print("Error: Unable to access back camera")
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
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectTextRectanglesRequest { [weak self] request, _ in
            guard let self = self else { return }
            if let results = request.results as? [VNTextObservation] {
                self.processVisionResults(results)
            }
        }
        request.reportCharacterBoxes = false
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        try? handler.perform([request])
    }
    
    // swiftlint:disable:next function_body_length
    private func processVisionResults(_ observations: [VNTextObservation]) {
        // 1. Center-Weighted Clustering Logic
        // Instead of unioning everything, we find the text block closest to center,
        // and then group only its close neighbors.
        
        let validObs = observations.filter { $0.boundingBox.height > 0.02 } // Filter noise
        guard !validObs.isEmpty else {
            handleNoDetection()
            return
        }
        
        // A. Find "Anchor" (Observation closest to center screen)
        let centerPoint = CGPoint(x: 0.5, y: 0.5)
        
        func distance(from box: CGRect, to point: CGPoint) -> CGFloat {
            let boxCenter = CGPoint(x: box.midX, y: box.midY)
            return hypot(boxCenter.x - point.x, boxCenter.y - point.y)
        }
        
        // Find the observation closest to center (within reasonable range, e.g. 0.35 radius)
        let sortedByDistance = validObs.sorted {
            distance(from: $0.boundingBox, to: centerPoint) < distance(from: $1.boundingBox, to: centerPoint)
        }
        
        guard let anchor = sortedByDistance.first,
              distance(from: anchor.boundingBox, to: centerPoint) < 0.35 else {
            // Nothing near center
            handleNoDetection()
            return
        }
        
        // B. Cluster Neighbors
        // Expand from anchor to include nearby text blocks (e.g. same paragraph)
        // Vertical distance is crucial (lines above/below), Horizontal can be wider.
        
        var cluster: [VNTextObservation] = [anchor]
        var currentUnion = anchor.boundingBox
        
        // Simple strategy: Filter all obs that intersect or are very close to the anchor's growing union
        // Iterative expansion could be better, but single-pass proximity check is faster.
        
        for obs in validObs where obs !== anchor {
            let box = obs.boundingBox
            // Check vertical proximity to the current cluster area
            // Ideally should check against specific lines, but let's check against center of anchor for simplicity first,
            // or better: check if it overlaps vertical range of anchor expanded by threshold.
            
            // Check if this box is close to the anchor
            let distToAnchor = distance(from: box, to: CGPoint(x: anchor.boundingBox.midX, y: anchor.boundingBox.midY))
            
            if distToAnchor < 0.15 { // Close neighbors only
                cluster.append(obs)
                currentUnion = currentUnion.union(box)
            }
        }
        
        // Update Raw Rect
        let rawRect: CGRect? = currentUnion
        
        // 2. Smoothing & Stability Logic
        
        let now = Date().timeIntervalSince1970
        // Throttle updates to ~15 FPS to reduce visual jitter perception
        guard now - lastUpdateTime > 0.06 else { return }
        lastUpdateTime = now
        
        guard let target = rawRect else {
            // Lost track
            handleNoDetection()
            return
        }
        
        if let current = smoothedRect {
            // Low Pass Filter: new = old * (1 - factor) + target * factor
            // Reduced factor for "heavier", smoother movement
            let factor: CGFloat = 0.08
            let newX = current.origin.x * (1 - factor) + target.origin.x * factor
            let newY = current.origin.y * (1 - factor) + target.origin.y * factor
            let newW = current.width * (1 - factor) + target.width * factor
            let newH = current.height * (1 - factor) + target.height * factor
            
            let newRect = CGRect(x: newX, y: newY, width: newW, height: newH)
            
            // Check delta for stability
            let delta = abs(newRect.origin.x - current.origin.x) + abs(newRect.origin.y - current.origin.y)
            if delta < movementThreshold {
                stabilityCounter += 1
            } else {
                stabilityCounter = max(0, stabilityCounter - 1)
            }
            
            self.smoothedRect = newRect
        } else {
            self.smoothedRect = target
            self.stabilityCounter = 0
        }
        
        // 3. Final Output
        let isStable = stabilityCounter > stabilityThreshold
        
        if let output = smoothedRect {
             // Padding and clamping
             // Increased padding to 0.1 (10%) to solve "tight box" issue
            let padded = output.insetBy(dx: -0.1, dy: -0.1)
            let finalRect = padded.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
            
            self.lastDetectedRect = finalRect
            onRegionDetected?(finalRect, isStable)
        }
    }
    
    private func handleNoDetection() {
        let now = Date().timeIntervalSince1970
        guard now - lastUpdateTime > 0.06 else { return }
        lastUpdateTime = now
        
        self.stabilityCounter = 0
        self.onRegionDetected?(nil, false)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        
        let rect = self.lastDetectedRect ?? CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
        onCapture?(image, rect)
    }
}
