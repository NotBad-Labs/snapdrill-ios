// CaptureKit - 相机扫描服务
//
// 基于 VisionKit DataScannerViewController 的实时扫描支持。
// 在相机取景器中实时高亮显示可识别的文字和二维码。
//
// iOS 16+ only (DataScannerViewController 仅 iOS 可用)

import Foundation

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
import UIKit
import SwiftUI
import VisionKit

// MARK: - ScannerService

/// 相机扫描服务
///
/// 提供相机实时文字扫描功能，支持：
/// - 实时高亮显示识别到的文字
/// - 点击选择文字
/// - 自动拍照保存
///
/// ## 使用示例
///
/// ```swift
/// // 检查可用性
/// if ScannerService.isAvailable {
///     // 显示扫描器
///     TextScannerView { result in
///         print("识别到: \(result.text)")
///     }
/// }
/// ```
@available(iOS 16.0, *)
@MainActor
public final class ScannerService {
    
    // MARK: - Singleton
    
    /// 共享实例
    public static let shared = ScannerService()
    
    // MARK: - Availability
    
    /// 设备是否支持扫描（需要 Neural Engine）
    public static var isSupported: Bool {
        DataScannerViewController.isSupported
    }
    
    /// 扫描是否可用（已授权相机权限）
    public static var isAvailable: Bool {
        DataScannerViewController.isAvailable
    }
    
