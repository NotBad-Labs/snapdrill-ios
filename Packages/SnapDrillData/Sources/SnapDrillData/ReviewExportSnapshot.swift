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
    /// 所属学科
    public let subject: String
    /// 题目来源
    public let source: String
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
    /// 标签列表
    public let tags: [String]
}

extension ReviewExportSnapshot: PDFExportable {
    /// 桥接 `subject: String` → 协议的 `exportSubject: String?`
    public var exportSubject: String? { subject }
}

// 字段与 `ReviewCSVRow` 一一对应，CSV 编码统一走 `ReviewCSVCodec`（单一契约源）。
extension ReviewExportSnapshot: ReviewCSVRow {}
