//
//  DashboardViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  DashboardViewModel 的单元测试，验证草稿处理与导航逻辑。
//

import Testing
import UIKit
import Foundation
import SnapDrillDomain
import SnapDrillCore
@testable import SnapDrillFeatures

// MARK: - Mock Implementations

@MainActor
final class MockCaptureDraftService: CaptureDraftServiceProtocol {
    var storedDraft: CaptureDraftService.Draft?

    var hasDraft: Bool { storedDraft != nil }

    func saveDraft(image: UIImage, content: String) {
        storedDraft = CaptureDraftService.Draft(image: image, content: content, date: Date())
    }

    func loadDraft() -> CaptureDraftService.Draft? { storedDraft }

    func clearDraft() { storedDraft = nil }
}

@MainActor
final class MockReviewUseCaseForDashboard: ReviewUseCaseProtocol {
    var dueCount: Int = 0
    var todayAddedCount: Int = 0
    var totalItemCount: Int = 0
    var todayReviewedCount: Int = 0

    func getDueItems() throws -> [ReviewItem] { [] }
    func getDueCount() throws -> Int { dueCount }
    func getTodayAddedCount() throws -> Int { todayAddedCount }
    func getTotalItemCount() throws -> Int { totalItemCount }
    func getTodayReviewedCount() throws -> Int { todayReviewedCount }
    func captureNewItem(_ item: ReviewItem) throws {}
    func updateItem(_ item: ReviewItem) throws {}
    func submitReviewResult(id: UUID, rating: ReviewRating) throws {}
    func searchLibrary(query: String, subjects: Set<String>, tags: Set<String>, page: Int, pageSize: Int) throws -> [ReviewItem] { [] }
    func deleteItem(id: UUID) throws {}
    func deleteAllData() throws {}
    func fetchAllItems() throws -> [ReviewItem] { [] }
    func fetchItemsByIds(_ ids: Set<UUID>) throws -> [ReviewItem] { [] }
}

@MainActor
final class MockTaxonomyUseCaseForDashboard: TaxonomyUseCaseProtocol {
    func getSubjects() throws -> [Subject] { [] }
    func getSources() throws -> [Source] { [] }
    func getAllTags() throws -> [Tag] { [] }
    func getOrCreateTag(name: String, colorHex: String) throws -> Tag { Tag(name: name, colorHex: colorHex) }
    func addSubject(name: String, icon: String, colorHex: String) throws {}
    func updateSubject(oldName: String, newName: String, icon: String, colorHex: String) throws {}
    func deleteSubject(name: String) throws {}
    func canDeleteSubject(name: String) throws -> Bool { true }
    func addSource(name: String, icon: String, colorHex: String) throws {}
    func updateSource(oldName: String, newName: String, icon: String, colorHex: String) throws {}
    func deleteSource(name: String) throws {}
    func canDeleteSource(name: String) throws -> Bool { true }
    func getGrades() throws -> [Grade] { [] }
    func addGrade(name: String) throws {}
    func updateGrade(oldName: String, newName: String) throws {}
    func deleteGrade(name: String) throws {}
    func canDeleteGrade(name: String) throws -> Bool { true }
    func deleteAllTaxonomy() throws {}
}

// MARK: - Tests

@MainActor
@Suite("DashboardViewModel 草稿与导航逻辑测试")
struct DashboardViewModelTests {

    private func createTestImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }

    private func makeViewModel(draftService: CaptureDraftServiceProtocol = MockCaptureDraftService()) -> DashboardViewModel {
        DashboardViewModel(
            reviewUseCase: MockReviewUseCaseForDashboard(),
            taxonomyUseCase: MockTaxonomyUseCaseForDashboard(),
            draftService: draftService
        )
    }

    @Test("有草稿时应该弹出提示而不直接进入相机")
    func checkDraftTriggersAlert() {
        let mockDraftService = MockCaptureDraftService()
        mockDraftService.saveDraft(image: createTestImage(), content: "Exist")

        let viewModel = makeViewModel(draftService: mockDraftService)
        let router = DashboardRouter()

        var navigateCalled = false
        router.onNavigateToCapture = { _ in navigateCalled = true }

        viewModel.checkDraftAndCapture(router: router)

        #expect(navigateCalled == false, "存在草稿时，必须拦截导航")
        #expect(viewModel.showingDraftAlert == true)
    }

    @Test("清空草稿开启新拍摄路线")
    func forceStartNewCaptureRoute() {
        let mockDraftService = MockCaptureDraftService()
        mockDraftService.saveDraft(image: createTestImage(), content: "Exist")

        let viewModel = makeViewModel(draftService: mockDraftService)
        let router = DashboardRouter()

        var passedDraft: CaptureDraftService.Draft?
        router.onNavigateToCapture = { draft in passedDraft = draft }

        viewModel.startNewCapture(router: router)

        #expect(mockDraftService.hasDraft == false, "强制开启新拍摄前，必须清空旧草稿")
        #expect(passedDraft == nil, "传递给 Router 的不应有草稿")
    }

    @Test("连续多次调用开始拍摄不应当崩溃")
    func concurrencySpammingStartCapture() {
        let viewModel = makeViewModel()
        let router = DashboardRouter()

        var navigateCount = 0
        router.onNavigateToCapture = { _ in navigateCount += 1 }

        for _ in 0..<5 {
            viewModel.startNewCapture(router: router)
        }

        #expect(navigateCount == 5)
    }

    @Test("loadData 正确填充统计数字")
    func loadDataPopulatesStats() {
        let mockReview = MockReviewUseCaseForDashboard()
        mockReview.dueCount = 5
        mockReview.todayAddedCount = 3
        mockReview.totalItemCount = 42

        let viewModel = DashboardViewModel(
            reviewUseCase: mockReview,
            taxonomyUseCase: MockTaxonomyUseCaseForDashboard()
        )

        viewModel.loadData()

        #expect(viewModel.dueCount == 5)
        #expect(viewModel.todayItemsCount == 3)
        #expect(viewModel.totalCount == 42)
    }
}
