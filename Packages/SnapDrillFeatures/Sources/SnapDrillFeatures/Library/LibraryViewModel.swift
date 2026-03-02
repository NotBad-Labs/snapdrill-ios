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
import SnapDrillDomain

@Observable
@MainActor
public final class LibraryViewModel {
    
    // MARK: - Dependencies
    
    private let reviewUseCase: ReviewUseCaseProtocol
    private let taxonomyUseCase: TaxonomyUseCaseProtocol
    
    // MARK: - State
    
    public var filteredItems: [ReviewItem] = []
    public var subjects: [Subject] = []
    public var allTags: [Tag] = []
    
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
    nonisolated(unsafe) private var searchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(
        reviewUseCase: ReviewUseCaseProtocol,
        taxonomyUseCase: TaxonomyUseCaseProtocol
    ) {
        self.reviewUseCase = reviewUseCase
        self.taxonomyUseCase = taxonomyUseCase
    }
    
    // MARK: - Public API
    
    /// 加载基础元数据与初始数据
    public func loadDataAsync() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.subjects = try taxonomyUseCase.getSubjects()
            self.allTags = try taxonomyUseCase.getAllTags()
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
            let results = try reviewUseCase.searchLibrary(
                query: searchText,
                subjects: selectedSubjects,
                tags: selectedTags,
                page: currentPage,
                pageSize: pageSize
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
            currentPage += 1
            let nextItems = try reviewUseCase.searchLibrary(
                query: searchText,
                subjects: selectedSubjects,
                tags: selectedTags,
                page: currentPage,
                pageSize: pageSize
            )
            
            guard !Task.isCancelled else { return }
            self.filteredItems.append(contentsOf: nextItems)
        } catch {
            SnapDrillLogger.generic.error("加载更多题目失败: \(error.localizedDescription)")
        }
    }
    
    /// 删除单个题目
    public func deleteItem(_ item: ReviewItem) {
        do {
            try reviewUseCase.deleteItem(id: item.id)
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
                try reviewUseCase.deleteItem(id: id)
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
