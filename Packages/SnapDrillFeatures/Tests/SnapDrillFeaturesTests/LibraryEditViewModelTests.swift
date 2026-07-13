//
//  LibraryEditViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  LibraryEditViewModel 核心路径单元测试：init 状态映射、save 持久化、图片操作、动态维度。
//

import Testing
import SwiftUI
import SwiftData
import Foundation
import UIKit
import PhotosUI
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore

private actor SuspendedLibraryPhotoDataLoader {
    private let data: Data
    private var didStart = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?

    init(data: Data) {
        self.data = data
    }

    func load() async -> Data {
        didStart = true
        startWaiter?.resume()
        startWaiter = nil
        await withCheckedContinuation { releaseWaiter = $0 }
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

}

@Suite("LibraryEditViewModel 编辑与保存测试", .serialized)
final class LibraryEditViewModelTests {

    // MARK: - 存储属性（每次 @Test 执行前由 Swift Testing 调用 init() 重建）

    /// ModelContainer 必须作为实例属性保活：ModelContext 对 ModelContainer 持弱引用，
    /// 若 container 被提前释放，后续 insert/fetch/save 均会 crash（x0 = nil, brk #1）。
    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        // L3：用 SnapDrillSchemaV1.models（含 CategoryDimension/Value），否则 categoryValues 关系无法解析
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    // MARK: - Helpers

    private struct TestContext {
        let vm: LibraryEditViewModel
        let repos: RepositoryContainer
        let item: ArchiveItemModel
    }

    private func createVM(
        content: String? = "原始题目",
        imagePath: String? = nil,
        answerText: String? = "原始答案",
        answerImagePath: String? = nil,
        imageStorage: ImageStorage = ImageStorage(baseDirectory: FileManager.default.temporaryDirectory),
        photoDataLoader: @escaping @Sendable (PhotosPickerItem) async throws -> Data? = {
            try await $0.loadTransferable(type: Data.self)
        }
    ) throws -> TestContext {
        let item = ArchiveItemModel(
            content: content,
            imagePath: imagePath,
            answerText: answerText,
            answerImagePath: answerImagePath
        )
        repos.archive.insert(item)

        let vm = LibraryEditViewModel(
            item: item,
            repositories: repos,
            imageStorage: imageStorage,
            ocrService: MockOCRServiceShared(),
            photoDataLoader: photoDataLoader
        )
        return TestContext(vm: vm, repos: repos, item: item)
    }

    private func removeTemporaryDirectory(_ url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            Issue.record("清理测试目录失败: \(error.localizedDescription)")
        }
    }

    // MARK: - init 状态映射

    @Test("init 从 ArchiveItemModel 正确映射文本与答案字段")
    func init_mapsAllFields() throws {
        let ctx = try createVM(
            content: "测试内容",
            answerText: "测试答案"
        )

        #expect(ctx.vm.content == "测试内容")
        #expect(ctx.vm.answer == "测试答案")
    }

    @Test("init content 为 nil 时映射为空字符串")
    func init_nilContent_mapsToEmpty() throws {
        let ctx = try createVM(content: nil, answerText: nil)

        #expect(ctx.vm.content == "")
        #expect(ctx.vm.answer == "")
    }

    // MARK: - loadData（动态维度）

    @Test("loadData 加载内置维度")
    func loadData_loadsDimensions() async throws {
        repos.dimension.seedDefaultsIfNeeded()
        let ctx = try createVM()

        await ctx.vm.loadData()

        // seed 出 4 个内置维度（category/source/level/tag）
        #expect(ctx.vm.dimensions.count >= 4)
    }

    @Test("loadData 从 item.categoryValues 初始化维度选中态")
    func loadData_initializesSelectedFromCategoryValues() async throws {
        repos.dimension.seedDefaultsIfNeeded()
        let dims = try repos.dimension.fetchAllModels()
        let categoryDim = try #require(dims.first { $0.systemKey == "category" })
        let value = repos.categoryValue.fetchOrCreate(name: "数学", in: categoryDim)
        try repos.categoryValue.saveContext()

        let item = ArchiveItemModel(content: "题目")
        item.categoryValues = [value]
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let vm = LibraryEditViewModel(item: item, repositories: repos, ocrService: MockOCRServiceShared())
        await vm.loadData()

        #expect(vm.selectedIds(forDimension: categoryDim.id).contains(value.id))
    }

    @Test("重复 loadData 不覆盖尚未保存的维度选择")
    func loadData_repeatedCall_preservesPendingDimensionSelection() async throws {
        repos.dimension.seedDefaultsIfNeeded()
        let ctx = try createVM()
        await ctx.vm.loadData()
        let tagDimension = try #require(ctx.vm.dimensions.first { $0.systemKey == "tag" })
        ctx.vm.createValue(name: "待保存标签", inDimension: tagDimension.id)
        let selectedBeforeReload = ctx.vm.selectedIds(forDimension: tagDimension.id)
        #expect(!selectedBeforeReload.isEmpty)

        await ctx.vm.loadData()

        #expect(ctx.vm.selectedIds(forDimension: tagDimension.id) == selectedBeforeReload)
    }

    // MARK: - 图片操作

    @Test("removeAnswerImage 设置清除标志")
    func removeAnswerImage_setsFlag() throws {
        let ctx = try createVM()
        ctx.vm.answerDisplayedImage = createTestImage()

        ctx.vm.removeAnswerImage()

        #expect(ctx.vm.answerDisplayedImage == nil)
        #expect(ctx.vm.isAnswerImageCleared == true)
    }

    @Test("重复 loadData 不会恢复用户已移除的答案图")
    func loadData_afterRemovingAnswerImage_doesNotRestoreImage() async throws {
        let storageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LibraryEditAnswerReload-\(UUID().uuidString)")
        defer { removeTemporaryDirectory(storageDirectory) }
        let storage = ImageStorage(baseDirectory: storageDirectory)
        let path = try await storage.saveImage(createTestImage())
        let ctx = try createVM(answerImagePath: path, imageStorage: storage)
        await ctx.vm.loadData()
        #expect(ctx.vm.answerDisplayedImage != nil)

        ctx.vm.removeAnswerImage()
        await ctx.vm.loadData()

        #expect(ctx.vm.answerDisplayedImage == nil)
        #expect(ctx.vm.isAnswerImageCleared)
    }

    @Test("答案图加载期间保存不会静默漏图")
    func save_whileAnswerPhotoLoading_doesNotDropImage() async throws {
        guard let data = createTestImage().jpegData(compressionQuality: 0.8) else {
            Issue.record("测试图片无法编码")
            return
        }
        let loader = SuspendedLibraryPhotoDataLoader(data: data)
        let storageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LibraryEditPhotoRace-\(UUID().uuidString)")
        defer { removeTemporaryDirectory(storageDirectory) }
        let storage = ImageStorage(baseDirectory: storageDirectory)
        let ctx = try createVM(
            imageStorage: storage,
            photoDataLoader: { _ in await loader.load() }
        )

        let loadTask = try #require(
            ctx.vm.loadAnswerPhoto(PhotosPickerItem(itemIdentifier: "pending-answer-photo"))
        )
        await loader.waitUntilStarted()
        #expect(ctx.vm.isAnswerPhotoLoading)

        await ctx.vm.save()
        #expect(!ctx.vm.isSavedNormally)
        #expect(ctx.item.answerImagePath == nil)

        await loader.release()
        await loadTask.value
        #expect(ctx.vm.answerDisplayedImage != nil)
        #expect(!ctx.vm.isAnswerPhotoLoading)
        await ctx.vm.save()

        let path = try #require(ctx.item.answerImagePath)
        let persistedImage = await storage.loadImageAsync(path: path)
        #expect(persistedImage != nil)
        try await storage.deleteImage(path: path)
    }

    @Test("题目图加载期间保存不会忽略待裁剪图片")
    func save_whileQuestionPhotoLoading_doesNotComplete() async throws {
        guard let data = createTestImage().pngData() else {
            Issue.record("测试图片无法编码")
            return
        }
        let loader = SuspendedLibraryPhotoDataLoader(data: data)
        let ctx = try createVM(photoDataLoader: { _ in await loader.load() })
        var loadedImage: UIImage?

        let loadTask = try #require(
            ctx.vm.loadQuestionPhoto(PhotosPickerItem(itemIdentifier: "pending-question-photo")) {
                loadedImage = $0
            }
        )
        await loader.waitUntilStarted()

        await ctx.vm.save()
        #expect(!ctx.vm.isSavedNormally)
        await loader.release()
        await loadTask.value
        #expect(loadedImage != nil)
        #expect(!ctx.vm.isQuestionPhotoLoading)
    }

    @Test("答案图连续选择时迟到结果不会覆盖最新图片")
    func loadAnswerPhoto_staleSelectionDoesNotWin() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let firstImage = UIGraphicsImageRenderer(
            size: CGSize(width: 8, height: 8),
            format: format
        ).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        let secondImage = UIGraphicsImageRenderer(
            size: CGSize(width: 16, height: 8),
            format: format
        ).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 16, height: 8))
        }
        let firstData = try #require(firstImage.pngData())
        let secondData = try #require(secondImage.pngData())
        let firstLoader = SuspendedLibraryPhotoDataLoader(data: firstData)
        let secondLoader = SuspendedLibraryPhotoDataLoader(data: secondData)
        let ctx = try createVM(photoDataLoader: { item in
            if item.itemIdentifier == "first-answer-photo" {
                return await firstLoader.load()
            }
            return await secondLoader.load()
        })

        let firstTask = try #require(
            ctx.vm.loadAnswerPhoto(PhotosPickerItem(itemIdentifier: "first-answer-photo"))
        )
        await firstLoader.waitUntilStarted()
        let secondTask = try #require(
            ctx.vm.loadAnswerPhoto(PhotosPickerItem(itemIdentifier: "second-answer-photo"))
        )
        await secondLoader.waitUntilStarted()

        await secondLoader.release()
        await secondTask.value
        #expect(ctx.vm.answerDisplayedImage?.size.width == 16)
        await firstLoader.release()
        await firstTask.value

        #expect(ctx.vm.answerDisplayedImage?.size.width == 16)
        #expect(!ctx.vm.isAnswerPhotoLoading)
    }

    @Test("移除答案图会取消尚未完成的选择")
    func removeAnswerImage_cancelsPendingSelection() async throws {
        guard let data = createTestImage().pngData() else {
            Issue.record("测试图片无法编码")
            return
        }
        let loader = SuspendedLibraryPhotoDataLoader(data: data)
        let ctx = try createVM(photoDataLoader: { _ in await loader.load() })

        let loadTask = try #require(
            ctx.vm.loadAnswerPhoto(PhotosPickerItem(itemIdentifier: "answer-photo-to-remove"))
        )
        await loader.waitUntilStarted()
        ctx.vm.removeAnswerImage()
        await loader.release()
        await loadTask.value

        #expect(ctx.vm.answerDisplayedImage == nil)
        #expect(ctx.vm.isAnswerImageCleared)
        #expect(!ctx.vm.isAnswerPhotoLoading)
    }

    @Test("handleNewImage 更新显示图片并触发 OCR")
    func handleNewImage_triggersOCR() async throws {
        let mockOCR = MockOCRServiceShared()
        mockOCR.recognizeTextResult = "OCR 新文本"
        let item = ArchiveItemModel(content: "旧文本")
        repos.archive.insert(item)

        let vm = LibraryEditViewModel(item: item, repositories: repos, ocrService: mockOCR)

        vm.handleNewImage(createTestImage())

        #expect(vm.isProcessing == true)
        // 轮询等待 OCR 任务完成（观测 ViewModel 最终状态，而非 Mock 中间状态）
        try await waitUntil { vm.isProcessing == false }
        #expect(vm.content == "OCR 新文本")
        #expect(mockOCR.recognizeTextCallCount == 1)
    }

    // MARK: - save

    @Test("save 更新 @Model 文本与答案属性")
    func save_updatesModelProperties() async throws {
        let ctx = try createVM()

        ctx.vm.content = "修改后的内容"
        ctx.vm.answer = "修改后的答案"

        await ctx.vm.save()

        #expect(ctx.vm.isSavedNormally == true)
        #expect(ctx.item.content == "修改后的内容")
        #expect(ctx.item.answerText == "修改后的答案")
    }

    @Test("save 同步选中的维度值到 @Model")
    func save_syncsDimensionValues() async throws {
        repos.dimension.seedDefaultsIfNeeded()
        let ctx = try createVM()
        await ctx.vm.loadData()
        // tag 维度为多值，现场新建两个值（createValue 自动选中）
        let tagDim = try #require(ctx.vm.dimensions.first { $0.systemKey == "tag" })
        ctx.vm.createValue(name: "易错", inDimension: tagDim.id)
        ctx.vm.createValue(name: "考前必看", inDimension: tagDim.id)

        await ctx.vm.save()

        let names = (ctx.item.categoryValues ?? []).map(\.name).sorted()
        #expect(names == ["易错", "考前必看"])
    }

    @Test("save 空内容且无图片时不保存")
    func save_emptyContentNoImage_noOp() async throws {
        let ctx = try createVM(content: "原始内容")
        ctx.vm.content = ""
        ctx.vm.displayedImage = nil

        await ctx.vm.save()

        #expect(ctx.vm.isSavedNormally == false)
    }

    @Test("save 发送 reviewDataDidChange 通知")
    func save_postsNotification() async throws {
        let ctx = try createVM()
        ctx.vm.content = "更新内容"

        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .reviewDataDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }

        await ctx.vm.save()

        NotificationCenter.default.removeObserver(observer)
        #expect(notificationReceived == true)
    }

    // MARK: - cancelTasks

    @Test("cancelTasks 不崩溃")
    func cancelTasks_noCrash() throws {
        let ctx = try createVM()
        ctx.vm.cancelTasks()
    }
}
