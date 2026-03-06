//
//  ReviewExportSnapshot.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/03/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  导出专用只读快照，作为 @Model 到 Transferable 的 Sendable 桥接类型。
//

import Foundation
import SnapDrillCore

/// 导出专用只读快照——仅含导出所需字段，满足 Sendable 和 PDFExportable。
public struct ReviewExportSnapshot: Sendable, Identifiable {
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
    /// 创建时间
    public let createdAt: Date
}

extension ReviewExportSnapshot: PDFExportable {}
