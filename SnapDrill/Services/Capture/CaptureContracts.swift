import CoreGraphics
import Foundation

// MARK: - Value Types

/// Normalized 4-corner polygon in top-left origin coordinates (0...1).
struct QuadCorners: Sendable, Codable, Equatable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomRight: CGPoint
    var bottomLeft: CGPoint

    static let fullFrame = QuadCorners(
        topLeft: CGPoint(x: 0.0, y: 0.0),
        topRight: CGPoint(x: 1.0, y: 0.0),
        bottomRight: CGPoint(x: 1.0, y: 1.0),
        bottomLeft: CGPoint(x: 0.0, y: 1.0)
    )

    /// Verifies that corners stay within 0...1, form a strictly convex non-self-intersecting quad,
    /// and span meaningful edges and area before passing to CIFilter.perspectiveCorrection.
    var isConvexAndValid: Bool {
        let pts = [topLeft, topRight, bottomRight, bottomLeft]
        for pt in pts {
            guard pt.x.isFinite, pt.y.isFinite,
                  pt.x >= 0.0, pt.x <= 1.0,
                  pt.y >= 0.0, pt.y <= 1.0 else {
                return false
            }
        }

        var crossSign: Int = 0
        for i in 0..<4 {
            let a = pts[i]
            let b = pts[(i + 1) % 4]
            let c = pts[(i + 2) % 4]
            let edgeLen = hypot(b.x - a.x, b.y - a.y)
            guard edgeLen >= 0.05 else { return false }

            let dx1 = b.x - a.x
            let dy1 = b.y - a.y
            let dx2 = c.x - b.x
            let dy2 = c.y - b.y
            let cross = dx1 * dy2 - dy1 * dx2
            guard abs(cross) > 1e-4 else { return false }

            let sign = cross > 0 ? 1 : -1
            if crossSign == 0 {
                crossSign = sign
            } else if crossSign != sign {
                return false
            }
        }

        // Shoelace area
        var doubleArea: CGFloat = 0
        for i in 0..<4 {
            let p1 = pts[i]
            let p2 = pts[(i + 1) % 4]
            doubleArea += (p1.x * p2.y - p2.x * p1.y)
        }
        return abs(doubleArea) * 0.5 >= 0.02
    }
}

/// Three image enhancement presets required by PRD F-04.
enum ImageEnhancementMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case enhanced
    case original
    case blackAndWhite

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .enhanced: return String(localized: "Enhanced")
        case .original: return String(localized: "Original")
        case .blackAndWhite: return String(localized: "B&W")
        }
    }
}

/// Handwriting removal modes combining heuristic chroma/pencil cleanup and Core ML extensibility.
enum InkRemovalMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case autoAll
    case coloredOnly
    case off

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .autoAll: return String(localized: "Auto Clean (Ink & Pencil)")
        case .coloredOnly: return String(localized: "Colored Pens Only")
        case .off: return String(localized: "Keep Original")
        }
    }
}

/// Normalized crop box in top-left origin coordinates (0...1).
struct CaptureCropBox: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    var normalizedRect: CGRect

    init(
        id: UUID = UUID(),
        normalizedRect: CGRect = CGRect(x: 0.08, y: 0.12, width: 0.84, height: 0.34)
    ) {
        self.id = id
        self.normalizedRect = normalizedRect.clampedToUnitSquare()
    }
}

/// One scanned or imported exam/homework page within a capture session.
struct CapturePage: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    var rawImageData: Data
    var correctedImageData: Data
    var enhancedImageData: Data
    var corners: QuadCorners
    var enhancementMode: ImageEnhancementMode
    var boxes: [CaptureCropBox]

    init(
        id: UUID = UUID(),
        rawImageData: Data,
        correctedImageData: Data? = nil,
        enhancedImageData: Data? = nil,
        corners: QuadCorners = .fullFrame,
        enhancementMode: ImageEnhancementMode = .enhanced,
        boxes: [CaptureCropBox] = [CaptureCropBox()]
    ) {
        self.id = id
        self.rawImageData = rawImageData
        self.correctedImageData = correctedImageData ?? rawImageData
        self.enhancedImageData = enhancedImageData ?? correctedImageData ?? rawImageData
        self.corners = corners
        self.enhancementMode = enhancementMode
        self.boxes = boxes
    }
}

