import Foundation
import Vision
import AVFoundation
import CoreImage

#if canImport(UIKit)
import UIKit
#endif

/// 实时文档检测器（Live Detection）
///
/// 职责：
/// - 分析摄像头实时视频流
/// - 检测文档边界（四边形）
/// - 判断是否可以拍照
///
/// 使用场景：
/// - ScanState.searching → detected 转换
/// - 实时 UI 反馈（绿框/提示）
@available(iOS 17.0, macOS 14.0, *)
public actor LiveDocumentDetector {
    
    // MARK: - Configuration
    
    public struct Configuration: Sendable {
        /// 最低置信度（0-1）
        public let minimumConfidence: Float
        
        /// 最小文档面积（占画面比例 0-1）
        public let minimumArea: Float
        
        /// 检测频率（每秒帧数）
        public let detectionFPS: Int
        
        public init(
            minimumConfidence: Float = 0.6,
            minimumArea: Float = 0.3,
            detectionFPS: Int = 5
        ) {
            self.minimumConfidence = minimumConfidence
            self.minimumArea = minimumArea
            self.detectionFPS = detectionFPS
        }
    }
    
    // MARK: - Properties
    
    private let configuration: Configuration
    private var lastDetectionTime: Date = .distantPast
    private var detectionRequest: VNDetectRectanglesRequest?
    
    /// 检测结果回调
    public var onDetection: (@Sendable (DetectionResult) -> Void)?
    
    // MARK: - Initialization
    
    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
        // setupVisionRequest 将在首次使用时调用
    }
    
    // MARK: - Public API
    
    /// 处理视频帧（从相机回调中调用）
    ///
    /// - Parameter sampleBuffer: 相机视频帧
    public func processFrame(_ sampleBuffer: CMSampleBuffer) async {
        // 控制检测频率（避免过度消耗）
        let interval = 1.0 / Double(configuration.detectionFPS)
        guard Date().timeIntervalSince(lastDetectionTime) >= interval else {
            return
        }
        lastDetectionTime = Date()
        
        // 提取图像
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            await sendResult(.notFound(reason: "无法提取视频帧"))
            return
        }
        
        // Vision 检测
        await performDetection(on: pixelBuffer)
    }
    
    /// 处理单张图片（用于测试或静态检测）
    ///
    /// - Parameter image: 输入图片
    /// - Returns: 检测结果
    public func detectDocument(in image: PlatformImage) async -> DetectionResult {
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else {
            return .notFound(reason: "无法转换图片")
        }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .notFound(reason: "无法转换图片")
        }
        let ciImage = CIImage(cgImage: cgImage)
        #endif
        
        return await withCheckedContinuation { continuation in
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            
            guard let request = detectionRequest else {
                continuation.resume(returning: .notFound(reason: "检测请求未初始化"))
                return
            }
            
            do {
                try handler.perform([request])
                
                if let result = processVisionResults(request.results) {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(returning: .notFound(reason: "未检测到文档"))
                }
            } catch {
                continuation.resume(returning: .notFound(reason: error.localizedDescription))
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func setupVisionRequest() {
        let request = VNDetectRectanglesRequest()
        
        // 配置检测参数
        request.minimumAspectRatio = 0.3  // 最小宽高比（防止检测到细长物体）
        request.maximumAspectRatio = 3.0  // 最大宽高比
        request.minimumSize = configuration.minimumArea  // 最小尺寸
        request.minimumConfidence = configuration.minimumConfidence  // 最低置信度
        request.maximumObservations = 1  // 只检测最显著的矩形
        
        self.detectionRequest = request
    }
    
    private func performDetection(on pixelBuffer: CVPixelBuffer) async {
        if detectionRequest == nil {
            setupVisionRequest()
        }
        guard let request = detectionRequest else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
            
            // 直接处理结果
            if let result = processVisionResults(request.results) {
                await sendResult(result)
            } else {
                await sendResult(.notFound(reason: "未检测到文档"))
            }
        } catch {
            await sendResult(.notFound(reason: "Vision 错误: \(error.localizedDescription)"))
        }
    }
    
    private func handleVisionCompletion(_ request: VNRequest, error: Error?) async {
        // 这个方法不再使用，保留用于静态检测
    }
    
    private func processVisionResults(_ results: [Any]?) -> DetectionResult? {
        guard let observations = results as? [VNRectangleObservation],
              let rect = observations.first else {
            return nil
        }
        
        // 转换为归一化坐标（0-1）
        let boundingBox = rect.boundingBox
        
        // 计算置信度
        let confidence = rect.confidence
        
        // 计算面积
        let area = boundingBox.width * boundingBox.height
        
        // 验证是否符合要求
        guard confidence >= configuration.minimumConfidence else {
            return .lowConfidence(confidence)
        }
        
        guard area >= CGFloat(configuration.minimumArea) else {
            return .tooSmall(area: Float(area))
        }
        
        // 提取四个角点
        let corners = [
            rect.topLeft,
            rect.topRight,
            rect.bottomRight,
            rect.bottomLeft
        ]
        
        return .detected(
            boundingBox: boundingBox,
            corners: corners,
            confidence: confidence,
            area: Float(area)
        )
    }
    
    private func sendResult(_ result: DetectionResult) async {
        onDetection?(result)
    }
}

// MARK: - Detection Result

@available(iOS 17.0, macOS 14.0, *)
extension LiveDocumentDetector {
    /// 检测结果
    public enum DetectionResult: Sendable {
        /// 检测到文档（可以拍照）
        case detected(
            boundingBox: CGRect,
            corners: [CGPoint],
            confidence: Float,
            area: Float
        )
        
        /// 未检测到文档
        case notFound(reason: String)
        
        /// 置信度过低
        case lowConfidence(Float)
        
        /// 文档区域太小
        case tooSmall(area: Float)
        
        // MARK: - Helpers
        
        /// 是否可以拍照
        public var canCapture: Bool {
            if case .detected = self {
                return true
            }
            return false
        }
        
        /// UI 提示文字
        public var hint: String {
            switch self {
            case .detected:
                return "检测到文档，点击拍摄"
            case .notFound(let reason):
                return "未检测到文档：\(reason)"
            case .lowConfidence(let value):
                return "请对准文档（置信度 \(Int(value * 100))%）"
            case .tooSmall(let area):
                return "请靠近一些（文档占比 \(Int(area * 100))%）"
            }
        }
        
        /// UI 颜色指示
        public var color: DetectionColor {
            switch self {
            case .detected:
                return .green  // 🟢 可以拍
            case .lowConfidence:
                return .yellow // 🟡 可以改进
            case .notFound, .tooSmall:
                return .red    // 🔴 不能拍
            }
        }
    }
    
    public enum DetectionColor: Sendable {
        case green
        case yellow
        case red
    }
}


