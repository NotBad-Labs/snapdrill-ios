//
//  DashboardViewModel.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
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
    
    // MARK: - Dependencies
    
    @ObservationIgnored
    nonisolated(unsafe) private var dataChangeObserver: Any?
    private let draftService: CaptureDraftServiceProtocol
    private let subjectRepository: SubjectRepositoryProtocol
    private let reviewRepository: ReviewRepositoryProtocol
    
    public init(
        draftService: CaptureDraftServiceProtocol = CaptureDraftService.shared,
        subjectRepository: SubjectRepositoryProtocol? = nil,
        reviewRepository: ReviewRepositoryProtocol? = nil
    ) {
        self.draftService = draftService
        // 对于未提供实例的情况，我们在 View 侧通过 @Environment(\.repositories) 进行初始化和注入
        self.subjectRepository = subjectRepository ?? DefaultRepositoryContainer().subject
        self.reviewRepository = reviewRepository ?? DefaultRepositoryContainer().review
        
        setupDataRetention()
    }
    
    /// 设置数据变更监听，确保跨视图同步
    private func setupDataRetention() {
        dataChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                SnapDrillLogger.generic.info("📡 Data change detected, refreshing dashboard stats...")
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
    
    /// 加载并刷新仪表盘数据
    public func loadData() {
        subjectRepository.initializeDefaultsIfNeeded()
        
        do {
            todayItemsCount = try reviewRepository.fetchTodayCount()
            totalCount = try reviewRepository.totalItemCount()
            dueCount = try reviewRepository.fetchDueCount()
        } catch {
            SnapDrillLogger.generic.error("Failed to fetch today's items count: \(error)")
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
