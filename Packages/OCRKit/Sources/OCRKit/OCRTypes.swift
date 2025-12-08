// OCRKit - 文字识别核心库
//
// 基于 Apple Vision 框架的 OCR 服务。
// 支持 iOS 和 macOS。

import Foundation
import Vision

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
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

// MARK: - OCRLine

/// OCR 识别的单行结果
public struct OCRLine: Sendable, Equatable {
    /// 文本内容
    public let text: String
    
    /// 置信度（0.0 - 1.0）
    public let confidence: Float
    
    /// 边界框（归一化坐标）
    public let boundingBox: CGRect
    
    public init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
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
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage: "图片格式无效，请重新选择"
        case .recognitionFailed: "文字识别失败，请重试"
        case .noTextFound: "未识别到文字，请确保图片清晰"
        case .timeout: "识别超时，请重试"
        }
    }
    
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
public protocol OCRServiceProtocol: AnyObject, Sendable {
    
    /// 从图片中识别文字
    func recognizeText(from image: PlatformImage) async throws -> String
    
    /// 从图片中识别文字（带置信度）
    func recognizeTextWithConfidence(from image: PlatformImage) async throws -> OCRResult
}

// MARK: - Default Implementation

public extension OCRServiceProtocol {
    func recognizeText(from image: PlatformImage) async throws -> String {
        let result = try await recognizeTextWithConfidence(from: image)
        return result.text
    }
}
