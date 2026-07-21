//
//  CaptureResultViewModelPhotoRaceTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import Testing
import UIKit
@testable import SnapDrillCore
@testable import SnapDrillData
@testable import SnapDrillFeatureCapture

private actor SuspendedPhotoDataLoader {
    private let data: Data
    private var didStart = false
    private var didComplete = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?
    private var completionWaiters: [CheckedContinuation<Void, Never>] = []

    init(data: Data) {
        self.data = data
    }

    func load() async -> Data {
        didStart = true
        startWaiter?.resume()
        startWaiter = nil
        await withCheckedContinuation { releaseWaiter = $0 }
        didComplete = true
        completionWaiters.forEach { $0.resume() }
        completionWaiters.removeAll()
        return data
    }

    func waitUntilStarted() async {
        guard !didStart else { return }
        await withCheckedContinuation { startWaiter = $0 }
    }

    func release() {
        releaseWaiter?.resume()
        releaseWaiter = nil
    }

    func waitUntilCompleted() async {
        guard !didComplete else { return }
        await withCheckedContinuation { completionWaiters.append($0) }
    }
}

@Suite("CaptureResultViewModel 答案图竞态测试", .serialized)
@MainActor
final class CaptureResultViewModelPhotoRaceTests {
    private let container: ModelContainer
    private let repositories: RepositoryContainer

    init() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repositories = RepositoryContainer(modelContext: container.mainContext)
    }

    private func makeViewModel(
        content: String,
        photoDataLoader: @escaping @Sendable (PhotosPickerItem) async throws -> Data?
    ) -> CaptureResultViewModel {
        CaptureResultViewModel(
            content: content,
            image: nil,
            draftToken: nil,
            repositories: repositories,
            ocrService: MockOCRServiceShared(),
            analyticsService: AnalyticsServiceMock(),
            contentTaggingService: ContentTaggingServiceMock(),
            router: CaptureRouter(),
            draftService: CaptureDraftServiceMock(),
            activityTracker: AppActivityTracker(),
            photoDataLoader: photoDataLoader
        )
    }

    @Test("答案图仍在加载时保存不会静默丢图")
    func saveResult_whileAnswerPhotoLoading_doesNotDropImage() async throws {
        guard let photoData = createTestImage().jpegData(compressionQuality: 0.8) else {
            Issue.record("测试图片无法编码")
            return
        }
        let loader = SuspendedPhotoDataLoader(data: photoData)
        let viewModel = makeViewModel(content: "带答案图的资料") { _ in
            await loader.load()
        }

        viewModel.answerPhotoItem = PhotosPickerItem(itemIdentifier: "answer-photo-race-test")
        await loader.waitUntilStarted()
        #expect(viewModel.isAnswerPhotoLoading)

        viewModel.save()
        #expect(!viewModel.isSaving)
        #expect(try repositories.archive.totalCount() == 0)

        await viewModel.saveResult()
        #expect(try repositories.archive.totalCount() == 0)

        await loader.release()
        try await waitUntil("答案图加载完成") { viewModel.answerImage != nil }
        #expect(!viewModel.isAnswerPhotoLoading)
        await viewModel.saveResult()

        let items = try repositories.archive.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.answerImagePath != nil)
    }

    @Test("连续选择答案图时，迟到的旧任务不会覆盖新图")
    func answerPhotoSelection_staleLoadDoesNotOverwriteLatestImage() async throws {
        let firstImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }
        let secondImage = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 1)).image { _ in }
        guard let firstData = firstImage.pngData(),
              let secondData = secondImage.pngData(),
              let secondPixelWidth = UIImage(data: secondData)?.cgImage?.width else {
            Issue.record("测试图片无法编码")
            return
        }
        let firstLoader = SuspendedPhotoDataLoader(data: firstData)
        let secondLoader = SuspendedPhotoDataLoader(data: secondData)
        let viewModel = makeViewModel(content: "连续选择答案图") { item in
            if item.itemIdentifier == "first-answer-photo" {
                return await firstLoader.load()
            }
            return await secondLoader.load()
        }

        viewModel.answerPhotoItem = PhotosPickerItem(itemIdentifier: "first-answer-photo")
        await firstLoader.waitUntilStarted()
        viewModel.answerPhotoItem = PhotosPickerItem(itemIdentifier: "second-answer-photo")
        await secondLoader.waitUntilStarted()

        await secondLoader.release()
        try await waitUntil("新答案图加载完成") {
            viewModel.answerImage?.cgImage?.width == secondPixelWidth && !viewModel.isAnswerPhotoLoading
        }

        await firstLoader.release()
        await firstLoader.waitUntilCompleted()

        #expect(viewModel.answerImage?.cgImage?.width == secondPixelWidth)
        #expect(!viewModel.isAnswerPhotoLoading)
    }

    @Test("加载替换图时移除答案图会取消迟到写回")
    func removeAnswerImage_whileReplacementLoads_preventsLateWriteback() async throws {
        guard let replacementData = createTestImage().pngData() else {
            Issue.record("测试图片无法编码")
            return
        }
        let loader = SuspendedPhotoDataLoader(data: replacementData)
        let viewModel = makeViewModel(content: "移除答案图") { _ in
            await loader.load()
        }
        viewModel.answerImage = createTestImage()
        viewModel.answerPhotoItem = PhotosPickerItem(itemIdentifier: "replacement-answer-photo")
        await loader.waitUntilStarted()

        viewModel.removeAnswerImage()
        #expect(viewModel.answerPhotoItem == nil)
        #expect(viewModel.answerImage == nil)
        #expect(!viewModel.isAnswerPhotoLoading)

        await loader.release()
        await loader.waitUntilCompleted()

        #expect(viewModel.answerImage == nil)
        #expect(!viewModel.isAnswerPhotoLoading)
    }

    @Test("退出时取消答案图加载会阻止迟到写回")
    func cancelTasks_whileAnswerPhotoLoads_preventsLateWriteback() async throws {
        guard let photoData = createTestImage().pngData() else {
            Issue.record("测试图片无法编码")
            return
        }
        let loader = SuspendedPhotoDataLoader(data: photoData)
        let viewModel = makeViewModel(content: "取消答案图加载") { _ in
            await loader.load()
        }
        viewModel.answerPhotoItem = PhotosPickerItem(itemIdentifier: "cancelled-answer-photo")
        await loader.waitUntilStarted()

        viewModel.cancelTasks()
        #expect(!viewModel.isAnswerPhotoLoading)

        await loader.release()
        await loader.waitUntilCompleted()

        #expect(viewModel.answerImage == nil)
        #expect(!viewModel.isAnswerPhotoLoading)
    }
}
