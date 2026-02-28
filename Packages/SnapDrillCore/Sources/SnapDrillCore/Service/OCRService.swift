//
//  OCRService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  OCR 服务，封装 Vision 框架提供图片文字识别能力。
//

#if canImport(UIKit)
import UIKit
#endif
import Vision

/// 光学字符识别服务协议
public protocol OCRServiceProtocol: Sendable {
    func recognizeText(from cgImage: CGImage) async throws -> String
}

/// 光学字符识别服务
///
/// 封装 Apple Vision 框架的 `VNRecognizeTextRequest`，提供异步的图片文字识别能力。
///
/// ## 功能
/// - 支持多语言识别（中文、英文）。
/// - 自动进行语言校正。
/// - 使用 `.accurate` 模式以确保最高识别率。
public actor OCRService: OCRServiceProtocol {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    ///
    /// 异步执行文本识别任务。
    ///
    /// - Parameter cgImage: 包含文字的图片（推荐经过文档扫描校正后的图片）
    /// - Returns: 识别出的所有文本，按行拼接，以换行符 `\n` 分隔
    /// - Throws: `OCRError` 如果识别请求失败
    public func recognizeText(from cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    // Return the top candidate
                    return observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            // Configuration
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "en-US"] // Support Chinese and English
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

public enum OCRError: Error {
    case invalidImage
}
