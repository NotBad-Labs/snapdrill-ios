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
    public let id: UUID
    public let content: String?
    public let imagePath: String?
    public let subject: String
    public let source: String
    public let createdAt: Date
}

extension ReviewExportSnapshot: PDFExportable {}
