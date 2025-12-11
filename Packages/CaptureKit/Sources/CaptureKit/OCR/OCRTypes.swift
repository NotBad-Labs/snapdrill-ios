// OCRKit - 文字识别核心库
//
// 基于 Apple Vision 框架的 OCR 服务。
// 支持 iOS 和 macOS。

import Foundation
import Vision

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - OCRResult

/// OCR 识别结果
public struct OCRResult: Sendable, Equatable {
    /// 完整识别文本
    public let text: String
    
    /// 按行分割的识别结果
    public let lines: [OCRLine]
    
    /// 平均置信度（0.0 - 1.0）
    public let confidence: Double
    
    /// 空结果
    public static let empty = OCRResult(text: "", lines: [], confidence: 0)
    
    public init(text: String, lines: [OCRLine], confidence: Double) {
        self.text = text
        self.lines = lines
        self.confidence = confidence
    }
    
    /// 置信度描述
    public var confidenceDescription: String {
        switch confidence {
        case 0.9...: "识别置信度很高"
        case 0.7..<0.9: "识别置信度良好"
        case 0.5..<0.7: "识别置信度一般"
        default: "识别置信度较低，建议检查"
        }
    }
    
    /// 是否高置信度
    public var isHighConfidence: Bool {
        confidence >= 0.8
    }
}

// MARK: - Coordinate System

/// 坐标系类型
///
/// 不同来源的 OCR 结果使用不同的坐标系：
/// - Vision 框架：归一化坐标，原点左下
/// - DataScanner：像素坐标，原点左上
public enum OCRCoordinateSystem: String, Sendable {
    /// Vision 归一化坐标（0-1，原点左下，Y 轴向上）
    case visionNormalized
    /// 像素坐标（原点左上，Y 轴向下）
    case pixelTopLeft
}

// MARK: - OCRLine

/// OCR 识别的单行结果
///
/// ⚠️ 坐标系说明：
/// - 来自 `OCRService`（Vision）：归一化坐标（0-1），原点左下
/// - 来自 `ScannerService`（DataScanner）：像素坐标，原点左上
///
/// 使用 `coordinateSystem` 属性来确定如何转换坐标。
public struct OCRLine: Sendable, Equatable {
    /// 文本内容
    public let text: String
    
    /// 置信度（0.0 - 1.0）
    public let confidence: Float
    
    /// 边界框
    ///
    /// ⚠️ 坐标系取决于来源：
    /// - Vision：归一化坐标 (0-1)，原点左下
    /// - DataScanner：像素坐标，原点左上
    public let boundingBox: CGRect
    
    /// 坐标系类型（默认 Vision 归一化坐标）
    public let coordinateSystem: OCRCoordinateSystem
    
    public init(
        text: String,
        confidence: Float,
        boundingBox: CGRect,
        coordinateSystem: OCRCoordinateSystem = .visionNormalized
    ) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.coordinateSystem = coordinateSystem
    }
    
    /// 转换为 UIKit 坐标系（原点左上）
    ///
    /// - Parameter imageSize: 原图尺寸
    /// - Returns: 像素坐标的边界框
    public func boundingBoxInUIKit(imageSize: CGSize) -> CGRect {
        switch coordinateSystem {
        case .visionNormalized:
            // Vision 坐标系转换：Y 轴翻转 + 乘以图片尺寸
            return CGRect(
                x: boundingBox.origin.x * imageSize.width,
                y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
                width: boundingBox.width * imageSize.width,
                height: boundingBox.height * imageSize.height
            )
        case .pixelTopLeft:
            // 已经是像素坐标，直接返回
            return boundingBox
        }
    }
}

// MARK: - OCRError

/// OCR 识别错误
public enum OCRError: LocalizedError, Sendable {
    /// 图片格式无效
    case invalidImage
    
    /// 识别处理失败
    case recognitionFailed
    
    /// 未识别到文字
    case noTextFound
    
    /// 超时
    case timeout
    
    /// 错误的人类可读描述
    public var errorDescription: String? {
        switch self {
        case .invalidImage: "图片格式无效，请重新选择"
        case .recognitionFailed: "文字识别失败，请重试"
        case .noTextFound: "未识别到文字，请确保图片清晰"
        case .timeout: "识别超时，请重试"
        }
    }
    
    /// 给用户的恢复建议
    public var recoverySuggestion: String? {
        switch self {
        case .invalidImage: "请选择 JPEG 或 PNG 格式的图片"
        case .recognitionFailed: "请确保图片清晰，光线充足"
        case .noTextFound: "请确保图片中包含文字内容"
        case .timeout: "图片过大或设备负载较高，请稍后重试"
        }
    }
}

// MARK: - OCRServiceProtocol

/// OCR 服务协议
///
/// 定义文字识别服务的抽象接口，支持依赖注入和测试。
/// 方法可在任意线程调用，内部处理线程安全。
public protocol OCRServiceProtocol: Sendable {
    
    /// 从图片中识别文字
    func recognizeText(from image: PlatformImage) async throws -> String
    
    /// 从图片中识别文字（带置信度）
    func recognizeTextWithConfidence(from image: PlatformImage) async throws -> OCRResult
}

// MARK: - Default Implementation

/// OCR 协议的默认实现，便于复用简化版接口
public extension OCRServiceProtocol {
    func recognizeText(from image: PlatformImage) async throws -> String {
        let result = try await recognizeTextWithConfidence(from: image)
        return result.text
    }
}
