//
//  CaptureResultDraftRaceTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SwiftData
import Testing
import UIKit
@testable import SnapDrillCore
@testable import SnapDrillData
@testable import SnapDrillFeatureCapture

@Suite("CaptureResult draft/final-save ordering", .serialized)
@MainActor
struct CaptureResultDraftRaceTests {
    @Test("formal save waits for an in-flight draft generation before final CAS")
    func formalSaveWaitsForPendingDraftSave() async throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let repositories = RepositoryContainer(modelContext: container.mainContext)
        let draftService = PendingDraftSaveService()
        let viewModel = CaptureResultViewModel(
            content: "race-safe content",
            image: nil,
            draftToken: nil,
            repositories: repositories,
            ocrService: MockOCRServiceShared(),
            analyticsService: AnalyticsServiceMock(),
            contentTaggingService: ContentTaggingServiceMock(),
            router: CaptureRouter(),
            draftService: draftService,
            activityTracker: AppActivityTracker()
        )

        viewModel.saveDraftOnDisappear()
        await draftService.waitUntilRegularSavePending()

        let formalSave = Task { await viewModel.saveResult() }
        await Task.yield()
        #expect(draftService.finalSaveCallCount == 0)

        draftService.releaseRegularSave()
        await formalSave.value

        #expect(viewModel.isSaved)
        #expect(try repositories.archive.totalCount() == 1)
        #expect(draftService.finalSaveCallCount == 1)
        #expect(isDraftRaceNone(await draftService.loadDraftState()))
    }

    @Test("page cleanup does not cancel the durable exit flush")
    func pageCleanupPreservesExitFlush() async throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let draftService = PendingDraftSaveService()
        let viewModel = CaptureResultViewModel(
            content: "edited immediately before exit",
            image: nil,
            draftToken: nil,
            repositories: RepositoryContainer(modelContext: container.mainContext),
            ocrService: MockOCRServiceShared(),
            analyticsService: AnalyticsServiceMock(),
            contentTaggingService: ContentTaggingServiceMock(),
            router: CaptureRouter(),
            draftService: draftService,
            activityTracker: AppActivityTracker()
        )

        viewModel.saveDraftOnDisappear()
        await draftService.waitUntilRegularSavePending()
        viewModel.cancelTasks()
        draftService.releaseRegularSave()
        await draftService.waitUntilRegularSaveFinished()

        guard case .recoverable(let draft) = await draftService.loadDraftState() else {
            Issue.record("Exit flush must survive page task cleanup")
            return
        }
        #expect(draft.content == "edited immediately before exit")
    }
}

@MainActor
private final class PendingDraftSaveService: CaptureDraftServiceProtocol {
    private let base = CaptureDraftServiceMock()
    private var regularSaveContinuation: CheckedContinuation<Void, Never>?
    private var pendingWaiters: [CheckedContinuation<Void, Never>] = []
    private var finishedWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var isRegularSavePending = false
    private(set) var didFinishRegularSave = false
    private(set) var finalSaveCallCount = 0

    func loadDraftState() async -> CaptureDraftReadState {
        await base.loadDraftState()
    }

    func saveDraft(
        image: UIImage?,
        content: String,
        category: String?,
        expectedToken: CaptureDraftToken?
    ) async throws -> CaptureDraftToken {
        isRegularSavePending = true
        pendingWaiters.forEach { $0.resume() }
        pendingWaiters.removeAll()
        await withCheckedContinuation { continuation in
            regularSaveContinuation = continuation
        }
        defer {
            isRegularSavePending = false
            didFinishRegularSave = true
            finishedWaiters.forEach { $0.resume() }
            finishedWaiters.removeAll()
        }
        try Task.checkCancellation()
        return try await base.saveDraft(
            image: image,
            content: content,
            category: category,
            expectedToken: expectedToken
        )
    }

    func saveDraftAndBeginSettlement(
        image: UIImage?,
        content: String,
        category: String?,
        expectedToken: CaptureDraftToken?
    ) async throws -> CaptureDraftToken {
        finalSaveCallCount += 1
        guard !isRegularSavePending else { throw CaptureDraftError.draftChanged }
        return try await base.saveDraftAndBeginSettlement(
            image: image,
            content: content,
            category: category,
            expectedToken: expectedToken
        )
    }

    func discardDraft(expectedToken: CaptureDraftToken) async throws {
        try await base.discardDraft(expectedToken: expectedToken)
    }

    func discardUnrecoverableDraft(expectedToken: CaptureDraftDiscardToken) async throws {
        try await base.discardUnrecoverableDraft(expectedToken: expectedToken)
    }

    func beginSettlement(expectedToken: CaptureDraftToken) async throws {
        try await base.beginSettlement(expectedToken: expectedToken)
    }

    func completeSettlement(expectedToken: CaptureDraftToken) async throws {
        try await base.completeSettlement(expectedToken: expectedToken)
    }

    func abortSettlement(expectedToken: CaptureDraftToken) async {
        await base.abortSettlement(expectedToken: expectedToken)
    }

    func releaseRegularSave() {
        regularSaveContinuation?.resume()
        regularSaveContinuation = nil
    }

    func waitUntilRegularSavePending() async {
        if isRegularSavePending { return }
        await withCheckedContinuation { continuation in
            pendingWaiters.append(continuation)
        }
    }

    func waitUntilRegularSaveFinished() async {
        if didFinishRegularSave { return }
        await withCheckedContinuation { continuation in
            finishedWaiters.append(continuation)
        }
    }
}

private func isDraftRaceNone(_ state: CaptureDraftReadState) -> Bool {
    if case .none = state { return true }
    return false
}
