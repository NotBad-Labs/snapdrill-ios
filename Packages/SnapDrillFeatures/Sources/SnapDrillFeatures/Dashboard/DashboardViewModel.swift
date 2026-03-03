//
//  DashboardViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首页仪表盘 ViewModel，管理统计数据加载与快捷操作状态。
//

import Foundation
import Observation
import SnapDrillCore
import SnapDrillData

@Observable
@MainActor
public final class DashboardViewModel {

    // MARK: - State

    public var showingSubjectManager = false
    public var showingComingSoon = false
    public var showingDraftAlert = false

    /// 今日新增卡片数
    public var todayItemsCount: Int = 0
    /// 题库总卡片数量
    public var totalCount: Int = 0
    /// 今日待复习卡片数
    public var dueCount: Int = 0
    /// 今日已复习卡片数（用于进度环）
    public var reviewedTodayCount: Int = 0

    // MARK: - Dependencies

    @ObservationIgnored
    nonisolated(unsafe) private var dataChangeObserver: Any?
    private let draftService: CaptureDraftServiceProtocol
    private let repositories: RepositoryContainer

    public init(
        repositories: RepositoryContainer,
        draftService: CaptureDraftServiceProtocol = CaptureDraftService.shared
    ) {
        self.repositories = repositories
        self.draftService = draftService

        setupDataRetention()
    }

    /// 设置数据变更监听
    private func setupDataRetention() {
        dataChangeObserver = NotificationCenter.default.addObserver(
            forName: .reviewDataDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                SnapDrillLogger.generic.info("数据发生变更，刷新仪表盘...")
                self.loadData()
            }
        }
    }

    deinit {
        if let observer = dataChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public API

    /// 加载并刷新统计数据
    public func loadData() {
        do {
            todayItemsCount = try repositories.review.fetchTodayCount()
            totalCount = try repositories.review.totalItemCount()
            dueCount = try repositories.review.fetchDueCount()
            reviewedTodayCount = try repositories.review.fetchTodayReviewedCount()
        } catch {
            SnapDrillLogger.generic.error("加载统计数据失败: \(error.localizedDescription)")
        }
    }

    public func checkDraftAndCapture(router: DashboardRouter) {
        if draftService.hasDraft {
            showingDraftAlert = true
        } else {
            router.navigateToCapture()
        }
    }

    public func startNewCapture(router: DashboardRouter) {
        draftService.clearDraft()
        router.navigateToCapture()
    }

    public func restoreDraft(router: DashboardRouter) {
        if let draft = draftService.loadDraft() {
            router.navigateToCapture(withDraft: draft)
        } else {
            router.navigateToCapture()
        }
    }
}
