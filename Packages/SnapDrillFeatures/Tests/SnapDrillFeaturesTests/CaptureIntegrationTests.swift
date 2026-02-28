//
//  CaptureIntegrationTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  集成测试：验证数据变更通知触发 Dashboard 自动刷新统计数字。
//

import Testing
import Foundation
import SnapDrillDomain
import SnapDrillCore
@testable import SnapDrillFeatures

// MARK: - Tests

@MainActor
@Suite("Dashboard 数据变更集成测试")
struct CaptureIntegrationTests {

    @Test("数据变更通知触发 Dashboard 自动刷新统计数字")
    func dataChangeNotificationRefreshesDashboard() async throws {
        let mockReview = MockReviewUseCaseForDashboard()
        mockReview.totalItemCount = 0
        mockReview.todayAddedCount = 0

        let dashboardVM = DashboardViewModel(
            reviewUseCase: mockReview,
            taxonomyUseCase: MockTaxonomyUseCaseForDashboard()
        )

        dashboardVM.loadData()
        #expect(dashboardVM.totalCount == 0)
        #expect(dashboardVM.todayItemsCount == 0)

        // 模拟新题目被采集并持久化后，UseCase 层发出数据变更通知
        mockReview.totalItemCount = 1
        mockReview.todayAddedCount = 1

        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)

        // 通知处理器内部以 Task { @MainActor in } 调度，需等待执行
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        #expect(dashboardVM.totalCount == 1)
        #expect(dashboardVM.todayItemsCount == 1)
    }

    @Test("多次数据变更通知触发多次刷新，最终值以最后一次为准")
    func multipleNotificationsRefreshesAccumulate() async throws {
        let mockReview = MockReviewUseCaseForDashboard()
        mockReview.totalItemCount = 0

        let dashboardVM = DashboardViewModel(
            reviewUseCase: mockReview,
            taxonomyUseCase: MockTaxonomyUseCaseForDashboard()
        )

        dashboardVM.loadData()
        #expect(dashboardVM.totalCount == 0)

        mockReview.totalItemCount = 5
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
        NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)

        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        #expect(dashboardVM.totalCount == 5)
    }
}
