//
//  PDFExportable.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出用内容协议，隔离领域实体依赖。
//

import Foundation

/// PDF 导出内容协议
///
/// 任何可被渲染到 PDF 的数据类型均可遵守此协议，
/// 使 PDFExportService 不依赖具体的领域实体（如 ReviewItem）。
public protocol PDFExportable: Sendable {
    var content: String { get }
    var imagePath: String? { get }
}
