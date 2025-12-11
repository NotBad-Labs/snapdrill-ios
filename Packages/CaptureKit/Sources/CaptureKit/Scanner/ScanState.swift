import Foundation
import CoreGraphics

/// 扫描状态机（三层漏斗模型）
///
/// 状态流转：
/// searching → detected → capturing → processing → completed
@available(iOS 17.0, macOS 14.0, *)
public enum ScanState: Sendable {
    /// 第一层：实时感知 - 寻找文档
    case searching
    
    /// 第一层：检测到文档（含边界矩形）
    case detected(documentRect: CGRect, confidence: Float)
    
    /// 第二层：采集中
    case capturing
    
    /// 第二层：AI 处理中（去手写 + OCR）
    case processing(progress: Float)
    
    /// 第三层：等待用户确认
    case awaitingConfirmation(draft: DraftScan)
    
    /// 完成（已保存到 ReviewKit）
    case completed
    
    /// 错误
    case failed(Error)
    
    // MARK: - Helpers
    
    /// 是否可以拍照
    public var canCapture: Bool {
        if case .detected = self {
            return true
        }
        return false
    }
    
    /// 是否正在处理
    public var isProcessing: Bool {
        if case .processing = self {
            return true
        }
        return false
    }
}

// MARK: - Equatable (简化比较)

@available(iOS 17.0, macOS 14.0, *)
extension ScanState: Equatable {
    public static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.searching, .searching):
            return true
        case (.detected(let rect1, let conf1), .detected(let rect2, let conf2)):
            return rect1 == rect2 && conf1 == conf2
        case (.capturing, .capturing):
            return true
        case (.processing(let p1), .processing(let p2)):
            return p1 == p2
        case (.awaitingConfirmation(let d1), .awaitingConfirmation(let d2)):
            return d1.id == d2.id
        case (.completed, .completed):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

/// 草稿扫描对象（临时，未进入 ReviewKit）
///
/// 用途：
/// - 用户确认前的中间产物
/// - 避免"拍到猫"污染数据库
@available(iOS 17.0, macOS 14.0, *)
public struct DraftScan: Sendable, Identifiable {
    public let id: UUID
    
    /// 原始图片
    public let originalImage: Data
    
    /// 处理后的图片（去手写、裁剪）
    public let processedImage: Data
    
    /// OCR 提取的文字
    public let extractedText: String
    
    /// 文档边界（归一化坐标 0-1）
    public let documentRect: CGRect
    
    /// 置信度（0-1）
    public let confidence: Float
    
    /// 创建时间
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        originalImage: Data,
        processedImage: Data,
        extractedText: String,
        documentRect: CGRect,
        confidence: Float,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.originalImage = originalImage
        self.processedImage = processedImage
        self.extractedText = extractedText
        self.documentRect = documentRect
        self.confidence = confidence
        self.createdAt = createdAt
    }
}

// MARK: - Validation

@available(iOS 17.0, macOS 14.0, *)
extension DraftScan {
    /// 是否是有效的试卷扫描
    ///
    /// 拦截"拍到猫"的逻辑：
    /// - 置信度过低
    /// - 文字量太少
    /// - 文档矩形异常
    public var isValid: Bool {
        // 置信度至少 60%
        guard confidence >= 0.6 else { return false }
        
        // 至少包含 20 个字符
        guard extractedText.count >= 20 else { return false }
        
        // 文档矩形合理（至少占画面 30%）
        let area = documentRect.width * documentRect.height
        guard area >= 0.3 else { return false }
        
        return true
    }
    
    /// 验证失败原因
    public enum ValidationError: Error, LocalizedError {
        case lowConfidence(Float)
        case insufficientText(Int)
        case invalidDocumentRect(CGFloat)
        
        public var errorDescription: String? {
            switch self {
            case .lowConfidence(let value):
                return "文档检测置信度过低：\(Int(value * 100))%，建议重新对准"
            case .insufficientText(let count):
                return "识别到的文字太少（\(count) 字符），可能不是试卷"
            case .invalidDocumentRect(let area):
                return "文档区域异常（\(Int(area * 100))%），请调整拍摄角度"
            }
        }
    }
    
    /// 执行验证，失败时抛出具体错误
    public func validate() throws {
        if confidence < 0.6 {
            throw ValidationError.lowConfidence(confidence)
        }
        
        if extractedText.count < 20 {
            throw ValidationError.insufficientText(extractedText.count)
        }
        
        let area = documentRect.width * documentRect.height
        if area < 0.3 {
            throw ValidationError.invalidDocumentRect(area)
        }
    }
}
