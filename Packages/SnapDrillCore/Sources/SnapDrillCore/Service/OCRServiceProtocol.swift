//
//  OCRServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
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

    /// 从整页文档图片中识别结构化内容
    ///
    /// 使用 `RecognizeDocumentsRequest`（iOS 26+）识别文档结构：段落、表格、列表、二维码等。
    /// 适合整页扫描件或 PDF 页面，**不适合裁剪后的单题图片**（单题图片请用 `recognizeText`）。
    ///
    /// - Parameter cgImage: 整页文档图片
    /// - Returns: 结构化识别结果，包含全文文本、段落列表和表格数据
    /// - Throws: Vision 框架错误或 `OCRError.invalidImage`
    func recognizeDocument(from cgImage: CGImage) async throws -> DocumentRecognitionResult
}

// MARK: - 文档结构化识别结果

/// 文档结构化识别结果
///
/// 解耦 Vision 框架原生类型，便于测试 Mock 和后续演进。
/// nonisolated：纯值类型，需要跨 actor 传递（OCRService 是独立 actor）。
nonisolated public struct DocumentRecognitionResult: Sendable, Equatable {
    /// 文档全文（所有文本拼接，换行符分隔）
    public let transcript: String

    /// 段落列表（按文档结构分组的文本块）
    public let paragraphs: [String]

    /// 表格数据（二维字符串数组，每个表格 = rows × cells）
    public let tables: [[TableRow]]

    public init(transcript: String, paragraphs: [String], tables: [[TableRow]]) {
        self.transcript = transcript
        self.paragraphs = paragraphs
        self.tables = tables
    }

    /// 空结果（无可识别内容）
    public static let empty = DocumentRecognitionResult(transcript: "", paragraphs: [], tables: [])
}

/// 表格行（一行中每个单元格的文本）
public typealias TableRow = [String]
