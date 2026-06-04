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
    /// 学科维度首值（仅供 PDF 页眉 exportSubject；CSV 走 dimensionValues）
    public let subject: String
    /// 难度等级 (1-5)
    public let difficulty: Int
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
    /// 桥接 `subject: String` → 协议的 `exportSubject: String?`（PDF 页眉用学科维度首值）。
    /// 空串归一为 nil：无学科值的题目须被 PDFExportService.resolveSubject 的 compactMap 丢弃，
    /// 否则空串污染 subjects 集合 → 误判「综合练习」或页眉学科留白（恢复 S5 前契约）。
    public var exportSubject: String? { subject.isEmpty ? nil : subject }
}

// CSV 编码统一走 `ReviewCSVCodec`（单一契约源）；A2 动态列经 dimensionValues。
extension ReviewExportSnapshot: ReviewCSVRow {}
