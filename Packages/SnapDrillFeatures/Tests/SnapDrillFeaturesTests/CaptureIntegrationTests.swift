//
//  CaptureIntegrationTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatures
@testable import SnapDrillCore
@testable import SnapDrillData

@MainActor
struct CaptureIntegrationTests {
    
    // Helper to create an in-memory ModelContext for testing.
    private func createTestContext() throws -> ModelContext {
        let schema = Schema(SnapDrillSchemaV1.models)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return container.mainContext
    }

    @Test("验证采集保存后 Dashboard 统计数字能够实时更新")
    func testCaptureSaveUpdatesDashboardStats() throws {
        let context = try createTestContext()
        
        // 1. 初始化 Repository 和 ViewModel
        let reviewRepo = ReviewRepository(modelContext: context)
        let subjectRepo = SubjectRepository(modelContext: context)
        
        let dashboardVM = DashboardViewModel(
            draftService: MockCaptureDraftService(),
            subjectRepository: subjectRepo,
            reviewRepository: reviewRepo
        )
        
        // 初始加载
        dashboardVM.loadData()
        #expect(dashboardVM.totalCount == 0)
        
        // 2. 模拟采集保存过程
        let newItem = ReviewItem(
            content: "Integrated Test Content",
            source: "Test Source",
            difficulty: 3
        )
        
        try reviewRepo.save(newItem, subject: "Math")
        try reviewRepo.save() // 触发通知
        
        // 3. 验证 Dashboard 是否自动刷新且数字正确
        // 这里的异步通知会在主线程主循环中执行，loadData 也是同步触发的
        #expect(dashboardVM.totalCount == 1)
        #expect(dashboardVM.todayItemsCount == 1)
    }
}
