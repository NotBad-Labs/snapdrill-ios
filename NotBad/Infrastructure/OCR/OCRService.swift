//
//  OCRService.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import UIKit
import Vision

// MARK: - OCRService

/// OCR 文字识别服务
///
/// 基于 Apple Vision 框架实现的文字识别服务，支持中英文混合识别。
///
/// ## 功能特性
///
/// - 支持中文简体、繁体和英文识别
/// - 精确识别模式，适合印刷体和手写体
/// - 语言校正，提高识别准确率
/// - 返回置信度信息
///
/// ## 使用示例
///
/// ```swift
/// let service = OCRService.shared
///
/// do {
///     let result = try await service.recognizeText(from: image)
///     print("识别文本: \(result.text)")
///     print("置信度: \(result.confidence)")
/// } catch {
///     print("识别失败: \(error)")
/// }
/// ```
///
/// - Note: 使用单例模式，通过 `.shared` 访问
/// - Important: 识别是异步操作，可能需要数秒时间
@MainActor
final class OCRService: OCRServiceProtocol {

    // MARK: - Singleton

    /// 共享实例
    static let shared = OCRService()

    // MARK: - Configuration

    /// 识别级别
    private let recognitionLevel: VNRequestTextRecognitionLevel = .accurate

    /// 支持的语言
    private let recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]

    /// 是否使用语言校正
    private let usesLanguageCorrection = true

    // MARK: - Initialization

    private init() {}

    // MARK: - Recognition

    /// 从图片中识别文字
    ///
    /// 使用 Vision 框架进行文字识别，支持中英文混合内容。
    ///
    /// - Parameter image: 要识别的图片
    /// - Returns: 识别结果，包含文本和置信度
    /// - Throws: `OCRError` 当识别失败时
    func recognizeText(from image: UIImage) async throws -> String {
        let result = try await recognizeTextWithConfidence(from: image)
        return result.text
    }

    /// 从图片中识别文字（带置信度）
    ///
    /// - Parameter image: 要识别的图片
    /// - Returns: 识别结果，包含文本和置信度
    /// - Throws: `OCRError` 当识别失败时
    func recognizeTextWithConfidence(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            let request = VNRecognizeTextRequest { [weak self] request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                    return
                }

                let result = self?.processObservations(observations) ?? OCRResult.empty

                if result.text.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: result)
                }
            }

            // 配置识别参数
            request.recognitionLevel = recognitionLevel
            request.recognitionLanguages = recognitionLanguages
            request.usesLanguageCorrection = usesLanguageCorrection

            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// 处理识别结果
    private func processObservations(_ observations: [VNRecognizedTextObservation]) -> OCRResult {
        var lines: [OCRLine] = []
        var totalConfidence: Float = 0

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }

            let line = OCRLine(
                text: candidate.string,
                confidence: candidate.confidence,
                boundingBox: observation.boundingBox
            )
            lines.append(line)
            totalConfidence += candidate.confidence
        }

        let averageConfidence = lines.isEmpty ? 0 : totalConfidence / Float(lines.count)
        let fullText = lines.map { $0.text }.joined(separator: "\n")

        return OCRResult(
            text: fullText,
            lines: lines,
            confidence: Double(averageConfidence)
        )
    }

    // MARK: - Text Extraction

    /// 从识别的文字中提取标题
    ///
    /// 提取第一行文字作为标题，最多 50 个字符。
    ///
    /// - Parameter text: 完整识别文本
    /// - Returns: 提取的标题
    func extractTitle(from text: String) -> String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = String(trimmed.prefix(50))
        return title.isEmpty ? "未命名错题" : title
    }

    /// 提取题目中的数学公式（简单识别）
    ///
    /// - Parameter text: 完整识别文本
    /// - Returns: 识别到的数学表达式列表
    func extractMathExpressions(from text: String) -> [String] {
        // 简单的数学表达式模式匹配
        let patterns = [
            "[0-9]+[+\\-×÷*/=][0-9]+",  // 基本运算
            "[a-zA-Z]\\^[0-9]+",         // 幂运算
            "√[0-9]+",                    // 根号
            "[0-9]+/[0-9]+"              // 分数
        ]

        var expressions: [String] = []

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, range: range)

                for match in matches {
                    if let range = Range(match.range, in: text) {
                        expressions.append(String(text[range]))
                    }
                }
            }
        }

        return expressions
    }
}

// MARK: - OCRResult

/// OCR 识别结果
struct OCRResult: Sendable, Equatable {
    /// 完整识别文本
    let text: String

    /// 按行分割的识别结果
    let lines: [OCRLine]

    /// 平均置信度（0.0 - 1.0）
    let confidence: Double

    /// 空结果
    static let empty = OCRResult(text: "", lines: [], confidence: 0)

    /// 置信度描述
    var confidenceDescription: String {
        switch confidence {
        case 0.9...: "识别置信度很高"
        case 0.7..<0.9: "识别置信度良好"
        case 0.5..<0.7: "识别置信度一般"
        default: "识别置信度较低，建议检查"
        }
    }

    /// 是否高置信度
    var isHighConfidence: Bool {
        confidence >= 0.8
    }
}

// MARK: - OCRLine

/// OCR 识别的单行结果
struct OCRLine: Sendable, Equatable {
    /// 文本内容
    let text: String

    /// 置信度（0.0 - 1.0）
    let confidence: Float

    /// 边界框（归一化坐标）
    let boundingBox: CGRect
}

// MARK: - OCRError

/// OCR 识别错误
enum OCRError: LocalizedError, Sendable {
    /// 图片格式无效
    case invalidImage

    /// 识别处理失败
    case recognitionFailed

    /// 未识别到文字
    case noTextFound

    /// 超时
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidImage: String(localized: "ocr_error_invalid_image", defaultValue: "图片格式无效，请重新选择")
        case .recognitionFailed: String(localized: "ocr_error_recognition_failed", defaultValue: "文字识别失败，请重试")
        case .noTextFound: String(localized: "ocr_error_no_text_found", defaultValue: "未识别到文字，请确保图片清晰")
        case .timeout: String(localized: "ocr_error_timeout", defaultValue: "识别超时，请重试")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidImage: String(localized: "ocr_suggestion_invalid_image", defaultValue: "请选择 JPEG 或 PNG 格式的图片")
        case .recognitionFailed: String(localized: "ocr_suggestion_recognition_failed", defaultValue: "请确保图片清晰，光线充足")
        case .noTextFound: String(localized: "ocr_suggestion_no_text_found", defaultValue: "请确保图片中包含文字内容")
        case .timeout: String(localized: "ocr_suggestion_timeout", defaultValue: "图片过大或设备负载较高，请稍后重试")
        }
    }
}
