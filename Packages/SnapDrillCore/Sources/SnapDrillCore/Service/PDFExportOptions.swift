//
//  PDFExportOptions.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/03/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出配置项，控制答案显示、答题区留白、页眉页码等渲染行为。
//

import Foundation

/// PDF 导出渲染配置
///
/// 控制 `PDFExportService` 的渲染行为，由导出选项 UI 构造后传入。
/// 默认值面向最常见场景：家长打印 A4 给孩子重做。
nonisolated public struct PDFExportOptions: Sendable {
    /// 是否隐藏答案（默认隐藏——打印给孩子重做时不应显示答案）
    public var hideAnswers: Bool
    /// 是否显示答题留白区（仅在 `hideAnswers == true` 时生效）
    public var showBlankAnswerArea: Bool
    /// 是否显示页眉和页码
    public var showHeader: Bool
    /// 每页题目数量（1 = 大图整页，2 = 默认，4 = 小题紧凑）
    public var itemsPerPage: Int

    public init(
        hideAnswers: Bool = true,
        showBlankAnswerArea: Bool = true,
        showHeader: Bool = true,
        itemsPerPage: Int = 2
    ) {
        self.hideAnswers = hideAnswers
        self.showBlankAnswerArea = showBlankAnswerArea
        self.showHeader = showHeader
        self.itemsPerPage = itemsPerPage
    }

    /// 默认配置：隐藏答案 + 显示答题区 + 显示页眉
    public static let `default` = PDFExportOptions()
}
