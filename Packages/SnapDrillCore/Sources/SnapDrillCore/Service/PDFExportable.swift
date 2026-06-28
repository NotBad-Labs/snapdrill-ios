//
//  PDFExportable.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出用内容协议，隔离领域实体依赖。
//

import Foundation

/// PDF 导出内容协议
///
/// 任何可被渲染到 PDF 的数据类型均可遵守此协议，
/// 使 PDFExportService 不依赖具体的领域实体（如 ReviewItem）。
///
/// ## 行为保证
/// - `content` 和 `imagePath` 至少有一个非 nil（否则该条目在 PDF 中无可渲染内容）
/// - `imagePath` 是相对于 App Documents 目录的路径，由 `ImageStorage` 管理
/// - 线程安全：标注 `Sendable`，属性须为不可变或线程安全
///
/// ## 边界条件
/// - `content == nil && imagePath == nil`：`PDFExportService` 跳过该条目，不崩溃
/// - `imagePath` 指向不存在的文件：该条目仅渲染文字部分（如有），图片区域留白
///
/// ## 不保证
/// - 文字内容的格式或长度限制（由渲染层处理截断和分页）
public protocol PDFExportable: Sendable {
    /// 题目文字内容；纯图片题时为 `nil`
    var content: String? { get }
    /// 题目图片的存储路径（相对路径）；纯文字题时为 `nil`
    var imagePath: String? { get }
    /// 答案文本；无答案时为 `nil`
    var answerText: String? { get }
    /// 导出用分类名称；用于 PDF 页眉显示
    var exportCategory: String? { get }
}

extension PDFExportable {
    public var answerText: String? { nil }
    public var exportCategory: String? { nil }
}
