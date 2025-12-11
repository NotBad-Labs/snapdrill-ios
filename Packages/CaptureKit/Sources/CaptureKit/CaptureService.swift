// CaptureKit - 统一录入服务
//
// 提供完整的录入链路：拍照/选图 → OCR → 保存
// 作为 CaptureKit 的统一入口
//
// 支持三种识别方式：
// 1. OCRService - 静态图片 OCR（Vision 框架）
// 2. LiveTextService - 图片上的交互式文字（VisionKit）
// 3. ScannerService - 相机实时扫描（VisionKit）

import Foundation
import VisionKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - CaptureResult

/// 录入结果
public struct CaptureResult: Sendable {
    /// 识别的文本
    public let text: String
    
    /// OCR 详细结果
    public let ocrResult: OCRResult
    
    /// 保存的图片文件名
    public let imageFileName: String
    
    /// 建议的标题（从 OCR 提取）
    public let suggestedTitle: String
    
    public init(
        text: String,
        ocrResult: OCRResult,
        imageFileName: String,
        suggestedTitle: String
    ) {
        self.text = text
        self.ocrResult = ocrResult
        self.imageFileName = imageFileName
        self.suggestedTitle = suggestedTitle
    }
}

// MARK: - CaptureError

/// 录入错误
public enum CaptureError: LocalizedError, Sendable {
    /// 图片无效
    case invalidImage
    
    /// OCR 识别失败
    case ocrFailed(OCRError)
    
    /// 图片保存失败
    case saveFailed
    
    /// 用户可读的错误描述
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "图片无效，请重新选择"
        case .ocrFailed(let error):
            return error.errorDescription
        case .saveFailed:
            return "图片保存失败，请重试"
        }
    }
}

// MARK: - CaptureService

/// 统一录入服务
///
/// 提供完整的录入链路，将 OCR 识别和图片存储整合为一个简单的 API。
///
/// ## 使用示例
///
/// ```swift
/// let capture = CaptureService.shared
///
/// do {
///     let result = try await capture.process(image: selectedImage, itemId: newItem.id)
///     newItem.imagePath = result.imageFileName
///     newItem.content = result.text
///     newItem.title = result.suggestedTitle
/// } catch {
///     print("录入失败: \(error)")
/// }
/// ```
public final class CaptureService: @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// 共享实例
    public static let shared = CaptureService()
    
    // MARK: - Dependencies
    
    private let ocrService: OCRService
    private let imageStorage: ImageStorageClient
    
    // MARK: - Initialization
    
    public init(
        ocrService: OCRService = .shared,
        imageStorage: ImageStorageClient = ImageStorageService()
    ) {
        self.ocrService = ocrService
        self.imageStorage = imageStorage
    }
    
    // MARK: - Public API
    
    /// 处理图片：OCR + 保存。
    ///
    /// 完整流程：
    /// 1. 执行 OCR 识别
    /// 2. 保存图片到磁盘
    /// 3. 提取建议标题
    ///
    /// - Parameters:
    ///   - image: 待处理的图片
    ///   - itemId: 关联的 ReviewItem ID
    ///   - compressionQuality: 图片压缩质量（默认 0.8）
    /// - Returns: 录入结果
    public func process(
        image: PlatformImage,
        itemId: UUID,
        compressionQuality: CGFloat = 0.8
    ) async throws -> CaptureResult {
        // Step 1: OCR 识别
        let ocrResult: OCRResult
        do {
            ocrResult = try await ocrService.recognizeTextWithConfidence(from: image)
        } catch let error as OCRError {
            throw CaptureError.ocrFailed(error)
        } catch {
            throw CaptureError.ocrFailed(.recognitionFailed)
        }
        
        // Step 2: 保存图片
        let fileName = try await imageStorage.saveImage(
            image,
            id: itemId,
            compressionQuality: compressionQuality
        )
        
        // Step 3: 提取标题
        let title = ocrService.extractTitle(from: ocrResult.text)
        
        return CaptureResult(
            text: ocrResult.text,
            ocrResult: ocrResult,
            imageFileName: fileName,
            suggestedTitle: title
        )
    }
    
    /// 仅执行 OCR（不保存图片），用于预览或验证场景。
    public func recognizeOnly(image: PlatformImage) async throws -> OCRResult {
        do {
            return try await ocrService.recognizeTextWithConfidence(from: image)
        } catch let error as OCRError {
            throw CaptureError.ocrFailed(error)
        } catch {
            throw CaptureError.ocrFailed(.recognitionFailed)
        }
    }
    
    /// 仅保存图片（不执行 OCR），用于手动录入场景。
    public func saveOnly(
        image: PlatformImage,
        itemId: UUID,
        compressionQuality: CGFloat = 0.8
    ) async throws -> String {
        try await imageStorage.saveImage(
            image,
            id: itemId,
            compressionQuality: compressionQuality
        )
    }
    
    // MARK: - Image Management (Delegate to ImageStorageService)
    
    /// 加载图片
    /// - Parameter fileName: 文件名
    /// - Returns: 图片或 nil
    public func loadImage(fileName: String?) async -> PlatformImage? {
        await imageStorage.loadImage(named: fileName)
    }
    
    /// 删除单张图片
    /// - Parameter fileName: 文件名
    public func deleteImage(fileName: String?) async {
        await imageStorage.deleteImage(named: fileName)
    }
    
    /// 批量删除图片
    /// - Parameter fileNames: 文件名列表
    public func deleteImages(fileNames: [String?]) async {
        await imageStorage.deleteImages(named: fileNames)
    }
    
    /// 检查图片是否存在
    /// - Parameter fileName: 文件名
    /// - Returns: 是否存在
    public func imageExists(fileName: String?) async -> Bool {
        await imageStorage.exists(named: fileName)
    }
    
    // MARK: - Statistics
    
    /// 图片存储大小（格式化）
    public var storageSize: String {
        get async { await imageStorage.formattedSize }
    }
    
    /// 图片数量
    public var imageCount: Int {
        get async { await imageStorage.imageCount }
    }
}

