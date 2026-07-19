//
//  CaptureDraftReconcilerTests.swift
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
@testable import SnapDrillFeatureCapture

@Suite("Capture draft archive settlement", .serialized)
@MainActor
final class CaptureDraftReconcilerTests {
    private let container: ModelContainer
    private let repositories: RepositoryContainer

    init() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        repositories = RepositoryContainer(modelContext: container.mainContext)
    }

    @Test("boot reconciliation retires a draft whose stable archive ID committed")
    func reconcile_matchingArchive_retiresDraft() throws {
        let captureID = UUID()
        let draft = makeDraft(captureID: captureID)
        let draftService = CaptureDraftServiceMock(
            initialDraft: draft,
            pendingSettlementToken: draft.token
        )
        try repositories.archive.insertAndSave(
            ArchiveItemModel(id: captureID, content: "已提交")
        )

        CaptureDraftReconciler.reconcile(
            draftService: draftService,
            repositories: repositories
        )

        guard case .none = draftService.state() else {
            Issue.record("已提交 captureID 不得重新出现恢复提示")
            return
        }
        #expect(draftService.clearCallCount == 1)
    }

    @Test("boot reconciliation retains a draft without a matching archive ID")
    func reconcile_noMatchingArchive_retainsDraft() throws {
        let captureID = UUID()
        let draft = makeDraft(captureID: captureID)
        let draftService = CaptureDraftServiceMock(
            initialDraft: draft,
            pendingSettlementToken: draft.token
        )
        try repositories.archive.insertAndSave(
            ArchiveItemModel(id: UUID(), content: "其他资料")
        )

        CaptureDraftReconciler.reconcile(
            draftService: draftService,
            repositories: repositories
        )

        guard case .recoverable(let remaining) = draftService.state() else {
            Issue.record("未提交的草稿必须保持可恢复")
            return
        }
        #expect(remaining.token == draft.token)
        #expect(draftService.clearCallCount == 0)
    }

    @Test("transient archive query failure stays closed and retries in the same session")
    func reconcile_queryFailure_defersThenReopens() throws {
        let draft = makeDraft(captureID: UUID())
        let draftService = CaptureDraftServiceMock(
            initialDraft: draft,
            pendingSettlementToken: draft.token
        )
        var shouldFail = true
        let lookup: (UUID) throws -> Bool = { _ in
            if shouldFail {
                shouldFail = false
                throw CocoaError(.fileReadUnknown)
            }
            return false
        }

        let deferred = CaptureDraftReconciler.reconcile(
            draftService: draftService,
            repositories: repositories,
            archiveLookup: lookup
        )

        #expect(deferred == .deferred(draft.token))
        guard case .settlementPending(let pending) = draftService.state() else {
            Issue.record("Query uncertainty must retain the settlement fence")
            return
        }
        #expect(pending == draft.token)

        let retried = CaptureDraftReconciler.reconcile(
            draftService: draftService,
            repositories: repositories,
            archiveLookup: lookup
        )
        #expect(retried == .reopened(draft.token))
        guard case .recoverable(let recovered) = draftService.state() else {
            Issue.record("A later successful absence query must reopen recovery")
            return
        }
        #expect(recovered.token == draft.token)
    }

    @Test("failed cleanup hides an archived draft and a later retry retires it")
    func reconcile_cleanupFailure_isNotRecoverableAndRetries() throws {
        let captureID = UUID()
        let draft = makeDraft(captureID: captureID)
        let draftService = CaptureDraftServiceMock(
            initialDraft: draft,
            pendingSettlementToken: draft.token
        )
        draftService.discardError = .discardFailed
        try repositories.archive.insertAndSave(
            ArchiveItemModel(id: captureID, content: "已提交")
        )

        CaptureDraftReconciler.reconcile(
            draftService: draftService,
            repositories: repositories
        )

        guard case .committedPendingRetirement(let token) = draftService.state() else {
            Issue.record("已提交但待清理的草稿不得再次进入恢复编辑")
            return
        }
        #expect(token == draft.token)
        #expect(draftService.state().revision == .generation(draft.token))

        draftService.discardError = nil
        CaptureDraftReconciler.reconcile(
            draftService: draftService,
            repositories: repositories
        )

        guard case .none = draftService.state() else {
            Issue.record("后续清理成功后应移除已提交草稿")
            return
        }
    }

    @Test("matching archive ID without settlement evidence retains a newer edit")
    func reconcile_matchingArchiveWithoutEvidence_retainsDraft() throws {
        let captureID = UUID()
        let draft = makeDraft(captureID: captureID)
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        try repositories.archive.insertAndSave(
            ArchiveItemModel(id: captureID, content: "已提交旧内容")
        )

        CaptureDraftReconciler.reconcile(
            draftService: draftService,
            repositories: repositories
        )

        guard case .recoverable(let remaining) = draftService.state() else {
            Issue.record("没有精确结算证据时不得按 captureID 删除新编辑")
            return
        }
        #expect(remaining.token == draft.token)
        #expect(draftService.clearCallCount == 0)
    }

    @Test("formal save uses stable capture ID and a retry is idempotent")
    func coordinator_stableID_retryDoesNotDuplicate() async throws {
        let captureID = UUID()
        let imageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CaptureSaveCoordinator-\(UUID())", isDirectory: true)
        defer {
            if FileManager.default.fileExists(atPath: imageDirectory.path) {
                do {
                    try FileManager.default.removeItem(at: imageDirectory)
                } catch {
                    Issue.record("测试图片目录清理失败: \(error.localizedDescription)")
                }
            }
        }
        let coordinator = CaptureSaveCoordinator(
            repositories: repositories,
            imageStorage: ImageStorage(baseDirectory: imageDirectory)
        )
        let form = CaptureFormSnapshot(
            content: "稳定 ID",
            image: nil,
            selectedValues: [],
            answerText: "",
            answerImage: nil
        )

        let first = try await coordinator.save(form, id: captureID)
        let second = try await coordinator.save(form, id: captureID)

        guard case .committed = first else {
            Issue.record("首次保存应提交新资料")
            return
        }
        guard case .alreadyCommitted = second else {
            Issue.record("同 captureID 重试应识别已有提交")
            return
        }
        let items = try repositories.archive.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.id == captureID)
    }

    private func makeDraft(captureID: UUID) -> CaptureDraft {
        CaptureDraft(
            image: nil,
            content: "未完成",
            date: Date(),
            category: nil,
            token: CaptureDraftToken(
                captureID: captureID,
                generationID: UUID()
            )
        )
    }
}
