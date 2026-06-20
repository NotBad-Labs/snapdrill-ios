//
//  ReviewViewModelStaleModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SwiftData
import Testing
@testable import SnapDrillCore
@testable import SnapDrillData
@testable import SnapDrillFeatureReview

@Suite("ReviewViewModel stale model guard", .serialized)
@MainActor
final class ReviewViewModelStaleModelTests {
    private let container: ModelContainer
    private let repo: ReviewRepository

    init() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repo = ReviewRepository(modelContext: container.mainContext)
    }

    @discardableResult
    private func insertDueItem(content: String) -> ReviewItemModel {
        let model = ReviewItemModel(content: content)
        model.nextReviewAt = Date().addingTimeInterval(-3600)
        repo.insert(model)
        return model
    }

    @Test("评分前当前条目已被删除时跳过，不写回已删 @Model")
    func handleSwipe_deletedCurrentItem_skipsWithoutReinserting() async throws {
        let model = insertDueItem(content: "已被删除的题")
        let id = model.id

        let vm = ReviewViewModel(repository: repo, analyticsService: AnalyticsServiceMock())
        await vm.loadDataAsync()
        vm.startSession()

        #expect(vm.workingItems.first?.id == id)
        try await repo.delete(id: id)
        #expect(try repo.fetchModel(by: id) == nil)

        let didCommit = vm.handleSwipeCompletion(direction: 1)

        #expect(didCommit == false)
        #expect(vm.workingItems.isEmpty)
        #expect(vm.undoStack.isEmpty)
        #expect(vm.finishedItems == 0)
        #expect(vm.sessionGoodCount == 0)
        #expect(vm.phase == .finished)
        #expect(try repo.fetchModel(by: id) == nil)
    }
}
