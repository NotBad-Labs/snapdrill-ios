//
//  LibraryViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题库列表的状态管理与过滤逻辑，支持搜索、分页与多维度筛选。
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillData

/// 题库列表排序选项
public enum LibrarySortOption: String, CaseIterable, Identifiable {
    /// 按创建时间倒序（最新在前）
    case createdAt
    /// 按学科升序（A→Z）
    case subject
    /// 按难度倒序（最难在前）
    case difficulty
    /// 按复习状态升序（最紧急在前）
    case reviewStatus

    public var id: String { rawValue }

    var displayName: String {
        switch self {
        case .createdAt: L10n.Library.sortTime
        case .subject: L10n.Library.sortSubject
        case .difficulty: L10n.Library.sortDifficulty
        case .reviewStatus: L10n.Library.sortReviewStatus
        }
    }

    var sortDescriptors: [SortDescriptor<ReviewItemModel>] {
        switch self {
        case .createdAt:
            [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)]
        case .subject:
            [SortDescriptor(\ReviewItemModel.subjectRawValue, order: .forward),
             SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)]
        case .difficulty:
            [SortDescriptor(\ReviewItemModel.difficulty, order: .reverse),
             SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)]
        case .reviewStatus:
            [SortDescriptor(\ReviewItemModel.nextReviewAt, order: .forward),
             SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)]
        }
    }
}

/// 题库列表 ViewModel
///
/// 管理多维度过滤（搜索文本、学科、标签）、分页加载和数据刷新逻辑。
/// 由于 SwiftData many-to-many Predicate 限制，过滤在内存端完成。
@MainActor @Observable
public final class LibraryViewModel {

    // MARK: - Dependencies

    private let repositories: RepositoryContainer

    // MARK: - State

    /// 当前过滤条件下的题目列表（支持分页追加）
    public var filteredItems: [ReviewItemModel] = []
    /// 所有学科列表，用于过滤选项
    public var subjects: [SubjectModel] = []
    /// 所有标签列表，用于过滤选项
    public var allTags: [TagModel] = []

    /// 搜索文本（变更时触发防抖刷新）
    public var searchText: String = "" {
        didSet { triggerRefresh() }
    }
    /// 已选中的学科过滤集合（变更时触发防抖刷新）
    public var selectedSubjects: Set<String> = [] {
        didSet { triggerRefresh() }
    }
    /// 已选中的标签过滤集合（变更时触发防抖刷新）
    public var selectedTags: Set<String> = [] {
        didSet { triggerRefresh() }
    }
    /// 已选中的难度过滤集合（变更时触发防抖刷新）
    public var selectedDifficulties: Set<Int> = [] {
        didSet { triggerRefresh() }
    }
    /// 当前排序方式（变更时触发刷新）
    public var sortOption: LibrarySortOption = .createdAt {
        didSet { triggerRefresh() }
    }

    /// 是否正在加载数据
    public var isLoading: Bool = false
    /// 当前筛选条件是否还有下一页数据
    public var hasMore: Bool = true
    /// 数据加载错误信息（非 nil 时 View 应展示错误状态）
    public var errorMessage: String?
    /// 操作错误信息（非 nil 时 View 展示 alert，用于删除、打标签等操作）
    public var operationError: String?
    /// 撤销 Toast 状态（委托给 DeletionScheduler）
    public var showUndoToast: Bool {
        get { deletionScheduler.showUndoToast }
        set { deletionScheduler.showUndoToast = newValue }
    }
    /// 待删除的题目数量（Toast 显示用）
    public var pendingDeletionCount: Int {
        deletionScheduler.pendingDeletionCount
    }
    /// App 级删除调度器
    @ObservationIgnored
    private let deletionScheduler = DeletionScheduler.shared
    /// 撤销恢复时按批次暂存 items，避免连续删除时后批次覆盖前批次缓冲区
    @ObservationIgnored
    private var pendingDeletionItemBatches: [(ids: Set<UUID>, items: [ReviewItemModel])] = []
    private var currentPage: Int = 0
    private let pageSize: Int = 50
    private let metadataFetchLimit: Int = 500
    /// 搜索防抖任务句柄（@MainActor 隔离，由 View 的 onDisappear 通过 cancelTasks() 取消）
    /// @ObservationIgnored：Task 不是 UI 状态，不应触发 Observation 追踪
    @ObservationIgnored
    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    /// 创建题库列表 ViewModel
    /// - Parameter repositories: 应用的数据仓库容器
    public init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public API

    /// 加载基础元数据与初始数据
    public func loadDataAsync() async {
        isLoading = true
        defer { isLoading = false }

        do {
            self.subjects = try repositories.subject.fetchAllModels(limit: metadataFetchLimit)
            self.allTags = try repositories.tag.fetchAllModels(limit: metadataFetchLimit)
            self.errorMessage = nil
            await refreshData()
        } catch {
            SnapDrillLogger.generic.error("加载题库元数据失败: \(error.localizedDescription)")
            self.errorMessage = L10n.Errors.loadFailed
        }
    }

