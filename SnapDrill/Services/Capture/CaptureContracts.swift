import Foundation

/// Capture 模块对外「合同」。**修改须先改本文档 + `Docs/ARCHITECTURE.md` §4.3，再改实现。**
///
/// PRD：§8.2、AC-02、AC-03。UI（`Features/Capture`）**只能**依赖 `CapturePipelineServing`，禁止直接调 Core Image / Vision / 相机 API。

// MARK: - Value types

struct CapturePage: Identifiable, Sendable, Equatable {
    let id: UUID
    var imageData: Data
    var enhancementMode: ImageEnhancementMode
    /// 归一化坐标 0…1，单页最多 10 个（PRD §8.2）
    var boxes: [CaptureCropBox]

    init(
        id: UUID = UUID(),
        imageData: Data,
        enhancementMode: ImageEnhancementMode = .enhanced,
        boxes: [CaptureCropBox] = [CaptureCropBox()]
    ) {
        self.id = id
        self.imageData = imageData
        self.enhancementMode = enhancementMode
        self.boxes = boxes
    }
}

struct CaptureCropBox: Identifiable, Sendable, Equatable {
    let id: UUID
    /// 相对整页图像的 CGRect，origin/size 均在 0…1
    var normalizedRect: CGRect

    init(id: UUID = UUID(), normalizedRect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.35)) {
        self.id = id
        self.normalizedRect = normalizedRect
    }
}

struct CaptureSession: Sendable, Equatable {
    var pages: [CapturePage]

    var totalBoxCount: Int {
        pages.reduce(0) { $0 + $1.boxes.count }
    }
}

struct CaptureSaveItem: Sendable, Equatable {
    let pageIndex: Int
    let boxID: UUID
    var originalImageData: Data
    var cleanedImageData: Data
    var handwritingRemovalSucceeded: Bool
}

struct CaptureSavePreview: Sendable, Equatable {
    var items: [CaptureSaveItem]
    var questionCount: Int { items.count }
}

enum CapturePipelineError: Error, Sendable, Equatable {
    case tooManyPhotos(limit: Int)
    case tooManyBoxesPerPage(limit: Int)
    case emptySession
    case subjectRequired
}

// MARK: - Pipeline contract (UI 唯一入口)

/// 收录三步的聚合合同。实现类：`CapturePipelineStub`（UI 开发）、`CapturePipelineLive`（真能力，Slice 2+ 填充）。
protocol CapturePipelineServing: Sendable {
    var maxPhotoCount: Int { get }
    var maxBoxesPerPage: Int { get }

    /// 步骤 0→1：写入导入图（已剥离 GPS 由实现保证），返回可编辑 session
    func beginSession(importedImageData: [Data]) async throws -> CaptureSession

    /// 步骤 1：透视/角点由实现处理；当前 stub 透传
    func applyDocumentCorrection(session: CaptureSession) async throws -> CaptureSession

    /// 步骤 1：单页增强档位（PRD F-04）
    func setEnhancement(mode: ImageEnhancementMode, pageID: UUID, in session: CaptureSession) async throws -> CaptureSession

    /// 步骤 2：增删改框
    func addBox(on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession
    func updateBox(_ box: CaptureCropBox, on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession

    /// 步骤 3：去手写预览（可降级，PRD §8.6）
    func buildSavePreview(for session: CaptureSession) async throws -> CaptureSavePreview

    /// 步骤 3：入库；返回保存条数 N
    func commitSave(preview: CaptureSavePreview, subjectID: UUID) async throws -> Int
}

// MARK: - Sub-capabilities (实现者分文件，勿被 UI 引用)

protocol PhotoDataSanitizing: Sendable {
    func stripGPSMetadata(from imageData: Data) -> Data
}

protocol ImageEnhancing: Sendable {
    func apply(_ mode: ImageEnhancementMode, to imageData: Data) -> Data
}

protocol InkRemoving: Sendable {
    func removeInk(from imageData: Data) async -> (cleanedData: Data, succeeded: Bool)
}