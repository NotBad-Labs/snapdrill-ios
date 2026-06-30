//
//  SmartPaperViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  智能组卷 ViewModel — 免费随机选题 / Pro 精准选题 + PDF 生成。
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillData

/// 智能组卷 ViewModel
///
/// 免费层随机抽取，Pro 层根据 SM-2 复习状态选出最需要复习的题目，生成 PDF 练习卷。
@Observable
final class SmartPaperViewModel {

    nonisolated static let freeMonthlyQuota = 3

    enum GenerationOutcome: Equatable {
        case preview
        case quotaExceeded
        case unavailable
    }

    // MARK: - 配置状态

    /// 选题数量（默认 10）
    var questionCount: Int = 10

    /// 主分类筛选：选中的主分类维度值 id（空 = 全部）
    var selectedCategoryValueIds: Set<UUID> = []

    // MARK: - PDF 选项

    var hideAnswers = true
    var showBlankAnswerArea = true
    var showHeader = true
    var itemsPerPage = 2

    // MARK: - 输出状态

    /// 选题结果预览
    private(set) var selectedItems: [ArchiveExportSnapshot] = []

    /// 可用主分类维度值列表（供 UI 展示）
    private(set) var availableCategories: [CategoryValueModel] = []

    /// 当前选中主分类值名（摘要标签用）
    var selectedCategoryNames: String {
        availableCategories
            .filter { selectedCategoryValueIds.contains($0.id) }
            .map(\.name)
            .joined(separator: ", ")
    }

    /// 是否正在加载
    private(set) var isLoading = false

    /// 错误信息
    var errorMessage: String?

    /// 当前自然月已使用的免费生成次数
    private(set) var freeQuotaUsed = 0

    // MARK: - 依赖

    @ObservationIgnored
    private let repositories: RepositoryContainer
    /// 软删调度器（注入 App 级共享实例）：用 pendingDeletionIDs 把 5 秒撤销窗口内的软删题排除出选题
    @ObservationIgnored
    private let deletionScheduler: DeletionScheduler
    @ObservationIgnored
    private let defaults: UserDefaults
    @ObservationIgnored
    private var calendar: Calendar
    @ObservationIgnored
    private let now: () -> Date
    @ObservationIgnored
    private let randomizeArchiveItems: ([ArchiveItemModel]) -> [ArchiveItemModel]

    // MARK: - 初始化

    init(
        repositories: RepositoryContainer,
        deletionScheduler: DeletionScheduler = DeletionScheduler(),
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init,
        randomizeArchiveItems: @escaping ([ArchiveItemModel]) -> [ArchiveItemModel] = { $0.shuffled() }
    ) {
        self.repositories = repositories
        self.deletionScheduler = deletionScheduler
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        self.randomizeArchiveItems = randomizeArchiveItems
    }

    // MARK: - Public API

    /// 加载可用主分类列表 + 执行初始选题
    func loadInitialData(isProUser: Bool = false) {
        do {
            if let categoryDimension = try repositories.dimension.fetchDimension(bySystemKey: CategorySystemKey.category) {
                availableCategories = repositories.categoryValue.fetchAllModels(in: categoryDimension)
            }
        } catch {
            SnapDrillLogger.generic.error("加载主分类列表失败: \(error.localizedDescription)")
        }
        refreshFreeQuotaState()
        refreshSelection(isProUser: isProUser)
    }

    /// 根据当前筛选条件重新选题
    func refreshSelection(isProUser: Bool = false) {
        do {
            let models = isProUser ? try fetchPreciseSelection() : try fetchRandomSelection()
            selectedItems = models.map { $0.toExportSnapshot() }
        } catch {
            SnapDrillLogger.generic.error("智能选题失败: \(error.localizedDescription)")
            errorMessage = L10n.Errors.loadFailed
        }
    }

    /// 生成入口：免费层消耗月配额，Pro 层无限但仍保持 StoreKit 门后路径。
    func prepareGeneration(isProUser: Bool) -> GenerationOutcome {
        if !isProUser {
            refreshFreeQuotaState()
            guard freeQuotaUsed < Self.freeMonthlyQuota else { return .quotaExceeded }
        }

        refreshSelection(isProUser: isProUser)
        guard !selectedItems.isEmpty else { return .unavailable }

        if !isProUser {
            freeQuotaUsed += 1
            defaults.set(freeQuotaUsed, forKey: UDKey.smartPaperFreeQuotaUsed)
        }
        return .preview
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

    // MARK: - Selection

    private func fetchPreciseSelection() throws -> [ArchiveItemModel] {
        try repositories.archive.fetchSmartSelection(
            limit: questionCount,
            categoryValueIds: selectedCategoryValueIds,
            excluding: deletionScheduler.pendingDeletionIDs
        )
    }

    private func fetchRandomSelection() throws -> [ArchiveItemModel] {
        let candidates = try repositories.archive.fetchAllModels().filter { item in
            !deletionScheduler.pendingDeletionIDs.contains(item.id)
                && matchesSelectedCategories(item)
        }
        return Array(randomizeArchiveItems(candidates).prefix(questionCount))
    }

    private func matchesSelectedCategories(_ item: ArchiveItemModel) -> Bool {
        guard !selectedCategoryValueIds.isEmpty else { return true }
        let itemValueIds = Set((item.categoryValues ?? []).map(\.id))
        return !itemValueIds.isDisjoint(with: selectedCategoryValueIds)
    }

    // MARK: - Free Quota

    private func refreshFreeQuotaState() {
        let month = currentMonthIdentifier()
        guard defaults.string(forKey: UDKey.smartPaperFreeQuotaMonth) == month else {
            defaults.set(month, forKey: UDKey.smartPaperFreeQuotaMonth)
            defaults.set(0, forKey: UDKey.smartPaperFreeQuotaUsed)
            freeQuotaUsed = 0
            return
        }
        freeQuotaUsed = max(0, defaults.integer(forKey: UDKey.smartPaperFreeQuotaUsed))
    }

    private func currentMonthIdentifier() -> String {
        let components = calendar.dateComponents([.year, .month], from: now())
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }
}