/// Full multi-page capture session persisted as draft if interrupted (PRD §8.2, §8.6).
struct CaptureSession: Sendable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    var pages: [CapturePage]
    var activeStep: Int
    var selectedSubjectID: UUID? = nil
    var savedPreview: CaptureSavePreview? = nil

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        pages: [CapturePage] = [],
        activeStep: Int = 1,
        selectedSubjectID: UUID? = nil,
        savedPreview: CaptureSavePreview? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.pages = pages
        self.activeStep = activeStep
        self.selectedSubjectID = selectedSubjectID
        self.savedPreview = savedPreview
    }

    var totalBoxCount: Int {
        pages.reduce(0) { $0 + $1.boxes.count }
    }
}

/// Per-question preview item produced in Step 3 before saving to SwiftData.
struct CaptureSaveItem: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    let pageIndex: Int
    let boxIndex: Int
    var originalImageData: Data
    var cleanedImageData: Data
    var handwritingRemovalSucceeded: Bool
    var ocrText: String
    var pageImageData: Data? = nil
    var cropRectNormalized: CGRect? = nil

    // Optional metadata editable before saving
    var causes: [MistakeCause] = []
    var customCauseNames: [String] = []
    var tagNames: [String] = []
    var answerText: String = ""
    var answerImageDatas: [Data] = []
    var notes: String = ""
    var sourceTitle: String = ""
}

struct CaptureSavePreview: Sendable, Codable, Equatable {
    var items: [CaptureSaveItem]
    var inkRemovalMode: InkRemovalMode

    var questionCount: Int { items.count }
}

enum CameraAuthorizationState: Sendable, Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
}

enum CapturePipelineError: Error, Sendable, Equatable, LocalizedError {
    case tooManyPhotos(limit: Int)
    case tooManyBoxesPerPage(limit: Int)
    case emptySession
    case invalidImageData
    case subjectRequired

    var errorDescription: String? {
        switch self {
        case .tooManyPhotos(let limit):
            return String(localized: "You can capture or import up to \(limit) pages at once.")
        case .tooManyBoxesPerPage(let limit):
            return String(localized: "You can frame up to \(limit) questions per page.")
        case .emptySession:
            return String(localized: "Please select at least one photo.")
        case .invalidImageData:
            return String(localized: "Unable to decode the selected image.")
        case .subjectRequired:
            return String(localized: "Please pick a subject before saving.")
        }
    }
}

// MARK: - Pipeline Contract (Single Entry Point for Features/Capture)

protocol CapturePipelineServing: Sendable {
    var maxPhotoCount: Int { get }
    var maxBoxesPerPage: Int { get }

