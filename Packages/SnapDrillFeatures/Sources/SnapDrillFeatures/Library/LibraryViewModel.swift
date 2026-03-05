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

@Observable
@MainActor
public final class LibraryViewModel {

    // MARK: - Dependencies

    private let repositories: RepositoryContainer

    // MARK: - State

    public var filteredItems: [ReviewItemModel] = []
    public var subjects: [SubjectModel] = []
    public var allTags: [TagModel] = []

    public var searchText: String = "" {
        didSet { triggerRefresh() }
    }
    public var selectedSubjects: Set<String> = [] {
        didSet { triggerRefresh() }
    }
    public var selectedTags: Set<String> = [] {
        didSet { triggerRefresh() }
    }

    public var isLoading: Bool = false
    private var currentPage: Int = 0
    private let pageSize: Int = 50
    @ObservationIgnored
    // nonisolated(unsafe)：Task.cancel() 是线程安全的，deinit 调用安全；
    // 仅在 @MainActor 上写入，deinit 只读取引用后调用 cancel()，无数据竞争。
    nonisolated(unsafe) private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

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
            await refreshData()
        } catch {
            SnapDrillLogger.generic.error("加载题库元数据失败: \(error.localizedDescription)")
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
                limit: pageSize,
                offset: 0
            )

            guard !Task.isCancelled else { return }
            self.filteredItems = results
        } catch {
            SnapDrillLogger.generic.error("刷新题库失败: \(error.localizedDescription)")
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
                limit: pageSize,
                offset: nextPage * pageSize
            )

            guard !Task.isCancelled else { return }
            currentPage = nextPage
            self.filteredItems.append(contentsOf: nextItems)
        } catch {
            SnapDrillLogger.generic.error("加载更多题目失败: \(error.localizedDescription)")
        }
    }

    /// 删除单个题目
    public func deleteItem(_ item: ReviewItemModel) {
        do {
            try repositories.review.delete(id: item.id)
            filteredItems.removeAll { $0.id == item.id }
        } catch {
            SnapDrillLogger.generic.error("删除题目失败: \(error.localizedDescription)")
        }
    }

    /// 批量删除题目（仅移除实际删除成功的条目）
    public func deleteItems(ids: Set<UUID>) {
        var successfullyDeleted: Set<UUID> = []
        for id in ids {
            do {
                try repositories.review.delete(id: id)
                successfullyDeleted.insert(id)
            } catch {
                SnapDrillLogger.generic.error("批量删除失败（id=\(id)）: \(error.localizedDescription)")
            }
        }
        filteredItems.removeAll { successfullyDeleted.contains($0.id) }
    }

    /// 重置所有过滤器
    public func resetFilters() {
        searchText = ""
        selectedSubjects.removeAll()
        selectedTags.removeAll()
    }

    deinit {
        searchTask?.cancel()
    }
}
