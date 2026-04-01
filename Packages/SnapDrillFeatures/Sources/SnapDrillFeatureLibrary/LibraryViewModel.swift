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
@Observable
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
    /// 数据加载错误信息（非 nil 时 View 应展示错误状态）
    public var errorMessage: String?
    /// 操作错误信息（非 nil 时 View 展示 alert，用于删除、打标签等操作）
    public var operationError: String?
    private var currentPage: Int = 0
    private let pageSize: Int = 50
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
            self.subjects = try repositories.subject.fetchAllModels()
            self.allTags = try repositories.tag.fetchAllModels()
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
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
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
            self.errorMessage = nil
        } catch {
            SnapDrillLogger.generic.error("刷新题库失败: \(error.localizedDescription)")
            self.errorMessage = L10n.Errors.loadFailed
        }
    }

    /// 加载更多（分页）
    public func loadMore() async {
        guard !isLoading else { return }
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
            self.filteredItems.append(contentsOf: nextItems)
        } catch {
            SnapDrillLogger.generic.error("加载更多题目失败: \(error.localizedDescription)")
            // 分页失败不覆盖已有数据的 errorMessage，仅 log；
            // 避免用户已浏览的列表突然被错误状态替换
        }
    }

    /// 删除单个题目
    public func deleteItem(_ item: ReviewItemModel) async {
        do {
            try await repositories.review.delete(id: item.id)
            filteredItems.removeAll { $0.id == item.id }
        } catch {
            SnapDrillLogger.generic.error("删除题目失败: \(error.localizedDescription)")
            self.operationError = L10n.Errors.deleteFailed
        }
    }

    /// 批量删除题目（仅移除实际删除成功的条目）
    public func deleteItems(ids: Set<UUID>) async {
        var successfullyDeleted: Set<UUID> = []
        for id in ids {
            do {
                try await repositories.review.delete(id: id)
                successfullyDeleted.insert(id)
            } catch {
                SnapDrillLogger.generic.error("批量删除失败（id=\(id)）: \(error.localizedDescription)")
            }
        }
        filteredItems.removeAll { successfullyDeleted.contains($0.id) }
        if successfullyDeleted.count < ids.count {
            self.operationError = L10n.Errors.deleteFailed
        }
    }

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
    public func cancelTasks() {
        searchTask?.cancel()
        searchTask = nil
    }
}
