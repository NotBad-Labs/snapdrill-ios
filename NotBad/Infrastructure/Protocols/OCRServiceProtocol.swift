//
//  OCRServiceProtocol.swift
//  NotBad
//
//  OCR 文字识别服务协议定义
//

import UIKit

// MARK: - OCRServiceProtocol

/// OCR 文字识别服务协议
///
/// 定义文字识别服务的抽象接口，支持依赖注入和测试。
///
/// ## 设计目的
///
/// 1. **解耦**：View 层依赖协议而非具体实现
/// 2. **可测试**：可以注入 Mock 实现进行单元测试
/// 3. **可替换**：未来可以替换为其他 OCR 引擎
///
/// ## 使用示例
///
/// ```swift
/// let service = OCRService.shared
/// let result = try await service.recognizeText(from: image)
/// ```
///
/// - Note: 所有方法都是异步的，可能需要数秒时间
@MainActor
protocol OCRServiceProtocol: AnyObject, Sendable {

    /// 从图片中识别文字
    ///
    /// - Parameter image: 要识别的图片
    /// - Returns: 识别出的文本字符串
    /// - Throws: 识别失败时抛出错误
    func recognizeText(from image: UIImage) async throws -> String

    /// 从图片中识别文字（带置信度）
    ///
    /// - Parameter image: 要识别的图片
    /// - Returns: 识别结果，包含文本、置信度和边界框信息
    /// - Throws: 识别失败时抛出错误
    func recognizeTextWithConfidence(from image: UIImage) async throws -> OCRResult
}

// MARK: - Default Implementation

extension OCRServiceProtocol {
    /// 默认实现：从带置信度的结果中提取纯文本
    func recognizeText(from image: UIImage) async throws -> String {
        let result = try await recognizeTextWithConfidence(from: image)
        return result.text
    }
}
