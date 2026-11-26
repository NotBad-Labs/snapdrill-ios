import AVFoundation
import os
import UIKit
import Vision

/// Owns the AVCapture session and Vision edge tracking off the main actor.
/// Session mutation is confined to `sessionQueue`; Vision throttling is guarded by an unfair lock.
final class CameraEngine: NSObject, @unchecked Sendable, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.notbadlabs.snapdrill.camera.session")
    private let visionQueue = DispatchQueue(label: "com.notbadlabs.snapdrill.camera.vision")
    private let onDetection: @Sendable (QuadCorners?, CGSize) -> Void
    private let onPhoto: @Sendable (Data?) -> Void
    private let onSessionUnavailable: @Sendable () -> Void
    private let onInterruptionChanged: @Sendable (Bool) -> Void

    private var device: AVCaptureDevice?
    private var isConfigured = false
    private let lastDetectionTimeLock = OSAllocatedUnfairLock<CFAbsoluteTime>(initialState: 0)
    private var observers: [NSObjectProtocol] = []

    init(
        onDetection: @escaping @Sendable (QuadCorners?, CGSize) -> Void,
        onPhoto: @escaping @Sendable (Data?) -> Void,
        onSessionUnavailable: @escaping @Sendable () -> Void,
        onInterruptionChanged: @escaping @Sendable (Bool) -> Void
    ) {
        self.onDetection = onDetection
        self.onPhoto = onPhoto
        self.onSessionUnavailable = onSessionUnavailable
        self.onInterruptionChanged = onInterruptionChanged
        super.init()
        registerSessionObservers()
    }

    deinit {
        for token in observers {
            NotificationCenter.default.removeObserver(token)
        }
    }

    static var hasBackCamera: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    static var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    func start() {
        sessionQueue.async { [self] in
            if !isConfigured {
                isConfigured = configure()
            }
            guard isConfigured else {
                onSessionUnavailable()
                return
            }
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [self] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func capturePhoto(flash: LiveCameraFlashMode) {
        sessionQueue.async { [self] in
            guard isConfigured, session.isRunning else {
                onPhoto(nil)
                return
            }
            let settings = AVCapturePhotoSettings()
            let requested: AVCaptureDevice.FlashMode
            switch flash {
            case .auto: requested = .auto
            case .on: requested = .on
            case .off: requested = .off
            }
            if photoOutput.supportedFlashModes.contains(requested) {
                settings.flashMode = requested
            }
            if let connection = photoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func focus(atDevicePoint point: CGPoint) {
        sessionQueue.async { [self] in
            guard let device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch {
                return
            }
        }
    }

    private func registerSessionObservers() {
        let center = NotificationCenter.default
        let interrupted = center.addObserver(
            forName: AVCaptureSession.wasInterruptedNotification,
            object: session,
            queue: nil
        ) { [weak self] _ in
            self?.onInterruptionChanged(true)
        }
        let resumed = center.addObserver(
            forName: AVCaptureSession.interruptionEndedNotification,
            object: session,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            self.onInterruptionChanged(false)
            self.sessionQueue.async {
                if self.isConfigured, !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }
        let runtimeError = center.addObserver(
            forName: AVCaptureSession.runtimeErrorNotification,
            object: session,
            queue: nil
        ) { [weak self] notification in
            guard let self else { return }
            let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError
            self.sessionQueue.async {
                if error?.code == .mediaServicesWereReset {
                    if self.isConfigured, !self.session.isRunning {
                        self.session.startRunning()
                    }
                    self.onInterruptionChanged(false)
                } else if !self.session.isRunning {
                    self.onSessionUnavailable()
                }
            }
        }
        observers = [interrupted, resumed, runtimeError]
    }

    private func configure() -> Bool {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return false
        }

        session.beginConfiguration()
        var succeeded = false
        defer {
            if !succeeded {
                for existingInput in session.inputs {
                    session.removeInput(existingInput)
                }
                for existingOutput in session.outputs {
                    session.removeOutput(existingOutput)
                }
                device = nil
            }
            session.commitConfiguration()
        }

        session.sessionPreset = .photo
        guard session.canAddInput(input) else { return false }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else { return false }
        session.addOutput(photoOutput)

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        device = camera
        succeeded = true
        return true
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate (visionQueue)

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = CFAbsoluteTimeGetCurrent()
        let shouldProcess = lastDetectionTimeLock.withLock { lastTime -> Bool in
            guard now - lastTime >= 0.12 else { return false }
            lastTime = now
            return true
        }
        guard shouldProcess,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.55
        // Vision aspectRatio is always shortSide / longSide in [0.0, 1.0], matching both portrait and landscape sheets.
        request.minimumAspectRatio = 0.25
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.18
        request.quadratureTolerance = 35

        // Sensor buffers are landscape; `.right` yields an upright (portrait) coordinate space.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        let uprightSize = CGSize(
            width: CVPixelBufferGetHeight(pixelBuffer),
            height: CVPixelBufferGetWidth(pixelBuffer)
        )

        var quad: QuadCorners?
        if (try? handler.perform([request])) != nil, let observation = request.results?.first {
            let detected = QuadCorners(
                topLeft: CGPoint(x: observation.topLeft.x, y: 1.0 - observation.topLeft.y),
                topRight: CGPoint(x: observation.topRight.x, y: 1.0 - observation.topRight.y),
                bottomRight: CGPoint(x: observation.bottomRight.x, y: 1.0 - observation.bottomRight.y),
                bottomLeft: CGPoint(x: observation.bottomLeft.x, y: 1.0 - observation.bottomLeft.y)
            )
            quad = detected.isConvexAndValid ? detected : nil
        }
        onDetection(quad, uprightSize)
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        onPhoto(error == nil ? photo.fileDataRepresentation() : nil)
    }
}
