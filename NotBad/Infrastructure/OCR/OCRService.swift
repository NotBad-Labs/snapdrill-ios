//
//  OCRService.swift
//  NotBad
//
//  OCR 文字识别服务
//

import UIKit
import Vision

@MainActor
final class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// 从图片中识别文字
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                    return
                }
                
                // 提取所有识别到的文字
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // 设置识别级别为精确模式
            request.recognitionLevel = .accurate
            // 支持中文识别
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 从识别的文字中提取标题（第一行或前30个字符）
    func extractTitle(from text: String) -> String {
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        let title = String(firstLine.prefix(30))
        return title.isEmpty ? "未命名错题" : title
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "图片格式无效"
        case .recognitionFailed:
            return "文字识别失败"
        case .noTextFound:
            return "未识别到文字"
        }
    }
}
