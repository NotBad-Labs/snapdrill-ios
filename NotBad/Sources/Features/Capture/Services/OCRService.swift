//
//  OCRService.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation
import Vision
import UIKit

/// OCR识别结果
struct OCRResult {
    let text: String
    let confidence: Double
    let boundingBoxes: [BoundingBox]
    let processingTime: TimeInterval
}

/// 文字边界框
struct BoundingBox {
    let text: String
    let confidence: Double
    let rect: CGRect
}

/// OCR识别错误
enum OCRError: LocalizedError {
    case invalidImage
    case lowConfidence(confidence: Double)
    case processingTimeout
    case recognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "图像格式无效或损坏"
        case .lowConfidence(let confidence):
            return "识别置信度过低: \(String(format: "%.1f", confidence * 100))%"
        case .processingTimeout:
            return "图像处理超时"
        case .recognitionFailed:
            return "文字识别失败"
        }
    }
}

/// OCR服务协议
protocol OCRServiceProtocol: Sendable {
    func recognizeText(from image: UIImage) async throws -> OCRResult
}

/// Vision OCR服务实现 - Phase 1
final class VisionOCRService: OCRServiceProtocol, @unchecked Sendable {
    private let visionQueue = DispatchQueue(label: "com.notbad.ocr", qos: .userInitiated)
    private let confidenceThreshold: Double = 0.6 // Phase 1使用较低阈值
    
    func recognizeText(from image: UIImage) async throws -> OCRResult {
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async {
                guard let cgImage = image.cgImage else {
                    continuation.resume(throwing: OCRError.invalidImage)
                    return
                }
                
                let startTime = CFAbsoluteTimeGetCurrent()
                
                let request = VNRecognizeTextRequest { request, error in
                    let processingTime = CFAbsoluteTimeGetCurrent() - startTime
                    
                if error != nil {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                    return
                }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(throwing: OCRError.recognitionFailed)
                        return
                    }
                    
                    var recognizedText = ""
                    var boundingBoxes: [BoundingBox] = []
                    var totalConfidence: Double = 0
                    var validObservations = 0
                    
                    for observation in observations {
                        guard let topCandidate = observation.topCandidates(1).first else { continue }
                        
                        let confidence = Double(topCandidate.confidence)
                        let threshold = self.confidenceThreshold
                        if confidence >= threshold {
                            recognizedText += topCandidate.string + "\n"
                            
                            // 转换坐标系统 (Vision使用左下角原点，UIKit使用左上角原点)
                            let boundingBox = observation.boundingBox
                            let convertedRect = CGRect(
                                x: boundingBox.minX,
                                y: 1.0 - boundingBox.maxY, // 翻转Y坐标
                                width: boundingBox.width,
                                height: boundingBox.height
                            )
                            
                            boundingBoxes.append(BoundingBox(
                                text: topCandidate.string,
                                confidence: confidence,
                                rect: convertedRect
                            ))
                            
                            totalConfidence += confidence
                            validObservations += 1
                        }
                    }
                    
                    // 移除最后的换行符
                    recognizedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if recognizedText.isEmpty {
                        continuation.resume(throwing: OCRError.lowConfidence(confidence: 0))
                        return
                    }
                    
                    let averageConfidence = validObservations > 0 ? totalConfidence / Double(validObservations) : 0
                    
                    let result = OCRResult(
                        text: recognizedText,
                        confidence: averageConfidence,
                        boundingBoxes: boundingBoxes,
                        processingTime: processingTime
                    )
                    
                    continuation.resume(returning: result)
                }
                
                // 配置识别参数
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.automaticallyDetectsLanguage = true
                
                // 设置支持的语言（中文和英文）
                // 注意：supportedLanguages 在较新版本的 Vision 框架中可用
                // 这里使用更兼容的方式
                request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"]
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                }
            }
        }
    }
}

/// OCR服务管理器 - 单例
@MainActor
class OCRServiceManager: ObservableObject {
    static let shared = OCRServiceManager()
    
    private let ocrService: OCRServiceProtocol
    
    private init() {
        self.ocrService = VisionOCRService()
    }
    
    nonisolated func recognizeText(from image: UIImage) async throws -> OCRResult {
        let service = ocrService
        return try await service.recognizeText(from: image)
    }
}
