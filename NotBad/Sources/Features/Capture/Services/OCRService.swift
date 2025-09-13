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
enum OCRError: LocalizedError, CaseIterable {
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

/// 网络错误
enum NetworkError: LocalizedError, CaseIterable {
    case noConnection
    case timeout
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "网络连接不可用"
        case .timeout:
            return "网络请求超时"
        case .invalidResponse:
            return "无效的网络响应"
        }
    }
}

/// 同步错误
enum SyncError: LocalizedError, CaseIterable {
    case conflictDetected
    case quotaExceeded
    case cloudKitUnavailable
    
    var errorDescription: String? {
        switch self {
        case .conflictDetected:
            return "检测到数据冲突"
        case .quotaExceeded:
            return "存储配额已满"
        case .cloudKitUnavailable:
            return "CloudKit服务不可用"
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
                
                let request = VNRecognizeTextRequest { [weak self] request, error in
                    self?.handleRecognitionResult(request: request, error: error, startTime: startTime, continuation: continuation)
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
    
    // MARK: - Private Methods
    
    private func handleRecognitionResult(request: VNRequest, error: Error?, startTime: CFAbsoluteTime, continuation: CheckedContinuation<OCRResult, Error>) {
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        if error != nil {
            continuation.resume(throwing: OCRError.recognitionFailed)
            return
        }
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            continuation.resume(throwing: OCRError.recognitionFailed)
            return
        }
        
        let result = createOCRResult(from: observations, processingTime: processingTime)
        continuation.resume(returning: result)
    }
    
    private func createOCRResult(from observations: [VNRecognizedTextObservation], processingTime: TimeInterval) -> OCRResult {
        var recognizedText = ""
        var boundingBoxes: [BoundingBox] = []
        var totalConfidence: Double = 0
        var validObservations = 0
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let confidence = Double(topCandidate.confidence)
            if confidence >= confidenceThreshold {
                recognizedText += topCandidate.string + "\n"
                
                let convertedRect = convertBoundingBox(observation.boundingBox)
                boundingBoxes.append(BoundingBox(
                    text: topCandidate.string,
                    confidence: confidence,
                    rect: convertedRect
                ))
                
                totalConfidence += confidence
                validObservations += 1
            }
        }
        
        recognizedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if recognizedText.isEmpty {
            fatalError("No text recognized")
        }
        
        let averageConfidence = validObservations > 0 ? totalConfidence / Double(validObservations) : 0
        
        return OCRResult(
            text: recognizedText,
            confidence: averageConfidence,
            boundingBoxes: boundingBoxes,
            processingTime: processingTime
        )
    }
    
    private func convertBoundingBox(_ boundingBox: CGRect) -> CGRect {
        return CGRect(
            x: boundingBox.minX,
            y: 1.0 - boundingBox.maxY,
            width: boundingBox.width,
            height: boundingBox.height
        )
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
