import AVFoundation
import ImageIO
import os
import SwiftUI
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

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate (visionQueue)

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

    // MARK: AVCapturePhotoCaptureDelegate

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        onPhoto(error == nil ? photo.fileDataRepresentation() : nil)
    }
}

/// Full-screen batch document scanner: live paper-edge tracking, burst capture of up to `maxPhotos` pages,
/// optional auto-capture, flash control, and album fallback. Lives in Services/Capture so the SwiftUI
/// capture views never touch AVFoundation directly.
@MainActor
final class LiveDocumentCameraController: UIViewController {
    private enum FallbackReason {
        case unavailable
        case permissionDenied
    }

    private let maxPhotos: Int
    private let onFinishBatch: ([Data]) -> Void
    private let onRequestPhotoLibrary: ([Data]) -> Void
    private let onCancel: () -> Void

    private var engine: CameraEngine?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var smoother = QuadSmoother()
    private var capturedPhotos: [Data] = []
    private var flashMode: LiveCameraFlashMode = .auto
    private var autoCaptureEnabled = false
    private var isCapturing = false
    private var isSessionInterrupted = false
    private var hasFinished = false
    private var lastCaptureDate = Date.distantPast
    private var lastQuad: QuadCorners?
    private var lastImageSize: CGSize = .zero

