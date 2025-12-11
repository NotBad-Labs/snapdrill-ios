import Foundation
import AVFoundation
import Vision

#if canImport(UIKit)
import UIKit
#endif

/// 文档扫描服务（简化版 - MVP）
///
/// 使用 Vision 框架进行文档检测
/// 实现基本的状态管理
@available(iOS 17.0, *)
public final class DocumentScannerService: NSObject, Sendable {
    
    // MARK: - Properties
    
    /// 当前扫描状态（使用 @MainActor 保护）
    @MainActor
    public private(set) var currentState: ScanState = .searching
    
    /// 状态变化回调
    nonisolated(unsafe) public var onStateChange: (@Sendable (ScanState) async -> Void)?
    
    // MARK: - Public API
    
    /// 检测图片中的文档（静态检测）
    ///
    /// - Parameter image: 输入图片
    /// - Returns: DraftScan 如果检测成功
    public func detectDocument(in image: PlatformImage) async throws -> DraftScan? {
        let detector = LiveDocumentDetector()
        let result = await detector.detectDocument(in: image)
        
        guard case .detected(let box, let corners, let confidence, let area) = result else {
            return nil
        }
        
        // TODO: 实现 OCR 和图像处理
        let draftScan = DraftScan(
            originalImage: Data(), // 临时
            processedImage: Data(), // 临时
            extractedText: "检测到文档，待实现 OCR",
            documentRect: box,
            confidence: confidence
        )
        
        return draftScan
    }
}

// MARK: - Captured Document

@available(iOS 17.0, *)
public struct CapturedDocument: Sendable {
    /// 原始图片
    public let originalImage: Data
    
    /// 矫正后的图片
    public let correctedImage: Data
    
    /// 文档边界
    public let documentRect: CGRect
    
    /// 置信度
    public let confidence: Float
}

// MARK: - Errors

public enum ScanError: Error, LocalizedError {
    case cameraPermissionDenied
    case cameraNotAvailable
    case cannotAddInput
    case cannotAddOutput
    case notReady
    case notImplemented
    
    public var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "相机权限被拒绝，请在设置中允许访问"
        case .cameraNotAvailable:
            return "相机不可用"
        case .cannotAddInput:
            return "无法添加相机输入"
        case .cannotAddOutput:
            return "无法添加视频输出"
        case .notReady:
            return "请等待检测到文档后再拍照"
        case .notImplemented:
            return "功能尚未实现"
        }
    }
}
