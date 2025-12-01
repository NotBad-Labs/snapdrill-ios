//
//  ScannerConfiguration.swift
//  NotBad
//
//  扫描器配置模型
//

import VisionKit

// MARK: - ScannerConfiguration

/// 扫描器配置
///
/// 配置实时文字扫描的参数。
///
/// - Note: 由于 `RecognizedDataType` 不是 Sendable，使用 `@unchecked Sendable`
struct ScannerConfiguration: @unchecked Sendable {
    
    /// 识别的数据类型
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>

    /// 识别质量级别
    let qualityLevel: DataScannerViewController.QualityLevel

    /// 是否识别多个项目
    let recognizesMultipleItems: Bool

    /// 是否启用高帧率追踪
    let isHighFrameRateTrackingEnabled: Bool

    /// 是否启用捏合缩放
    let isPinchToZoomEnabled: Bool

    /// 是否启用引导提示
    let isGuidanceEnabled: Bool

    /// 是否启用高亮显示
    let isHighlightingEnabled: Bool

    /// 默认配置
    static let `default` = ScannerConfiguration(
        recognizedDataTypes: [.text()],
        qualityLevel: .balanced,
        recognizesMultipleItems: true,
        isHighFrameRateTrackingEnabled: false,
        isPinchToZoomEnabled: true,
        isGuidanceEnabled: true,
        isHighlightingEnabled: true
    )

    /// 精确配置
    static let accurate = ScannerConfiguration(
        recognizedDataTypes: [.text()],
        qualityLevel: .accurate,
        recognizesMultipleItems: true,
        isHighFrameRateTrackingEnabled: true,
        isPinchToZoomEnabled: true,
        isGuidanceEnabled: true,
        isHighlightingEnabled: true
    )

    /// 快速配置
    static let fast = ScannerConfiguration(
        recognizedDataTypes: [.text()],
        qualityLevel: .fast,
        recognizesMultipleItems: false,
        isHighFrameRateTrackingEnabled: false,
        isPinchToZoomEnabled: true,
        isGuidanceEnabled: false,
        isHighlightingEnabled: true
    )
}

// MARK: - ScannerResult

/// 扫描结果
///
/// 包含识别的文本和截图数据。
struct ScannerResult {
    /// 识别的文本
    let text: String
    
    /// 截图数据（JPEG 格式）
    let imageData: Data?
}