    /// 支持的文字识别语言
    public static var supportedLanguages: [String] {
        DataScannerViewController.supportedTextRecognitionLanguages
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Scanner Configuration
    
    /// 创建文字扫描器
    ///
    /// - Parameters:
    ///   - recognizesMultipleItems: 是否同时识别多个项目
    ///   - qualityLevel: 识别质量（accurate 更准确，balanced 更快）
    /// - Returns: 配置好的扫描器
    public func createTextScanner(
        recognizesMultipleItems: Bool = true,
        qualityLevel: DataScannerViewController.QualityLevel = .accurate
    ) -> DataScannerViewController {
        DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: qualityLevel,
            recognizesMultipleItems: recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
    }
    
    /// 创建文字 + 二维码扫描器
    public func createFullScanner(
        recognizesMultipleItems: Bool = true,
        qualityLevel: DataScannerViewController.QualityLevel = .accurate
    ) -> DataScannerViewController {
        DataScannerViewController(
            recognizedDataTypes: [.text(), .barcode()],
            qualityLevel: qualityLevel,
            recognizesMultipleItems: recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
    }
}

// MARK: - Recognized Item

/// 识别到的文字项（保留位置信息）
///
/// ⚠️ 坐标系说明：
/// - DataScanner 返回的是**屏幕像素坐标**（原点左上，Y 轴向下）
/// - 与拍摄的照片尺寸对应
/// - 不是归一化坐标（不在 0-1 范围内）
public struct RecognizedTextItem: Sendable {
    /// 识别到的文字
    public let transcript: String
    
    /// 文字在图片中的边界框（屏幕像素坐标）
    ///
    /// 坐标系：原点左上，Y 轴向下，单位为像素
    public let boundingBox: CGRect
    
    public init(transcript: String, boundingBox: CGRect) {
        self.transcript = transcript
        self.boundingBox = boundingBox
    }
}

// MARK: - Bounds Extension

@available(iOS 16.0, *)
extension RecognizedItem.Bounds {
    /// 将四角坐标转换为 CGRect 边界框
    ///
    /// DataScanner 的 Bounds 包含四个角点，这里转换为最小包围矩形。
    /// 返回的坐标是屏幕像素坐标（原点左上）。
    var cgRect: CGRect {
        let minX = min(topLeft.x, bottomLeft.x)
        let maxX = max(topRight.x, bottomRight.x)
        let minY = min(topLeft.y, topRight.y)
        let maxY = max(bottomLeft.y, bottomRight.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - Scan Result

/// 扫描结果
public struct ScanResult: Sendable {
    /// 识别到的完整文字
    public let text: String
    
    /// 识别到的文字项列表（包含位置信息）
    ///
    /// 可用于未来实现"点击高亮对应文字"功能
    public let items: [RecognizedTextItem]
    
    /// 拍摄的照片（可选）
    public let photo: UIImage?
    
    /// 扫描时间
    public let timestamp: Date
    
    public init(
        text: String,
        items: [RecognizedTextItem] = [],
        photo: UIImage? = nil,
        timestamp: Date = Date()
    ) {
        self.text = text
        self.items = items
        self.photo = photo
        self.timestamp = timestamp
    }
    
    /// 是否有位置信息
    public var hasPositionInfo: Bool {
        !items.isEmpty
    }
}

// MARK: - SwiftUI Scanner View

/// 文字扫描视图
///
/// SwiftUI 封装的相机扫描器，用于实时识别文字。
///
/// ## 使用示例
///
/// ```swift
/// struct CaptureView: View {
///     @State private var showScanner = false
///     @State private var scannedText = ""
///     
///     var body: some View {
///         Button("扫描题目") {
///             showScanner = true
///         }
///         .sheet(isPresented: $showScanner) {
///             TextScannerView { result in
///                 scannedText = result.text
///                 showScanner = false
///             }
///         }
///     }
/// }
/// ```
@available(iOS 16.0, *)
/// 文字扫描视图
///
/// SwiftUI 封装的相机扫描器，用于实时识别文字。
public struct TextScannerView: UIViewControllerRepresentable {
    
    /// 扫描完成回调
    public var onScan: (ScanResult) -> Void
    
    /// 取消回调
    public var onCancel: (() -> Void)?
    
    /// 是否自动拍照
    public var capturePhoto: Bool
    
    /// 识别质量
    public var qualityLevel: DataScannerViewController.QualityLevel
    
    public init(
        capturePhoto: Bool = true,
        qualityLevel: DataScannerViewController.QualityLevel = .accurate,
        onCancel: (() -> Void)? = nil,
        onScan: @escaping (ScanResult) -> Void
    ) {
        self.capturePhoto = capturePhoto
        self.qualityLevel = qualityLevel
        self.onCancel = onCancel
        self.onScan = onScan
    }
    
    /// 创建并配置扫描器视图控制器
    public func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = ScannerService.shared.createTextScanner(qualityLevel: qualityLevel)
        scanner.delegate = context.coordinator
        return scanner
    }
    
    /// 扫描器无需增量更新，保持空实现
    public func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    
    /// 创建协调器以桥接 DataScanner 回调
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    /// 扫描器协调器，处理 DataScanner 的委托回调
    public class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: TextScannerView
        
        /// 累积所有识别到的文字项（保留位置信息）
        private var recognizedTextItems: [RecognizedTextItem] = []
        
        init(_ parent: TextScannerView) {
            self.parent = parent
        }
        
        /// 处理缩放事件（当前仅占位）
        public func dataScannerDidZoom(_ dataScanner: DataScannerViewController) {}
        
        /// 点击识别项时回调，生成业务 ScanResult
        public func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            Task { @MainActor in
                await handleTap(on: item, scanner: dataScanner)
            }
        }
        
        @MainActor
        /// 将点击事件转换为 ScanResult 并回调业务层
        private func handleTap(on item: RecognizedItem, scanner: DataScannerViewController) async {
            guard case .text(let tappedText) = item else { return }
            
            var photo: UIImage? = nil
            
            if parent.capturePhoto {
                photo = try? await scanner.capturePhoto()
            }
            
            // 使用累积的所有识别项目（保留位置信息）
            let allItems = recognizedTextItems.isEmpty 
                ? [RecognizedTextItem(transcript: tappedText.transcript, boundingBox: tappedText.bounds.cgRect)]
                : recognizedTextItems
            
            // 合并所有文字
            let fullText = allItems.map { $0.transcript }.joined(separator: "\n")
            
            let result = ScanResult(
                text: fullText,
                items: allItems,
                photo: photo
            )
            
            scanner.stopScanning()
            parent.onScan(result)
        }
        
        /// 实时同步识别到的所有文字项，保留位置信息
        public func dataScannerViewController(
            _ controller: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            // 更新累积的文字项目列表
            recognizedTextItems = allItems.compactMap { item -> RecognizedTextItem? in
                guard case .text(let textItem) = item else { return nil }
                return RecognizedTextItem(
                    transcript: textItem.transcript,
                    boundingBox: textItem.bounds.cgRect
                )
            }
        }
    }
}

// MARK: - Scanner Availability View

/// 扫描器可用性检查视图
///
/// 自动检查设备是否支持扫描，显示相应的 UI。
@available(iOS 16.0, *)
/// 扫描器可用性检查视图
public struct ScannerAvailabilityView<Content: View, Fallback: View>: View {
    
    let content: () -> Content
    let fallback: () -> Fallback
    
    public init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder fallback: @escaping () -> Fallback
    ) {
        self.content = content
        self.fallback = fallback
    }
    
    /// 根据设备能力选择展示真实扫描 UI 或降级界面
    public var body: some View {
        if ScannerService.isSupported && ScannerService.isAvailable {
            content()
        } else {
            fallback()
        }
    }
}

#endif // canImport(UIKit)