    func beginSession(importedImageData: [Data]) async throws -> CaptureSession
    func updateCorners(_ corners: QuadCorners, pageID: UUID, in session: CaptureSession) async throws -> CaptureSession
    func setEnhancement(mode: ImageEnhancementMode, pageID: UUID, in session: CaptureSession) async throws -> CaptureSession
    func addBox(on pageID: UUID, rect: CGRect?, in session: CaptureSession) async throws -> CaptureSession
    func updateBox(_ box: CaptureCropBox, on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession
    func removeBox(boxID: UUID, on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession
    func suggestQuestionBoxes(on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession
    func buildSavePreview(for session: CaptureSession, mode: InkRemovalMode) async throws -> CaptureSavePreview
    func reprocessItem(_ item: CaptureSaveItem, mode: InkRemovalMode) async -> CaptureSaveItem
}

// MARK: - Sub-Capabilities (Never Imported Directly by Capture Views)

protocol CameraAccessChecking: Sendable {
    func authorizationState() -> CameraAuthorizationState
    func requestAccess() async -> CameraAuthorizationState
}

protocol PhotoDataSanitizing: Sendable {
    func sanitize(_ imageData: Data, maxDimension: CGFloat) -> Data?
}

protocol DocumentDetecting: Sendable {
    func detectCorners(in imageData: Data) async -> QuadCorners
    func applyPerspectiveCorrection(to imageData: Data, corners: QuadCorners) -> Data
}

protocol ImageEnhancing: Sendable {
    func apply(_ mode: ImageEnhancementMode, to imageData: Data) -> Data
}

protocol InkRemoving: Sendable {
    func removeInk(from imageData: Data, mode: InkRemovalMode) async -> (cleanedData: Data, succeeded: Bool)
}

protocol SmartQuestionDetecting: Sendable {
    func suggestBoxes(in imageData: Data, maxBoxes: Int) async -> [CaptureCropBox]
}

protocol CaptureDraftPersisting: Sendable {
    func saveDraft(_ session: CaptureSession) async throws
    func loadDraft() async -> CaptureSession?
    func clearDraft() async
}

// MARK: - Geometry Helpers

extension CGRect {
    /// Clamps a normalized crop rectangle into 0...1 with a minimum 6% width/height.
    func clampedToUnitSquare(minDimension: CGFloat = 0.06) -> CGRect {
        let w = min(1.0, max(minDimension, width))
        let h = min(1.0, max(minDimension, height))
        let x = min(1.0 - w, max(0.0, origin.x))
        let y = min(1.0 - h, max(0.0, origin.y))
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

// MARK: - Live Camera Helpers

/// Flash behavior of the live document scanner camera.
enum LiveCameraFlashMode: String, CaseIterable, Sendable {
    case auto
    case on
    case off

    var symbolName: String {
        switch self {
        case .auto: return "bolt.badge.a"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash"
        }
    }

    var next: LiveCameraFlashMode {
        switch self {
        case .auto: return .on
        case .on: return .off
        case .off: return .auto
        }
    }
}

/// Pure exponential smoother for live document-edge detections. Keeps the on-screen quad steady and tells
/// callers when the page has been held still long enough to auto-capture.
struct QuadSmoother: Sendable {
    let alpha: CGFloat
    let stabilityThreshold: CGFloat
    let requiredStableFrames: Int
    let maxMissedFrames: Int

    private(set) var currentQuad: QuadCorners?
    private(set) var stableFrameCount: Int = 0
    private(set) var missedFrameCount: Int = 0

    init(
        alpha: CGFloat = 0.35,
        stabilityThreshold: CGFloat = 0.025,
        requiredStableFrames: Int = 6,
        maxMissedFrames: Int = 5
    ) {
        self.alpha = alpha
        self.stabilityThreshold = stabilityThreshold
        self.requiredStableFrames = requiredStableFrames
        self.maxMissedFrames = maxMissedFrames
    }

    var isStable: Bool {
        currentQuad != nil && stableFrameCount >= requiredStableFrames
    }

    @discardableResult
    mutating func update(with detected: QuadCorners?) -> QuadCorners? {
        guard let detected, detected.isConvexAndValid else {
            missedFrameCount += 1
            stableFrameCount = 0
            if missedFrameCount >= maxMissedFrames {
                currentQuad = nil
            }
            return currentQuad
        }

        guard let previous = currentQuad else {
            currentQuad = detected
            missedFrameCount = 0
            stableFrameCount = 1
            return currentQuad
        }

        func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
        func blend(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            CGPoint(x: a.x * (1 - alpha) + b.x * alpha, y: a.y * (1 - alpha) + b.y * alpha)
        }

        let maxDelta = max(
            dist(previous.topLeft, detected.topLeft),
            dist(previous.topRight, detected.topRight),
            dist(previous.bottomRight, detected.bottomRight),
            dist(previous.bottomLeft, detected.bottomLeft)
        )

        let blended = QuadCorners(
            topLeft: blend(previous.topLeft, detected.topLeft),
            topRight: blend(previous.topRight, detected.topRight),
            bottomRight: blend(previous.bottomRight, detected.bottomRight),
            bottomLeft: blend(previous.bottomLeft, detected.bottomLeft)
        )

        if blended.isConvexAndValid {
            currentQuad = blended
            missedFrameCount = 0
            stableFrameCount = maxDelta <= stabilityThreshold ? stableFrameCount + 1 : 1
        } else {
            missedFrameCount += 1
            stableFrameCount = 0
        }
        return currentQuad
    }

    mutating func reset() {
        currentQuad = nil
        stableFrameCount = 0
        missedFrameCount = 0
    }
}