// MARK: - Convenience Extensions

/// CaptureService 的便捷封装，提供轻量级返回值
public extension CaptureService {
    
    /// 处理图片并返回简化结果（仅文本和文件名）
    func processSimple(
        image: PlatformImage,
        itemId: UUID
    ) async throws -> (text: String, fileName: String) {
        let result = try await process(image: image, itemId: itemId)
        return (result.text, result.imageFileName)
    }
}

// MARK: - Live Text Support

#if canImport(UIKit)
@available(iOS 16.0, *)
/// CaptureService 的 Live Text 相关便捷方法
public extension CaptureService {
    
    // MARK: - Availability
    
    /// 是否支持 Live Text
    static var isLiveTextSupported: Bool {
        LiveTextService.isSupported
    }
    
    /// 是否支持相机扫描
    @MainActor
    static var isScannerSupported: Bool {
        ScannerService.isSupported
    }
    
    /// 相机扫描是否可用（已授权）
    @MainActor
    static var isScannerAvailable: Bool {
        ScannerService.isAvailable
    }
    
    // MARK: - Live Text Processing
    
    /// 使用 Live Text 分析图片
    /// - Parameter image: 待分析图片
    /// - Returns: 用于交互展示的 `ImageAnalysis`
    func analyzeLiveText(image: UIImage) async throws -> ImageAnalysis {
        try await LiveTextService.shared.analyze(image: image)
    }
    
    /// 使用 Live Text 提取文字（基于 VisionKit）。
    /// - Parameter image: 待提取图片
    /// - Returns: 提取出的纯文本
    func extractTextWithLiveText(from image: UIImage) async throws -> String {
        try await LiveTextService.shared.extractText(from: image)
    }
    
    // MARK: - Scanner Result Processing
    
    /// 处理扫描结果，将 `ScanResult` 转换为 `CaptureResult` 并保存图片。
    /// 保留位置信息，便于未来高亮文字。
    /// - Parameters:
    ///   - scanResult: 扫描结果
    ///   - itemId: 业务 ID
    /// - Returns: 标准化的 CaptureResult
    func processScanResult(_ scanResult: ScanResult, itemId: UUID) async throws -> CaptureResult {
        var imageFileName: String? = nil
        
        // 保存照片（如果有）
        if let photo = scanResult.photo {
            imageFileName = try? await imageStorage.saveImage(photo, id: itemId)
        }
        
        // 提取标题
        let title = ocrService.extractTitle(from: scanResult.text)
        
        // 将 ScanResult 的位置信息转换为 OCRResult 格式
        // ⚠️ DataScanner 返回像素坐标（原点左上），与 Vision 的归一化坐标不同
        let ocrResult: OCRResult
        if scanResult.hasPositionInfo {
            // 保留位置信息，支持未来高亮功能
            let lines = scanResult.items.map { item in
                OCRLine(
                    text: item.transcript,
                    confidence: 1.0,  // Scanner 不提供置信度，假设为 1.0
                    boundingBox: item.boundingBox,
                    coordinateSystem: .pixelTopLeft  // DataScanner 使用像素坐标
                )
            }
            ocrResult = OCRResult(text: scanResult.text, lines: lines, confidence: 1.0)
        } else {
            // 降级处理：无位置信息
            ocrResult = OCRResult(text: scanResult.text, lines: [], confidence: 1.0)
        }
        
        return CaptureResult(
            text: scanResult.text,
            ocrResult: ocrResult,
            imageFileName: imageFileName ?? "",
            suggestedTitle: title
        )
    }
}
#endif
