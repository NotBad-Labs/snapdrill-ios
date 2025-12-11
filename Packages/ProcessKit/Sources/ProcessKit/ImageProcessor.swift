import Foundation
import CoreML
import CoreImage
import CoreGraphics
import OSLog

#if canImport(AppKit)
import AppKit
#endif

private extension Logger {
    static let processKit = Logger(subsystem: "com.notbad.processkit", category: "ImageProcessor")
}

/// 图像处理主引擎
///
/// 提供两种手写擦除方案：
/// 1. 颜色过滤（快速，适合蓝/红/铅笔）
/// 2. Core ML 语义分割（精确，适合黑笔）
@available(iOS 17.0, macOS 14.0, *)
public actor ImageProcessor {
    
    // MARK: - Configuration
    
    /// 配置选项
    public struct Configuration: Sendable {
        /// Core ML 模型名称
        public let modelName: String
        
        /// 最大处理尺寸（超过则缩放）
        public let maxProcessingSize: CGSize
        
        /// 是否启用 Neural Engine
        public let useNeuralEngine: Bool
        
        public init(
            modelName: String = "HandwritingSegmentation",
            maxProcessingSize: CGSize = CGSize(width: 2048, height: 2048),
            useNeuralEngine: Bool = true
        ) {
            self.modelName = modelName
            self.maxProcessingSize = maxProcessingSize
            self.useNeuralEngine = useNeuralEngine
        }
    }
    
    // MARK: - Properties
    
    private let configuration: Configuration
    private let colorEraser: ColorBasedEraser
    private var mlModel: MLModel?  // Core ML 模型（懒加载）
    
    // MARK: - Initialization
    
    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
        self.colorEraser = ColorBasedEraser()
    }
    
    // MARK: - Public API
    
    /// 方法 1：颜色过滤擦除（快速）
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - colors: 要擦除的颜色列表
    /// - Returns: 处理后的图片
    public func removeColoredInk(
        from image: PlatformImage,
        colors: [ColorBasedEraser.InkColor]
    ) -> PlatformImage? {
        let startTime = Date()
        
        let result = colorEraser.removeInk(from: image, colors: colors)
        
        let duration = Date().timeIntervalSince(startTime)
        Logger.processKit.info("颜色擦除完成，耗时: \(duration, format: .fixed(precision: 3))s")
        
        return result
    }
    
    /// 方法 2：Core ML 语义分割擦除（精确）
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - saveIntermediateResults: 是否保存分割 mask（用于调试）
    /// - Returns: 处理结果
    /// - Throws: 模型加载或推理错误
    public func removeHandwriting(
        from image: PlatformImage,
        saveIntermediateResults: Bool = false
    ) async throws -> ProcessResult {
        let startTime = Date()
        
        // 1. 加载 Core ML 模型（懒加载）
        if mlModel == nil {
            try await loadModel()
        }
        
        // 2. 预处理图片（调整尺寸）
        guard let resized = resizeIfNeeded(image) else {
            throw ProcessError.imageProcessingFailed
        }
        
        // 3. Core ML 推理
        // TODO: 实现模型推理逻辑
        // let segmentation = try await performSegmentation(resized)
        
        // 4. 后处理（合成最终图片）
        // TODO: 根据 mask 擦除手写区域
        
        let duration = Date().timeIntervalSince(startTime)
        Logger.processKit.info("Core ML 擦除完成，耗时: \(duration, format: .fixed(precision: 3))s")
        
        // 临时返回（待实现）
        let imageData = image.pngData ?? Data()
        return ProcessResult(
            image: imageData,
            duration: duration,
            segmentationMask: saveIntermediateResults ? imageData : nil
        )
    }
    
    // MARK: - Image Enhancement
    
    /// 对比度增强
    public func enhanceContrast(_ image: PlatformImage, intensity: Double = 1.5) -> PlatformImage? {
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else { return nil }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        #endif
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(intensity, forKey: kCIInputContrastKey)
        
        guard let output = filter?.outputImage else { return nil }
        return renderImage(output)
    }
    
    /// 锐化
    public func sharpen(_ image: PlatformImage, intensity: Double = 0.4) -> PlatformImage? {
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else { return nil }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        #endif
        
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(intensity, forKey: kCIInputSharpnessKey)
        
        guard let output = filter?.outputImage else { return nil }
        return renderImage(output)
    }
    
    // MARK: - Private Helpers
    
    private func loadModel() async throws {
        Logger.processKit.info("加载 Core ML 模型: \(self.configuration.modelName)")
        
        // TODO: 实现模型加载
        // let config = MLModelConfiguration()
        // config.computeUnits = configuration.useNeuralEngine ? .all : .cpuAndGPU
        // self.mlModel = try await MLModel.load(contentsOf: modelURL, configuration: config)
        
        throw ProcessError.modelNotFound(configuration.modelName)
    }
    
    private func resizeIfNeeded(_ image: PlatformImage) -> PlatformImage? {
        let maxSize = configuration.maxProcessingSize
        let size = image.size
        
        // 无需缩放
        if size.width <= maxSize.width && size.height <= maxSize.height {
            return image
        }
        
        // 计算缩放比例
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        Logger.processKit.debug("缩放图片: \(size.width)x\(size.height) → \(newSize.width)x\(newSize.height)")
        
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        #elseif canImport(AppKit)
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        defer { resizedImage.unlockFocus() }
        image.draw(in: NSRect(origin: .zero, size: newSize))
        return resizedImage
        #endif
    }
    
    private func renderImage(_ ciImage: CIImage) -> PlatformImage? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
        #endif
    }
}

// MARK: - Error Types

public enum ProcessError: Error, LocalizedError {
    case modelNotFound(String)
    case imageProcessingFailed
    case invalidImageFormat
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "找不到 Core ML 模型: \(name).mlmodel"
        case .imageProcessingFailed:
            return "图像处理失败"
        case .invalidImageFormat:
            return "无效的图片格式"
        }
    }
}
