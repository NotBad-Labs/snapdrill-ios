//
//  SmartPaperViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/04/08.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  智能组卷 ViewModel — 基于 SM-2 紧迫度选题 + PDF 生成。
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillData

/// 智能组卷 ViewModel
///
/// 根据 SM-2 复习状态选出最需要复习的题目，生成 PDF 练习卷。
/// 选题排序：nextReviewAt ASC（越早到期越优先）→ repetitions ASC（越不熟练越优先）。
@Observable
final class SmartPaperViewModel {

    // MARK: - 配置状态

    /// 选题数量（默认 10）
    var questionCount: Int = 10

    /// 学科筛选（空 = 全部）
    var selectedSubjects: Set<String> = []

    /// 难度筛选（空 = 全部）
    var selectedDifficulties: Set<Int> = []

    // MARK: - PDF 选项

    var hideAnswers = true
    var showBlankAnswerArea = true
    var showHeader = true
    var itemsPerPage = 2

    // MARK: - 输出状态

    /// 选题结果预览
    private(set) var selectedItems: [ReviewExportSnapshot] = []

    /// 可用学科列表（供 UI 展示）
    private(set) var availableSubjects: [String] = []

    /// 是否正在加载
    private(set) var isLoading = false

    /// 错误信息
    var errorMessage: String?

    // MARK: - 依赖

    private let repositories: RepositoryContainer

    // MARK: - 初始化

    init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public API

    /// 加载可用学科列表 + 执行初始选题
    func loadInitialData() {
        do {
            let subjects = try repositories.subject.fetchAllModels()
            availableSubjects = subjects.sorted(by: { $0.sortOrder < $1.sortOrder }).map(\.name)
        } catch {
            SnapDrillLogger.generic.error("加载学科列表失败: \(error.localizedDescription)")
        }
        refreshSelection()
    }

    /// 根据当前筛选条件重新选题
    func refreshSelection() {
        do {
            let models = try repositories.review.fetchSmartSelection(
                limit: questionCount,
                subjects: selectedSubjects,
                difficulties: selectedDifficulties
            )
            selectedItems = models.map { $0.toExportSnapshot() }
        } catch {
            SnapDrillLogger.generic.error("智能选题失败: \(error.localizedDescription)")
            errorMessage = L10n.Errors.loadFailed
        }
    }

    /// 构建 PDF 导出选项
    var pdfOptions: PDFExportOptions {
        PDFExportOptions(
            hideAnswers: hideAnswers,
            showBlankAnswerArea: showBlankAnswerArea,
            showHeader: showHeader,
            itemsPerPage: itemsPerPage,
            customTitle: L10n.SmartPaper.pdfTitle
        )
    }
}