    /// 触发防抖搜索/刷新
    public func triggerRefresh() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300)) // best-effort: 0.3s 防抖延迟，取消不影响正确性
            guard let self = self, !Task.isCancelled else { return }
            await self.refreshData()
        }
    }

    /// 执行数据加载与过滤 (异步)
    public func refreshData() async {
        do {
            currentPage = 0
            let results = try repositories.review.fetchFilteredModels(
                searchText: searchText,
                subjects: selectedSubjects,
                tags: selectedTags,
                difficulties: selectedDifficulties,
                sortDescriptors: sortOption.sortDescriptors,
                limit: pageSize,
                offset: 0
            )

            guard !Task.isCancelled else { return }
            self.filteredItems = results
            self.hasMore = results.count == pageSize
            self.errorMessage = nil
        } catch {
            SnapDrillLogger.generic.error("刷新题库失败: \(error.localizedDescription)")
            self.errorMessage = L10n.Errors.loadFailed
        }
    }

    /// 加载更多（分页）
    public func loadMore() async {
        guard hasMore, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // 先计算下一页索引，fetch 成功后再写回 currentPage，
            // 避免 fetch 抛出异常时 currentPage 已递增导致后续跳页。
            let nextPage = currentPage + 1
            let nextItems = try repositories.review.fetchFilteredModels(
                searchText: searchText,
                subjects: selectedSubjects,
                tags: selectedTags,
                difficulties: selectedDifficulties,
                sortDescriptors: sortOption.sortDescriptors,
                limit: pageSize,
                offset: nextPage * pageSize
            )

            guard !Task.isCancelled else { return }
            currentPage = nextPage
            hasMore = nextItems.count == pageSize
            self.filteredItems.append(contentsOf: nextItems)
        } catch {
            SnapDrillLogger.generic.error("加载更多题目失败: \(error.localizedDescription)")
            // 分页失败不覆盖已有数据的 errorMessage，仅 log；
            // 避免用户已浏览的列表突然被错误状态替换
        }
    }

    /// 软删除题目（从列表移除，暂存 5 秒后真正删除，支持撤销）
    public func softDeleteItems(ids: Set<UUID>) {
        // 暂存待删除的题目（用于撤销时恢复列表）
        let itemsToDelete = filteredItems.filter { ids.contains($0.id) }
        pendingDeletionItemBatches.append((ids: ids, items: itemsToDelete))

        // 从列表中移除（视觉即时反馈）
        withAnimation {
            filteredItems.removeAll { ids.contains($0.id) }
        }

        // 调度删除（5 秒倒计时由 App 级 DeletionScheduler 管理）
        let repos = repositories
        let previouslyPendingIDs = deletionScheduler.pendingDeletionIDs
        discardPendingDeletionBatches(matching: previouslyPendingIDs)
        deletionScheduler.scheduleDeletion(ids: ids) { idsToDelete in
            for id in idsToDelete {
                do {
                    try await repos.review.delete(id: id)
                } catch {
                    SnapDrillLogger.generic.error("删除题目失败（id=\(id)）: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 撤销删除（恢复暂存的题目到列表）
    public func undoDelete() {
        let result = deletionScheduler.undoDeletion()
        guard case .undone(let restoredIDs) = result else { return }
        let itemsToRestore = pendingDeletionItemBatches
            .flatMap { $0.items }
            .filter { restoredIDs.contains($0.id) }
        removePendingDeletionBatches(matching: restoredIDs)

        // 使用当前排序选项恢复列表顺序
        let descriptors = sortOption.sortDescriptors

        withAnimation {
            filteredItems.append(contentsOf: itemsToRestore)
            filteredItems.sort { lhs, rhs in
                for descriptor in descriptors {
                    switch descriptor.compare(lhs, rhs) {
                    case .orderedAscending: return true
                    case .orderedDescending: return false
                    case .orderedSame: continue
                    }
                }
                return false
            }
        }
    }

    // 删除逻辑已委托给 DeletionScheduler（App 级生命周期）

    /// 批量为选中题目添加标签
    public func addTagsToItems(ids: Set<UUID>, tagNames: Set<String>) async {
        do {
            let items = try repositories.review.fetchModels(by: ids)
            for item in items {
                var currentTags = item.tags ?? []
                let currentNames = Set(currentTags.map(\.name))
                for name in tagNames where !currentNames.contains(name) {
                    let tag = try repositories.tag.fetchOrCreateModel(name: name, colorHex: "007AFF")
                    currentTags.append(tag)
                }
                item.tags = currentTags
            }
            try repositories.review.saveContext()
        } catch {
            SnapDrillLogger.generic.error("批量打标签失败: \(error.localizedDescription)")
            self.operationError = L10n.Errors.batchTagFailed
        }
    }

    /// 重置所有过滤器
    public func resetFilters() {
        searchText = ""
        selectedSubjects.removeAll()
        selectedTags.removeAll()
        selectedDifficulties.removeAll()
    }

    /// 取消所有进行中的异步任务（由 View 的 onDisappear 调用）
    ///
    /// 不再在页面离开时提交 pending 删除 —— 删除倒计时由
    /// DeletionScheduler（App 级）管理，不随 View 释放而中断。
    public func cancelTasks() {
        searchTask?.cancel()
        searchTask = nil
        pendingDeletionItemBatches.removeAll()
    }

    private func discardPendingDeletionBatches(matching ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        removePendingDeletionBatches(matching: ids)
    }

    private func removePendingDeletionBatches(matching ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        pendingDeletionItemBatches = pendingDeletionItemBatches.compactMap { batch in
            let remainingItems = batch.items.filter { !ids.contains($0.id) }
            guard !remainingItems.isEmpty else { return nil }
            return (ids: Set(remainingItems.map(\.id)), items: remainingItems)
        }
    }
}
