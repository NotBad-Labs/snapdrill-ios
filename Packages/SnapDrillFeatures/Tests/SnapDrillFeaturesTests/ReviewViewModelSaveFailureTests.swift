import Foundation
import SwiftData
import Testing
import SnapDrillCore
@testable import SnapDrillData
@testable import SnapDrillFeatureReview

@MainActor
struct ReviewViewModelSaveFailureTests {
    private let container: ModelContainer
    private let repo: ArchiveRepository
    private var context: ModelContext { container.mainContext }

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: ArchiveItemModel.self, configurations: config)
        repo = ArchiveRepository(modelContext: container.mainContext)
    }

    @discardableResult
    private func insertDueItem(content: String = "测试题目", repetitions: Int = 0, interval: Int = 0) -> ArchiveItemModel {
        let model = ArchiveItemModel(
            content: content,
            createdAt: Date(),
            easeFactor: 2.5,
            interval: interval,
            repetitions: repetitions
        )
        context.insert(model)
        try! context.save()
        return model
    }

    @Test("handleSwipeCompletion 保存失败时恢复 workingItems、undoStack 与 SM-2 字段")
    func handleSwipe_saveFailure_restoresPendingState() async throws {
        let model = insertDueItem(content: "保存失败恢复题", repetitions: 2, interval: 3)
        model.easeFactor = 2.3
        let originalNextReviewAt = model.nextReviewAt
        let originalLastReviewedAt = model.lastReviewedAt

        let vm = ReviewViewModel(
            repository: repo,
            analyticsService: AnalyticsServiceMock(),
            saveContext: {
                throw NSError(domain: "ReviewViewModelTests", code: -1)
            },
            rollbackContext: {}
        )
        await vm.loadDataAsync()
        vm.startSession()
        vm.isAnswerShown = true

        let didCommit = vm.handleSwipeCompletion(direction: 1)

        #expect(didCommit == false)
        #expect(vm.phase == .reviewing)
        #expect(vm.workingItems.count == 1)
        #expect(vm.workingItems.first?.id == model.id)
        #expect(vm.undoStack.isEmpty)
        #expect(vm.finishedItems == 0)
        #expect(vm.sessionGoodCount == 0)
        #expect(vm.sessionAgainCount == 0)
        #expect(vm.isAnswerShown == true)
        #expect(vm.operationError != nil)
        #expect(model.easeFactor == 2.3)
        #expect(model.interval == 3)
        #expect(model.repetitions == 2)
        #expect(model.nextReviewAt == originalNextReviewAt)
        #expect(model.lastReviewedAt == originalLastReviewedAt)
    }
}
