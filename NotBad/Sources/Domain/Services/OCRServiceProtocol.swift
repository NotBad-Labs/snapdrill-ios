import Foundation
import CoreGraphics

// MARK: - OCR Result Models
public struct OCRResult {
    public let recognizedText: String
    public let confidence: Float
    public let boundingBoxes: [OCRTextBlock]
    public let metadata: OCRMetadata
    
    public init(
        recognizedText: String,
        confidence: Float,
        boundingBoxes: [OCRTextBlock] = [],
        metadata: OCRMetadata = OCRMetadata()
    ) {
        self.recognizedText = recognizedText
        self.confidence = confidence
        self.boundingBoxes = boundingBoxes
        self.metadata = metadata
    }
}

public struct OCRTextBlock {
    public let text: String
    public let confidence: Float
    public let boundingBox: CGRect
    public let range: NSRange
    
    public init(text: String, confidence: Float, boundingBox: CGRect, range: NSRange) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.range = range
    }
}

public struct OCRMetadata {
    public let processedAt: Date
    public let processingTime: TimeInterval
    public let imageSize: CGSize
    public let language: String
    
    public init(
        processedAt: Date = Date(),
        processingTime: TimeInterval = 0,
        imageSize: CGSize = .zero,
        language: String = "zh-Hans"
    ) {
        self.processedAt = processedAt
        self.processingTime = processingTime
        self.imageSize = imageSize
        self.language = language
    }
}

// MARK: - OCR Service Protocol
public protocol OCRServiceProtocol {
    /// 识别图片中的文字
    /// - Parameter imageData: 图片数据
    /// - Returns: OCR识别结果
    func recognizeText(from imageData: Data) async throws -> OCRResult
    
    /// 重新处理图片（用户反馈识别不准确时）
    /// - Parameter imageData: 图片数据
    /// - Returns: 重新识别的结果列表（可能包含多种策略的结果）
    func reprocessImage(_ imageData: Data) async throws -> [OCRResult]
    
    /// 验证OCR结果质量
    /// - Parameter result: OCR结果
    /// - Returns: 是否通过质量检查
    func validateResult(_ result: OCRResult) -> Bool
    
    /// 获取支持的语言列表
    /// - Returns: 支持的语言代码数组
    func getSupportedLanguages() -> [String]
}

// MARK: - OCR Error Types
public enum OCRError: Error, CaseIterable {
    case invalidImageData
    case recognitionFailed
    case lowConfidence
    case unsupportedLanguage
    case processingTimeout
    case visionFrameworkUnavailable
    
    public var localizedDescription: String {
        switch self {
        case .invalidImageData:
            return "图片数据无效"
        case .recognitionFailed:
            return "文字识别失败"
        case .lowConfidence:
            return "识别置信度过低"
        case .unsupportedLanguage:
            return "不支持的语言"
        case .processingTimeout:
            return "处理超时"
        case .visionFrameworkUnavailable:
            return "Vision框架不可用"
        }
    }
}
