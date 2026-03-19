//
//  OCRServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  OCR 服务协议，定义图片文字识别的公开接口。

import CoreGraphics

/// 光学字符识别服务协议
///
/// ## 行为保证
/// - 对有效 `CGImage` 返回识别出的文本（可能为空字符串，表示无可识别文字）
/// - 识别失败时抛出错误（Vision 框架错误或 `OCRError`）
/// - 线程安全：实现须为 `actor` 或以其他方式保证并发安全（标注 `Sendable`）
///
/// ## 边界条件
/// - 空白图片（纯色无文字）：返回空字符串 `""`，不抛错
/// - 超大图片：由 Vision 框架内部处理，可能耗时较长但不会崩溃
/// - 无效图片数据：抛出 `OCRError.invalidImage`
///
/// ## 不保证
/// - 识别准确率（取决于图片质量和 Vision 模型）
/// - 执行时间上限（依赖图片大小和设备性能）
public protocol OCRServiceProtocol: Sendable {
    /// 从图片中识别文字
    ///
    /// - Parameter cgImage: 待识别的图片
    /// - Returns: 识别出的文本，多行以 `\n` 分隔；无可识别文字时返回空字符串
    /// - Throws: Vision 框架错误或 `OCRError.invalidImage`
    func recognizeText(from cgImage: CGImage) async throws -> String
}
