// OCRKit - OCR 服务实现
//
// 基于 Apple Vision 框架的文字识别服务。
// 线程安全：Vision 处理在后台执行，可在任意线程调用。

import Foundation
import Vision

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - OCRService

/// OCR 文字识别服务
///
/// 基于 Apple Vision 框架实现的文字识别服务，支持中英文混合识别。
/// 线程安全，可在任意线程调用，Vision 处理在后台执行。
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
///     print("识别文本: \(result)")
/// } catch {
///     print("识别失败: \(error)")
/// }
/// ```
public final class OCRService: OCRServiceProtocol, @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// 共享实例
    public static let shared = OCRService()
    
    // MARK: - Configuration (Thread-safe via lock)
    
    private let lock = NSLock()
    
    private var _recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    private var _recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
    private var _usesLanguageCorrection = true
    
    /// 识别级别
    public var recognitionLevel: VNRequestTextRecognitionLevel {
        get { lock.withLock { _recognitionLevel } }
        set { lock.withLock { _recognitionLevel = newValue } }
    }
    
    /// 支持的语言
    public var recognitionLanguages: [String] {
        get { lock.withLock { _recognitionLanguages } }
        set { lock.withLock { _recognitionLanguages = newValue } }
    }
    
    /// 是否使用语言校正
    public var usesLanguageCorrection: Bool {
        get { lock.withLock { _usesLanguageCorrection } }
        set { lock.withLock { _usesLanguageCorrection = newValue } }
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    /// 创建自定义配置的 OCR 服务
    public init(
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        languages: [String] = ["zh-Hans", "zh-Hant", "en-US"],
        usesLanguageCorrection: Bool = true
    ) {
        self._recognitionLevel = recognitionLevel
        self._recognitionLanguages = languages
        self._usesLanguageCorrection = usesLanguageCorrection
    }
    
    // MARK: - Recognition
    
    /// 从图片中识别文字（带置信度）
    ///
    /// Vision 处理在后台线程执行，不阻塞主线程。
    public func recognizeTextWithConfidence(from image: PlatformImage) async throws -> OCRResult {
        guard let cgImage = getCGImage(from: image) else {
            throw OCRError.invalidImage
        }
        
        // 捕获配置（线程安全）
        let level = recognitionLevel
        let languages = recognitionLanguages
        let useCorrection = usesLanguageCorrection
        
        // 在后台线程执行 Vision 识别
        return try await Task.detached(priority: .userInitiated) {
            try self.performRecognition(
                cgImage: cgImage,
                level: level,
                languages: languages,
                useCorrection: useCorrection
            )
        }.value
    }
    
    // MARK: - Private Helpers
    
    private func performRecognition(
        cgImage: CGImage,
        level: VNRequestTextRecognitionLevel,
        languages: [String],
        useCorrection: Bool
    ) throws -> OCRResult {
        var recognitionResult: OCRResult = .empty
        var recognitionError: Error?
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let request = VNRecognizeTextRequest { request, error in
            if let error {
                recognitionError = error
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                recognitionError = OCRError.recognitionFailed
                return
            }
            
            recognitionResult = self.processObservations(observations)
        }
        
        // 配置识别参数
        request.recognitionLevel = level
        request.recognitionLanguages = languages
        request.usesLanguageCorrection = useCorrection
        
        try requestHandler.perform([request])
        
        if let error = recognitionError {
            throw error
        }
        
        if recognitionResult.text.isEmpty {
            throw OCRError.noTextFound
        }
        
        return recognitionResult
    }
    
    private func getCGImage(from image: PlatformImage) -> CGImage? {
        #if canImport(UIKit)
        return image.cgImage
        #elseif canImport(AppKit)
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #endif
    }
    
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
}

// MARK: - Text Extraction Helpers

public extension OCRService {
    
    /// 从识别的文字中提取标题
    ///
    /// 提取第一行文字作为标题，最多 50 个字符。
    func extractTitle(from text: String) -> String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = String(trimmed.prefix(50))
        return title.isEmpty ? "未命名错题" : title
    }
    
    /// 提取题目中的数学公式（简单识别）
    func extractMathExpressions(from text: String) -> [String] {
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