    private let previewContainer = UIView()
    private let overlayLayer = CAShapeLayer()
    private let guidanceLabel = UILabel()
    private let shutterFlashView = UIView()
    private let focusReticle = UIView()
    private var autoButton: UIButton?
    private var flashButton: UIButton?
    private var albumButton: UIButton?
    private let doneButton = UIButton(type: .system)
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(
        maxPhotos: Int,
        onFinishBatch: @escaping ([Data]) -> Void,
        onRequestPhotoLibrary: @escaping ([Data]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.maxPhotos = max(1, maxPhotos)
        self.onFinishBatch = onFinishBatch
        self.onRequestPhotoLibrary = onRequestPhotoLibrary
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        guard CameraEngine.hasBackCamera else {
            buildUnavailableFallback(reason: .unavailable)
            return
        }

        switch CameraEngine.authorizationStatus {
        case .authorized:
            setupLiveCamera()
        case .notDetermined:
            Task { [weak self] in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                guard let self, !self.hasFinished else { return }
                if granted {
                    self.setupLiveCamera()
                    self.engine?.start()
                    self.hapticGenerator.prepare()
                } else {
                    self.buildUnavailableFallback(reason: .permissionDenied)
                }
            }
        case .denied, .restricted:
            buildUnavailableFallback(reason: .permissionDenied)
        @unknown default:
            buildUnavailableFallback(reason: .unavailable)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        engine?.start()
        hapticGenerator.prepare()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        engine?.stop()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewContainer.bounds
        if let connection = previewLayer?.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        overlayLayer.frame = previewContainer.bounds
        redrawOverlay()
    }

    private func setupLiveCamera() {
        guard engine == nil else { return }
        let engine = CameraEngine(
            onDetection: { [weak self] quad, size in
                Task { @MainActor in self?.handleDetection(quad, imageSize: size) }
            },
            onPhoto: { [weak self] data in
                Task { @MainActor in self?.handlePhoto(data) }
            },
            onSessionUnavailable: { [weak self] in
                Task { @MainActor in self?.handleSessionUnavailable() }
            },
            onInterruptionChanged: { [weak self] interrupted in
                Task { @MainActor in self?.handleInterruptionChanged(interrupted) }
            }
        )
        self.engine = engine
        buildLiveInterface(session: engine.session)
    }

    private func handleSessionUnavailable() {
        guard !hasFinished else { return }
        engine?.stop()
        engine = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        view.subviews.forEach { $0.removeFromSuperview() }
        buildUnavailableFallback(reason: .unavailable)
    }

    private func handleInterruptionChanged(_ interrupted: Bool) {
        guard !hasFinished else { return }
        isSessionInterrupted = interrupted
        if interrupted {
            smoother.reset()
            lastQuad = nil
            redrawOverlay()
        }
        refreshGuidance(hasQuad: lastQuad != nil)
    }

    // MARK: Live Interface

    private func buildLiveInterface(session: AVCaptureSession) {
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.backgroundColor = .black
        view.addSubview(previewContainer)
        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        if let connection = layer.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        previewContainer.layer.addSublayer(layer)
        previewLayer = layer

        let accent = UIColor(SnapDrillTheme.inkBlue)
        overlayLayer.fillColor = accent.withAlphaComponent(0.20).cgColor
        overlayLayer.strokeColor = accent.cgColor
        overlayLayer.lineWidth = 3
        overlayLayer.lineJoin = .round
        previewContainer.layer.addSublayer(overlayLayer)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePreviewTap(_:)))
        previewContainer.addGestureRecognizer(tap)

        focusReticle.frame = CGRect(x: 0, y: 0, width: 72, height: 72)
        focusReticle.layer.borderColor = UIColor.systemYellow.cgColor
        focusReticle.layer.borderWidth = 1.5
        focusReticle.layer.cornerRadius = 8
        focusReticle.alpha = 0
        focusReticle.isUserInteractionEnabled = false
        previewContainer.addSubview(focusReticle)

        shutterFlashView.translatesAutoresizingMaskIntoConstraints = false
        shutterFlashView.backgroundColor = .white
        shutterFlashView.alpha = 0
        shutterFlashView.isUserInteractionEnabled = false
        view.addSubview(shutterFlashView)
        NSLayoutConstraint.activate([
            shutterFlashView.topAnchor.constraint(equalTo: view.topAnchor),
            shutterFlashView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            shutterFlashView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shutterFlashView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        buildTopBar()
        buildBottomBar()
        refreshGuidance(hasQuad: false)
    }

    private func buildTopBar() {
        let cancel = makeIconButton(
            symbol: "xmark",
            label: String(localized: "Cancel"),
            action: #selector(cancelTapped)
        )
        let auto = makeIconButton(
            symbol: "viewfinder.circle",
            label: String(localized: "Auto Capture"),
            action: #selector(autoTapped)
        )
        auto.accessibilityValue = String(localized: "Off")
        let flash = makeIconButton(
            symbol: flashMode.symbolName,
            label: String(localized: "Flash"),
            action: #selector(flashTapped)
        )
        flash.accessibilityValue = String(localized: "Auto")
        autoButton = auto
        flashButton = flash

        let pill = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.layer.cornerRadius = 16
        pill.clipsToBounds = true
        guidanceLabel.translatesAutoresizingMaskIntoConstraints = false
        guidanceLabel.textColor = .white
        guidanceLabel.font = .preferredFont(forTextStyle: .footnote)
        guidanceLabel.adjustsFontForContentSizeCategory = true
        guidanceLabel.numberOfLines = 2
        guidanceLabel.adjustsFontSizeToFitWidth = true
        guidanceLabel.minimumScaleFactor = 0.8
        guidanceLabel.textAlignment = .center
        pill.contentView.addSubview(guidanceLabel)
        NSLayoutConstraint.activate([
            guidanceLabel.topAnchor.constraint(equalTo: pill.contentView.topAnchor, constant: 7),
            guidanceLabel.bottomAnchor.constraint(equalTo: pill.contentView.bottomAnchor, constant: -7),
            guidanceLabel.leadingAnchor.constraint(equalTo: pill.contentView.leadingAnchor, constant: 12),
            guidanceLabel.trailingAnchor.constraint(equalTo: pill.contentView.trailingAnchor, constant: -12)
        ])

        let trailingStack = UIStackView(arrangedSubviews: [auto, flash])
        trailingStack.axis = .horizontal
        trailingStack.spacing = 10
        trailingStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(cancel)
        view.addSubview(pill)
        view.addSubview(trailingStack)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            cancel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            cancel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            trailingStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            trailingStack.centerYAnchor.constraint(equalTo: cancel.centerYAnchor),
            pill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pill.centerYAnchor.constraint(equalTo: cancel.centerYAnchor),
            pill.leadingAnchor.constraint(greaterThanOrEqualTo: cancel.trailingAnchor, constant: 8),
            pill.trailingAnchor.constraint(lessThanOrEqualTo: trailingStack.leadingAnchor, constant: -8)
        ])
    }

