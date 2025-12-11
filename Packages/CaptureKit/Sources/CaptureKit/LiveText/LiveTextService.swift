// CaptureKit - Live Text 服务
//
// 基于 VisionKit ImageAnalyzer 的 Live Text 支持。
// 在图片上启用可交互的文字识别（长按选择、复制、翻译等）。
//
// iOS 16+

import Foundation
import VisionKit

#if canImport(UIKit)
import UIKit
#endif

// MARK: - LiveTextService

/// Live Text 服务
///
/// 提供图片上的交互式文字识别，用户可以长按选择、复制、翻译文字。
/// 与 OCRService 的区别：
/// - OCRService：后台静态识别，返回纯文本
/// - LiveTextService：UI 交互式，用户可选择文字
///
/// ## 使用示例
///
/// ```swift
/// // 分析图片
/// let analysis = try await LiveTextService.shared.analyze(image: photo)
///
/// // 在 SwiftUI 中使用
/// LiveTextImageView(image: photo)
/// ```
@available(iOS 16.0, macOS 13.0, *)
public final class LiveTextService: @unchecked Sendable {
    
    // MARK: - Singleton
    
    /// 共享实例
    public static let shared = LiveTextService()
    
    // MARK: - Properties
    
    private let analyzer: ImageAnalyzer
    private let lock = NSLock()
    
    // MARK: - Availability
    
    /// 是否支持 Live Text
    public static var isSupported: Bool {
        ImageAnalyzer.isSupported
    }
    
    /// 支持的语言列表
    public static var supportedLanguages: [String] {
        ImageAnalyzer.supportedTextRecognitionLanguages
    }
    
    // MARK: - Initialization
    
    public init() {
        self.analyzer = ImageAnalyzer()
    }
    
    // MARK: - Analysis
    
    #if canImport(UIKit)
    /// 分析图片中的文字和二维码
    ///
    /// - Parameters:
    ///   - image: 待分析的图片
    ///   - types: 分析类型（默认：文字 + 二维码）
    /// - Returns: 分析结果，用于 ImageAnalysisInteraction
    public func analyze(
        image: UIImage,
        types: ImageAnalyzer.AnalysisTypes = [.text, .machineReadableCode]
    ) async throws -> ImageAnalysis {
        let configuration = ImageAnalyzer.Configuration(types)
        return try await analyzer.analyze(image, configuration: configuration)
    }
    
    /// 从图片中提取所有文字
    ///
    /// - Parameter image: 待分析的图片
    /// - Returns: 识别到的所有文字
    public func extractText(from image: UIImage) async throws -> String {
        let analysis = try await analyze(image: image, types: [.text])
        return analysis.transcript
    }
    
    /// 检查图片是否包含文字
    ///
    /// - Parameter image: 待检查的图片
    /// - Returns: 是否包含可识别的文字
    public func hasText(in image: UIImage) async -> Bool {
        do {
            let analysis = try await analyze(image: image, types: [.text])
            return analysis.hasResults(for: .text)
        } catch {
            return false
        }
    }
    #endif
}

// MARK: - ImageAnalysisInteraction Wrapper

#if canImport(UIKit)
import SwiftUI

@available(iOS 16.0, *)
/// Live Text 图片视图
///
/// 在图片上启用 Live Text 交互，用户可以：
/// - 长按选择文字
/// - 复制文字
/// - 翻译文字
/// - 查找相关内容
///
/// ## 使用示例
///
/// ```swift
/// struct ImageDetailView: View {
///     let image: UIImage
///     
///     var body: some View {
///         LiveTextImageView(image: image)
///     }
/// }
/// ```
public struct LiveTextImageView: UIViewRepresentable {
    
    /// 显示的图片
    public let image: UIImage
    
    /// 允许的交互类型
    public var interactionTypes: ImageAnalysisInteraction.InteractionTypes
    
    /// 分析完成回调
    public var onAnalysisComplete: ((ImageAnalysis?) -> Void)?
    
    public init(
        image: UIImage,
        interactionTypes: ImageAnalysisInteraction.InteractionTypes = [.automatic],
        onAnalysisComplete: ((ImageAnalysis?) -> Void)? = nil
    ) {
        self.image = image
        self.interactionTypes = interactionTypes
        self.onAnalysisComplete = onAnalysisComplete
    }
    
    /// 构建带 Live Text 交互的 UIImageView
    public func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        
        // 添加 Live Text 交互
        let interaction = ImageAnalysisInteraction()
        interaction.preferredInteractionTypes = interactionTypes
        imageView.addInteraction(interaction)
        
        // 异步分析图片
        Task {
            do {
                let analysis = try await LiveTextService.shared.analyze(image: image)
                await MainActor.run {
                    interaction.analysis = analysis
                    onAnalysisComplete?(analysis)
                }
            } catch {
                await MainActor.run {
                    onAnalysisComplete?(nil)
                }
            }
        }
        
        return imageView
    }
    
    /// 更新展示的图片内容
    public func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
    }
}

// MARK: - Convenience Extensions

@available(iOS 16.0, *)
/// LiveTextImageView 的便捷构造方法
public extension LiveTextImageView {
    /// 只允许文字选择
    func textSelectionOnly() -> LiveTextImageView {
        LiveTextImageView(
            image: image,
            interactionTypes: .textSelection,
            onAnalysisComplete: onAnalysisComplete
        )
    }
    
    /// 允许所有交互（文字选择 + 数据检测）
    func allInteractions() -> LiveTextImageView {
        LiveTextImageView(
            image: image,
            interactionTypes: [.textSelection, .dataDetectors],
            onAnalysisComplete: onAnalysisComplete
        )
    }
}
#endif
