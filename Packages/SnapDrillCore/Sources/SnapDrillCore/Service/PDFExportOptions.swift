//
//  PDFExportOptions.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出配置项，控制答案显示、答题区留白、页眉页码等渲染行为。
//

import Foundation

/// PDF 导出渲染配置
///
/// 控制 `PDFExportService` 的渲染行为，由导出选项 UI 构造后传入。
/// 默认值面向常见复盘场景：导出 A4 资料集供稍后查看或打印。
nonisolated public struct PDFExportOptions: Sendable {
    /// 是否隐藏参考内容（默认隐藏，便于稍后自查或打印）
    public var hideAnswers: Bool
    /// 是否显示答题留白区（仅在 `hideAnswers == true` 时生效）
    public var showBlankAnswerArea: Bool
    /// 是否显示页眉和页码
    public var showHeader: Bool
    /// 每页题目数量（1 = 大图整页，2 = 默认，4 = 小题紧凑）
    public var itemsPerPage: Int {
        get { validatedItemsPerPage }
        set { validatedItemsPerPage = Self.validatedItemsPerPage(newValue) }
    }
    /// 自定义封面标题（nil 时使用默认资料集标题）
    public var customTitle: String?
    /// 每页题目数的有效范围，防止 0 导致分页除零或过大导致布局失控
    public static let itemsPerPageRange = 1...100

    private var validatedItemsPerPage: Int

    public init(
        hideAnswers: Bool = true,
        showBlankAnswerArea: Bool = true,
        showHeader: Bool = true,
        itemsPerPage: Int = 2,
        customTitle: String? = nil
    ) {
        self.hideAnswers = hideAnswers
        self.showBlankAnswerArea = showBlankAnswerArea
        self.showHeader = showHeader
        self.customTitle = customTitle
        self.validatedItemsPerPage = Self.validatedItemsPerPage(itemsPerPage)
    }

    /// 默认配置：隐藏答案 + 显示答题区 + 显示页眉
    public static let `default` = PDFExportOptions()

    private static func validatedItemsPerPage(_ value: Int) -> Int {
        min(max(value, itemsPerPageRange.lowerBound), itemsPerPageRange.upperBound)
    }
}
