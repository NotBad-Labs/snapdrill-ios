//
//  ReviewViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
import Foundation
import SwiftData
@testable import SnapDrillFeatures
@testable import SnapDrillCore
@testable import SnapDrillData

@MainActor
struct ReviewViewModelTests {

    // Helper to create an in-memory ModelContext for testing.
    private func createTestContext() throws -> ModelContext {
        let schema = Schema([ReviewItemModel.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return ModelContext(container)
    }

    private func createDummyItems(count: Int, due: Bool = true) -> [ReviewItemModel] {
        var items: [ReviewItemModel] = []
        let now = Date()
        for i in 0..<count {
            let item = ReviewItemModel(
                id: UUID(),
                content: "Test Content \(i)",
                createdAt: now,
                subjectString: "Math",
                sourceString: "Manual",
                tags: []
            )
            // If it's due, the next review is in the past, else tomorrow
            item.nextReviewAt = due ? now.addingTimeInterval(-3600) : now.addingTimeInterval(86400)
            items.append(item)
        }
        return items
    }

    @Test
    func testLoadDataFiltersDueItems() throws {
        let context = try createTestContext()
        let vm = ReviewViewModel(modelContext: context)

        // 3 due, 2 not due
        let dueItems = createDummyItems(count: 3, due: true)
        let futureItems = createDummyItems(count: 2, due: false)
        let allItems = dueItems + futureItems

        vm.loadData(allItems: allItems)

        // It should only queue the due items
        #expect(vm.reviewQueue.count == 3)
        #expect(vm.phase == .idle)
    }

    @Test
    func testStartSessionConfiguresWorkingItems() throws {
        let context = try createTestContext()
        let vm = ReviewViewModel(modelContext: context)

        let allItems = createDummyItems(count: 5, due: true)
        vm.loadData(allItems: allItems)
        
        vm.startSession()

        #expect(vm.workingItems.count == 5)
        #expect(vm.finishedItems == 0)
        #expect(vm.undoStack.isEmpty)
        #expect(vm.isAnswerShown == false)
        #expect(vm.phase == .reviewing)
    }

    @Test
    func testHandleSwipeCompletionGood() throws {
        let context = try createTestContext()
        let vm = ReviewViewModel(modelContext: context)

        let item = createDummyItems(count: 1, due: true)[0]
        context.insert(item) // Needs to be inserted for save() to not trap if missing

        vm.loadData(allItems: [item])
        vm.startSession()

        // Give it a "good" swipe (direction 1)
        vm.handleSwipeCompletion(direction: 1)

        // SM-2 logic check: interval should become 1, ease factor defaults to 2.5
        #expect(item.interval == 1)
        #expect(item.repetitions == 1)
        #expect(item.easeFactor == 2.5)

        #expect(vm.workingItems.isEmpty)
        #expect(vm.finishedItems == 1)
        #expect(vm.undoStack.count == 1)
        #expect(vm.phase == .finished)
    }

    @Test
    func testHandleSwipeCompletionAgain() throws {
        let context = try createTestContext()
        let vm = ReviewViewModel(modelContext: context)

        let item = createDummyItems(count: 1, due: true)[0]
        item.repetitions = 5
        item.interval = 10
        item.easeFactor = 2.6
        context.insert(item)

        vm.loadData(allItems: [item])
        vm.startSession()

        // Give it an "again" / forgot swipe (direction -1)
        vm.handleSwipeCompletion(direction: -1)

        // SM-2 logic check for forgot: interval resets, reps reset, ease drops
        #expect(item.interval == 0)
        #expect(item.repetitions == 0)
        #expect(item.easeFactor < 2.6)
        #expect(item.easeFactor >= 1.3) // Lower bound check

        #expect(vm.workingItems.isEmpty)
        #expect(vm.finishedItems == 1)
        #expect(vm.undoStack.count == 1)
        #expect(vm.phase == .finished)
    }

    @Test
    func testUndoLastSwipe() throws {
        let context = try createTestContext()
        let vm = ReviewViewModel(modelContext: context)

        let item = createDummyItems(count: 1, due: true)[0]
        // Save initial state prior to the swipe algorithm modding it
        let initialRep = item.repetitions
        let initialInterval = item.interval
        let initialEase = item.easeFactor
        
        // We'll trust the caller restores DB state for undo, logic just handles stacks:
        vm.loadData(allItems: [item])
        vm.startSession()
        
        // Swipe to complete
        vm.handleSwipeCompletion(direction: 1)
        #expect(vm.phase == .finished)

        // Undo
        vm.undoLastSwipe()
        
        // Working items restored, phase back to reviewing
        #expect(vm.workingItems.count == 1)
        #expect(vm.finishedItems == 0)
        #expect(vm.undoStack.isEmpty)
        #expect(vm.phase == .reviewing)
    }
}
