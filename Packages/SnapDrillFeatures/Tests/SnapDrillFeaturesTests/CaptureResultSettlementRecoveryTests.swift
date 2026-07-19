//
//  CaptureResultSettlementRecoveryTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SwiftData
import Testing
import UIKit
@testable import SnapDrillCore
@testable import SnapDrillData
@testable import SnapDrillFeatureCapture

@Suite("Capture result settlement recovery", .serialized)
@MainActor
final class CaptureResultSettlementRecoveryTests {
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

    @Test("abort failure survives editor reconstruction")
    func abortFailureSurvivesViewModelRecreation() async throws {
        let draft = CaptureDraft(
            image: createTestImage(),
            content: "draft",
            date: Date(),
            category: nil
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        let storageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CaptureAbortRetry-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(
            at: storageDirectory,
            withIntermediateDirectories: true
        )
        let blockedImagesDirectory = storageDirectory.appendingPathComponent("images")
        try Data("blocked".utf8).write(to: blockedImagesDirectory)
        defer { try? FileManager.default.removeItem(at: storageDirectory) }
        let imageStorage = ImageStorage(baseDirectory: storageDirectory)
        let first = makeViewModel(
            content: "retryable",
            image: createTestImage(),
            token: draft.token,
            draftService: draftService,
            imageStorage: imageStorage
        )
        draftService.discardError = .discardFailed

        await first.saveResult()

        #expect(first.isSaved == false)
        let pending = try #require(draftService.pendingSettlementToken())
        draftService.discardError = nil
        try FileManager.default.removeItem(at: blockedImagesDirectory)
        try FileManager.default.createDirectory(
            at: blockedImagesDirectory,
            withIntermediateDirectories: true
        )
        let retried = makeViewModel(
            content: "retryable",
            image: createTestImage(),
            token: pending,
            draftService: draftService,
            imageStorage: imageStorage
        )

        await retried.saveResult()

        #expect(retried.isSaved)
        #expect(draftService.pendingSettlementToken() == nil)
        #expect(try repositories.archive.totalCount() == 1)
    }

    @Test("uncertain marker publication retries through the production save flow")
    func uncertainSettlementPublicationRetries() async throws {
        let draft = CaptureDraft(
            image: nil,
            content: "draft",
            date: Date(),
            category: nil
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        let viewModel = makeViewModel(
            content: "retryable",
            image: nil,
            token: draft.token,
            draftService: draftService
        )
        draftService.beginSettlementError = .publicationOutcomeUncertain

        await viewModel.saveResult()

        #expect(viewModel.isSaved == false)
        #expect(draftService.pendingSettlementToken() != nil)
        draftService.beginSettlementError = nil

        await viewModel.saveResult()

        #expect(viewModel.isSaved)
        #expect(draftService.pendingSettlementToken() == nil)
        #expect(try repositories.archive.totalCount() == 1)
    }

    private func makeViewModel(
        content: String,
        image: UIImage?,
        token: CaptureDraftToken,
        draftService: CaptureDraftServiceProtocol,
        imageStorage: ImageStorage = ImageStorage(
            baseDirectory: FileManager.default.temporaryDirectory
        )
    ) -> CaptureResultViewModel {
        CaptureResultViewModel(
            content: content,
            image: image,
            draftToken: token,
            repositories: repositories,
            ocrService: MockOCRServiceShared(),
            analyticsService: AnalyticsServiceMock(),
            imageStorage: imageStorage,
            contentTaggingService: ContentTaggingServiceMock(),
            router: CaptureRouter(),
            draftService: draftService
        )
    }
}
