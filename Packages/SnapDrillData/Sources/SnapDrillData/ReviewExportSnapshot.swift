//
//  ReviewExportSnapshot.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  导出专用只读快照，作为 @Model 到 Transferable 的 Sendable 桥接类型。
//

import Foundation
import SnapDrillCore

/// 导出专用只读快照——满足 Sendable 和 PDFExportable，供 PDF 和 CSV 导出共用。
nonisolated public struct ReviewExportSnapshot: Sendable, Identifiable {
    /// 题目唯一标识符
    public let id: UUID
    /// 题目内容文本
    public let content: String?
    /// 图片相对路径
    public let imagePath: String?
    /// 主分类维度首值（仅供 PDF 页眉 exportCategory；CSV 走 dimensionValues）
    public let category: String
    /// 答案文本
    public let answerText: String?
    /// 创建时间
    public let createdAt: Date
    /// 上次复习时间
    public let lastReviewedAt: Date?
    /// 下次计划复习时间
    public let nextReviewAt: Date?
    /// 动态维度值：维度名 → 值名（A2 动态列导出用）
    public let dimensionValues: [String: [String]]
}

extension ReviewExportSnapshot: PDFExportable {
    /// 桥接内部分类字段 → 协议的 `exportCategory: String?`（PDF 页眉用分类维度首值）。
    /// 空串归一为 nil：无分类值的条目须被 PDFExportService.resolveCategory 的 compactMap 丢弃，
    /// 否则空串污染 categories 集合 → 误判「综合资料」或页眉留白（恢复 S5 前契约）。
    public var exportCategory: String? { category.isEmpty ? nil : category }
}

// CSV 编码统一走 `ReviewCSVCodec`（单一契约源）；A2 动态列经 dimensionValues。
extension ReviewExportSnapshot: ReviewCSVRow {}