    private func buildBottomBar() {
        let album = makeIconButton(
            symbol: "photo.on.rectangle.angled",
            label: String(localized: "Import from Photos"),
            action: #selector(albumTapped)
        )
        albumButton = album

        let ring = UIView()
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.layer.borderColor = UIColor.white.cgColor
        ring.layer.borderWidth = 4
        ring.layer.cornerRadius = 36
        ring.isUserInteractionEnabled = false

        let shutter = UIButton(type: .custom)
        shutter.translatesAutoresizingMaskIntoConstraints = false
        shutter.backgroundColor = .white
        shutter.layer.cornerRadius = 30
        shutter.accessibilityLabel = String(localized: "Capture Mistakes")
        shutter.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)

        var doneConfig = UIButton.Configuration.filled()
        doneConfig.baseBackgroundColor = UIColor(SnapDrillTheme.inkBlue)
        doneConfig.baseForegroundColor = .white
        doneConfig.cornerStyle = .capsule
        doneConfig.imagePlacement = .leading
        doneConfig.imagePadding = 6
        doneButton.configuration = doneConfig
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.isHidden = true
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        view.addSubview(album)
        view.addSubview(ring)
        view.addSubview(shutter)
        view.addSubview(doneButton)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            ring.widthAnchor.constraint(equalToConstant: 72),
            ring.heightAnchor.constraint(equalToConstant: 72),
            ring.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ring.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -24),
            shutter.widthAnchor.constraint(equalToConstant: 60),
            shutter.heightAnchor.constraint(equalToConstant: 60),
            shutter.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            shutter.centerYAnchor.constraint(equalTo: ring.centerYAnchor),
            album.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            album.centerYAnchor.constraint(equalTo: ring.centerYAnchor),
            doneButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            doneButton.centerYAnchor.constraint(equalTo: ring.centerYAnchor),
            doneButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func makeIconButton(symbol: String, label: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbol)
        config.baseForegroundColor = .white
        config.background.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        config.background.cornerRadius = 22
        let button = UIButton(configuration: config)
        button.accessibilityLabel = label
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }

    // MARK: Unavailable Fallback (simulator, denied permission, session failure)

    private func buildUnavailableFallback(reason: FallbackReason) {
        let icon = UIImageView(
            image: UIImage(systemName: reason == .permissionDenied ? "lock.shield" : "camera.metering.unknown")
        )
        icon.tintColor = UIColor.white.withAlphaComponent(0.8)
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 54).isActive = true

        let title = UILabel()
        title.text = reason == .permissionDenied
            ? String(localized: "Camera Access Needed")
            : String(localized: "Camera Unavailable")
        title.textColor = .white
        title.font = .preferredFont(forTextStyle: .title3)
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0
        title.textAlignment = .center

        let message = UILabel()
        message.text = reason == .permissionDenied
            ? String(localized: "Allow camera access in Settings to scan exam pages, or import photos from your album instead.")
            : String(localized: "The camera is not available right now. You can import photos from your album instead.")
        message.textColor = UIColor.white.withAlphaComponent(0.75)
        message.font = .preferredFont(forTextStyle: .subheadline)
        message.adjustsFontForContentSizeCategory = true
        message.numberOfLines = 0
        message.textAlignment = .center

        var arranged: [UIView] = [icon, title, message]

        if reason == .permissionDenied {
            var settingsConfig = UIButton.Configuration.filled()
            settingsConfig.title = String(localized: "Open System Settings")
            settingsConfig.image = UIImage(systemName: "gear")
            settingsConfig.imagePadding = 8
            settingsConfig.cornerStyle = .capsule
            settingsConfig.baseBackgroundColor = UIColor(SnapDrillTheme.inkBlue)
            let settingsButton = UIButton(configuration: settingsConfig)
            settingsButton.addTarget(self, action: #selector(openSettingsTapped), for: .touchUpInside)
            settingsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            arranged.append(settingsButton)
        }

        var importConfig = reason == .permissionDenied ? UIButton.Configuration.tinted() : UIButton.Configuration.filled()
        importConfig.title = String(localized: "Import from Photos")
        importConfig.image = UIImage(systemName: "photo.on.rectangle.angled")
        importConfig.imagePadding = 8
        importConfig.cornerStyle = .capsule
        importConfig.baseBackgroundColor = UIColor(SnapDrillTheme.inkBlue)
        if reason == .permissionDenied {
            importConfig.baseForegroundColor = .white
        }
        let importButton = UIButton(configuration: importConfig)
        importButton.addTarget(self, action: #selector(albumTapped), for: .touchUpInside)
        importButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        arranged.append(importButton)

        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.title = String(localized: "Cancel")
        cancelConfig.baseForegroundColor = .white
        let cancelButton = UIButton(configuration: cancelConfig)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        arranged.append(cancelButton)

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    // MARK: Detection Overlay

    private func handleDetection(_ quad: QuadCorners?, imageSize: CGSize) {
        guard !hasFinished, !isSessionInterrupted else { return }
        lastImageSize = imageSize
        lastQuad = smoother.update(with: quad)
        redrawOverlay()
        refreshGuidance(hasQuad: lastQuad != nil)

        if autoCaptureEnabled,
           smoother.isStable,
           !isCapturing,
           capturedPhotos.count < maxPhotos,
           Date().timeIntervalSince(lastCaptureDate) > 1.8 {
            takePhoto()
        }
    }

    private func redrawOverlay() {
        guard let quad = lastQuad,
              lastImageSize.width > 0, lastImageSize.height > 0,
              previewContainer.bounds.width > 0 else {
            overlayLayer.path = nil
            return
        }

        let bounds = previewContainer.bounds
        let scale = max(bounds.width / lastImageSize.width, bounds.height / lastImageSize.height)
        let displayWidth = lastImageSize.width * scale
        let displayHeight = lastImageSize.height * scale
        let offsetX = (bounds.width - displayWidth) / 2
        let offsetY = (bounds.height - displayHeight) / 2

        func layerPoint(_ p: CGPoint) -> CGPoint {
            CGPoint(x: offsetX + p.x * displayWidth, y: offsetY + p.y * displayHeight)
        }

        let path = UIBezierPath()
        path.move(to: layerPoint(quad.topLeft))
        path.addLine(to: layerPoint(quad.topRight))
        path.addLine(to: layerPoint(quad.bottomRight))
        path.addLine(to: layerPoint(quad.bottomLeft))
        path.close()

        let color = smoother.isStable
            ? UIColor(SnapDrillTheme.masteryGreen)
            : UIColor(SnapDrillTheme.inkBlue)
        overlayLayer.strokeColor = color.cgColor
        overlayLayer.fillColor = color.withAlphaComponent(0.20).cgColor
        overlayLayer.path = path.cgPath
    }

    private func refreshGuidance(hasQuad: Bool) {
        if isSessionInterrupted {
            guidanceLabel.text = String(localized: "Camera paused")
            return
        }
        let page = min(capturedPhotos.count + 1, maxPhotos)
        if !hasQuad {
            guidanceLabel.text = String(localized: "Align exam page")
        } else if !smoother.isStable {
            guidanceLabel.text = String(localized: "Hold steady...")
        } else {
            guidanceLabel.text = String(localized: "Page \(page) of \(maxPhotos)")
        }
    }

    // MARK: Capture

    private func takePhoto() {
        guard !isCapturing, !hasFinished, !isSessionInterrupted, capturedPhotos.count < maxPhotos else { return }
        isCapturing = true
        lastCaptureDate = Date()
        hapticGenerator.impactOccurred()
        shutterFlashView.alpha = 0.85
        UIView.animate(withDuration: 0.22) { self.shutterFlashView.alpha = 0 }
        engine?.capturePhoto(flash: flashMode)
    }

    private func handlePhoto(_ data: Data?) {
        guard let data, !hasFinished else {
            isCapturing = false
            return
        }
        // Immediately downsample & strip GPS off-MainActor via ImageIO so burst capture never holds
        // 10 full-resolution 12–48MP JPEGs in RAM at once.
        Task { [weak self] in
            let processed: (compact: Data, thumbData: Data?) = await Task.detached(priority: .userInitiated) {
                let compact = PhotoDataSanitizer().sanitize(data, maxDimension: 2200) ?? data
                let thumb = PhotoDataSanitizer.makeThumbnailData(from: compact, maxPixel: 96)
                return (compact, thumb)
            }.value
            guard let self else { return }
            self.isCapturing = false
            guard !self.hasFinished else { return }

            self.capturedPhotos.append(processed.compact)
            self.smoother.reset()
            self.lastQuad = nil
            self.redrawOverlay()
            self.refreshGuidance(hasQuad: false)
            self.updateDoneButton(thumbData: processed.thumbData)
            self.albumButton?.isEnabled = self.capturedPhotos.count < self.maxPhotos

            if self.capturedPhotos.count >= self.maxPhotos {
                self.finishBatch()
            }
        }
    }

    private func updateDoneButton(thumbData: Data?) {
        doneButton.isHidden = capturedPhotos.isEmpty
        doneButton.configuration?.title = String(localized: "Done (\(capturedPhotos.count))")
        guard let thumbData, let image = UIImage(data: thumbData) else { return }
        let side: CGFloat = 28
        let rounded = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: side, height: side), cornerRadius: 6).addClip()
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        doneButton.configuration?.image = rounded
    }

    private func finishBatch() {
        guard !hasFinished, !capturedPhotos.isEmpty else { return }
        hasFinished = true
        engine?.stop()
        onFinishBatch(capturedPhotos)
    }

    // MARK: Actions

    @objc private func shutterTapped() {
        takePhoto()
    }

    @objc private func doneTapped() {
        finishBatch()
    }

    @objc private func cancelTapped() {
        guard !hasFinished else { return }
        hasFinished = true
        engine?.stop()
        onCancel()
    }

    @objc private func albumTapped() {
        guard !hasFinished else { return }
        hasFinished = true
        engine?.stop()
        onRequestPhotoLibrary(capturedPhotos)
    }

    @objc private func openSettingsTapped() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func autoTapped() {
        autoCaptureEnabled.toggle()
        smoother.reset()
        autoButton?.configuration?.image = UIImage(
            systemName: autoCaptureEnabled ? "viewfinder.circle.fill" : "viewfinder.circle"
        )
        autoButton?.configuration?.baseForegroundColor = autoCaptureEnabled
            ? UIColor(SnapDrillTheme.masteryGreen)
            : .white
        autoButton?.accessibilityValue = autoCaptureEnabled ? String(localized: "On") : String(localized: "Off")
    }

    @objc private func flashTapped() {
        flashMode = flashMode.next
        flashButton?.configuration?.image = UIImage(systemName: flashMode.symbolName)
        switch flashMode {
        case .auto: flashButton?.accessibilityValue = String(localized: "Auto")
        case .on: flashButton?.accessibilityValue = String(localized: "On")
        case .off: flashButton?.accessibilityValue = String(localized: "Off")
        }
    }

    @objc private func handlePreviewTap(_ gesture: UITapGestureRecognizer) {
        guard let layer = previewLayer else { return }
        let point = gesture.location(in: previewContainer)
        engine?.focus(atDevicePoint: layer.captureDevicePointConverted(fromLayerPoint: point))

        focusReticle.center = point
        focusReticle.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        focusReticle.alpha = 1
        UIView.animate(withDuration: 0.25, animations: {
            self.focusReticle.transform = .identity
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5) { self.focusReticle.alpha = 0 }
        })
    }
}
