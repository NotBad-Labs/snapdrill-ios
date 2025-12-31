//
//  OCRService.swift
//  NotBadService
//
//  Created by Yiming Liao on 2025/12/30.
//  Copyright © 2025 NotBad Team. All rights reserved.
//

import UIKit
import Vision

/// 光学字符识别服务
///
/// 封装 Apple Vision 框架的 `VNRecognizeTextRequest`，提供异步的图片文字识别能力。
///
/// ## 功能
/// - 支持多语言识别（中文、英文）。
/// - 自动进行语言校正。
/// - 使用 `.accurate` 模式以确保最高识别率。
public actor OCRService {
    
    public init() {}
    
    /// 从图片中识别文本
    ///
    /// 异步执行文本识别任务。
    ///
    /// - Parameter image: 包含文字的图片（推荐经过文档扫描校正后的图片）
    /// - Returns: 识别出的所有文本，按行拼接，以换行符 `\n` 分隔
    /// - Throws: `OCRError` 如果图片无效或识别请求失败
    public func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
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
