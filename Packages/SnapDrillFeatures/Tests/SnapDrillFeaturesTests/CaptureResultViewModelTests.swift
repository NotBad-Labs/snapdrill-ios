//
//  CaptureResultViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  CaptureResultViewModel 核心路径单元测试：保存、验证、分类创建、草稿。
//

import Testing
import TipKit
import SwiftData
import Foundation
import UIKit
@testable import SnapDrillFeatureCapture
@testable import SnapDrillData
@testable import SnapDrillCore
@testable import SnapDrillUI

@Suite("CaptureResultViewModel 保存与表单测试", .serialized)
@MainActor
final class CaptureResultViewModelTests {

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
        let vm: CaptureResultViewModel
        let repos: RepositoryContainer
        let analytics: AnalyticsServiceMock
    }

    private func createVM(
        content: String = "测试文本",
        image: UIImage? = nil,
        draftService: CaptureDraftServiceProtocol = CaptureDraftServiceMock(),
        imageStorage: ImageStorage = ImageStorage(
            baseDirectory: FileManager.default.temporaryDirectory
        )
    ) -> TestContext {
        let analytics = AnalyticsServiceMock()
        let router = CaptureRouter()
        let recoveredDraftToken: CaptureDraftToken?
        if case .recoverable(let draft) = draftService.state() {
            recoveredDraftToken = draft.token
        } else {
            recoveredDraftToken = nil
        }
        let vm = CaptureResultViewModel(
            content: content,
            image: image,
            draftToken: recoveredDraftToken,
            repositories: repos,
            ocrService: MockOCRServiceShared(),
            analyticsService: analytics,
            imageStorage: imageStorage,
            contentTaggingService: ContentTaggingServiceMock(),
            router: router,
            draftService: draftService
        )
        return TestContext(vm: vm, repos: repos, analytics: analytics)
    }

    // MARK: - 初始状态

    @Test("init 正确设置 content 和 image")
    func init_setsContentAndImage() throws {
        let img = createTestImage()
        let ctx = createVM(content: "初始文本", image: img)

        #expect(ctx.vm.content == "初始文本")
        #expect(ctx.vm.image != nil)
        #expect(ctx.vm.isSaved == false)
    }

    // MARK: - saveResult 验证

    @Test("saveResult 文字和图片都为空时报错")
    func saveResult_bothEmpty_showsError() async throws {
        let ctx = createVM(content: "", image: nil)

        await ctx.vm.saveResult()

        #expect(ctx.vm.isSaved == false)
        #expect(ctx.vm.showErrorAlert == true)
        #expect(ctx.vm.errorMessage != nil)
    }

    @Test("saveResult 纯文字成功保存")
    func saveResult_textOnly_saves() async throws {
        let ctx = createVM(content: "纯文字题目")

        await ctx.vm.saveResult()

        #expect(ctx.vm.isSaved == true)
        let items = try ctx.repos.archive.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.content == "纯文字题目")
        #expect(ctx.analytics.hasTrackedEvent(.captureSaved))
    }

    @Test("saveResult 纯图片成功保存")
    func saveResult_imageOnly_saves() async throws {
        let ctx = createVM(content: "", image: createTestImage())

        await ctx.vm.saveResult()

        #expect(ctx.vm.isSaved == true)
        let items = try ctx.repos.archive.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.content == nil)
        #expect(items.first?.imagePath != nil)
    }

    // MARK: - generateDraftIfNeeded

    @Test("generateDraftIfNeeded 未保存且有内容时生成草稿")
    func generateDraftIfNeeded_unsavedWithContent_savesDraft() async throws {
        let draftService = CaptureDraftServiceMock()
        let ctx = createVM(content: "草稿内容", image: createTestImage(), draftService: draftService)

        await ctx.vm.generateDraftIfNeeded()

        #expect(draftService.hasDraft == true)
    }

    @Test("首次草稿 checkpoint 失败必须提示用户")
    func generateDraftIfNeeded_persistenceFailure_isVisible() async {
        let draftService = CaptureDraftServiceMock()
        draftService.saveError = .persistenceFailed
        let ctx = createVM(content: "未保护的输入", draftService: draftService)

        await ctx.vm.generateDraftIfNeeded()

        #expect(ctx.vm.showErrorAlert)
        #expect(ctx.vm.errorMessage == L10n.Errors.tryAgainLater)
    }

    @Test("generateDraftIfNeeded 已保存时不生成草稿")
    func generateDraftIfNeeded_alreadySaved_noDraft() async throws {
        let draftService = CaptureDraftServiceMock()
        let ctx = createVM(content: "已保存", image: createTestImage(), draftService: draftService)
        // 模拟已保存
        ctx.vm.isSaved = true

        await ctx.vm.generateDraftIfNeeded()

        #expect(draftService.hasDraft == false)
    }

    @Test("generateDraftIfNeeded 无内容且无图片时不生成草稿")
    func generateDraftIfNeeded_emptyContentNoImage_noDraft() async throws {
        let draftService = CaptureDraftServiceMock()
        // PR #336 放宽草稿条件：image != nil 即保存（不看 content）
        // 因此测试"不保存"须同时去掉图片
        let ctx = createVM(content: "", image: nil, draftService: draftService)

        await ctx.vm.generateDraftIfNeeded()

        #expect(draftService.hasDraft == false)
    }

    @Test("手动编辑正文后自动 checkpoint")
    func scheduleDraftCheckpoint_manualEdit_savesLatestText() async throws {
        let draftService = CaptureDraftServiceMock()
        let ctx = createVM(content: "", draftService: draftService)
        ctx.vm.content = "手动录入内容"

        ctx.vm.scheduleDraftCheckpoint()

        try await waitUntil("编辑内容写入草稿") { draftService.hasDraft }
        #expect(draftService.storedDraft?.content == "手动录入内容")
    }

    @Test("编辑期自动 checkpoint 失败必须提示用户")
    func scheduleDraftCheckpoint_persistenceFailure_isVisible() async throws {
        let draftService = CaptureDraftServiceMock()
        draftService.saveError = .persistenceFailed
        let ctx = createVM(content: "", draftService: draftService)
        ctx.vm.content = "仍未落盘"

        ctx.vm.scheduleDraftCheckpoint()

        try await waitUntil("草稿落盘失败提示") {
            ctx.vm.showErrorAlert
        }
        #expect(ctx.vm.errorMessage == L10n.Errors.tryAgainLater)
    }

    @Test("已有 generation 首次出现时不重复落盘")
    func generateDraftIfNeeded_existingGeneration_doesNotRewrite() async throws {
        let draftService = CaptureDraftServiceMock(
            initialDraft: CaptureDraft(
                image: nil,
                content: "已有草稿",
                date: Date(),
                category: nil
            )
        )
        let ctx = createVM(content: "已有草稿", draftService: draftService)

        await ctx.vm.generateDraftIfNeeded()

        #expect(draftService.saveCalls.isEmpty)
    }

    // MARK: - handleImageCrop

    @Test("handleImageCrop 更新图片并触发 OCR")
    func handleImageCrop_updatesImageAndTriggersOCR() async throws {
        let mockOCR = MockOCRServiceShared()
        mockOCR.recognizeTextResult = "重新识别文本"
        let router = CaptureRouter()
        let vm = CaptureResultViewModel(
            content: "原始文本",
            image: createTestImage(),
            repositories: repos,
            ocrService: mockOCR,
            analyticsService: AnalyticsServiceMock(),
            contentTaggingService: ContentTaggingServiceMock(),
            router: router,
            draftService: CaptureDraftServiceMock()
        )

        let croppedImage = createTestImage()
        vm.handleImageCrop(croppedImage)

        #expect(vm.isCropping == false)
        // 等 OCR 任务完成：要求 callCount > 0（确保任务跑过）且 isRecognizing == false（确保完成）
        // 避免竞态：isRecognizing 初始值为 false，仅检查 false 会立即返回
        try await waitUntil("OCR 任务完成") { !vm.isRecognizing && mockOCR.recognizeTextCallCount > 0 }
        #expect(vm.content == "重新识别文本")
        #expect(mockOCR.recognizeTextCallCount == 1)
    }

    // MARK: - save 双击防护

    @Test("save 正在保存时第二次调用被忽略（isSaving 防双击）")
    func save_doubleTapGuard() async throws {
        let ctx = createVM(content: "防双击测试")

        // 第一次调用：设置 isSaving = true 并启动 saveTask
        ctx.vm.save()
        #expect(ctx.vm.isSaving == true)

        // 第二次调用：isSaving 为 true，guard 拦截
        ctx.vm.save()

        // 等待保存完成
        try await waitUntil("保存完成") { ctx.vm.isSaving == false }
        #expect(ctx.vm.isSaved == true)

        // 验证只保存了一次（不是两次）
        let items = try ctx.repos.archive.fetchAllModels()
        #expect(items.count == 1)
    }

    @Test("save 成功后再次调用被忽略")
    func save_afterSuccessIgnored() async throws {
        let draft = CaptureDraftService.Draft(
            image: nil,
            content: "保存前草稿",
            date: Date(),
            category: nil
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        let ctx = createVM(content: "保存后幂等测试", draftService: draftService)

        ctx.vm.save()
        try await waitUntil("首次保存完成") { ctx.vm.isSaved && !ctx.vm.isSaving }

        ctx.vm.save()
        try await waitUntil("重复保存调用结束") { !ctx.vm.isSaving }

        #expect(try ctx.repos.archive.totalCount() == 1)
        #expect(draftService.clearCallCount == 1)
    }

    @Test("saveResult 成功后再次调用被忽略")
    func saveResult_afterSuccessIgnored() async throws {
        let draft = CaptureDraftService.Draft(
            image: nil,
            content: "保存前草稿",
            date: Date(),
            category: nil
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        let ctx = createVM(content: "直接保存幂等测试", draftService: draftService)

        await ctx.vm.saveResult()
        await ctx.vm.saveResult()

        #expect(try ctx.repos.archive.totalCount() == 1)
        #expect(draftService.clearCallCount == 1)
    }

    @Test("saveResult 正式保存成功后清除持久草稿")
    func saveResult_successClearsDraft() async throws {
        let draft = CaptureDraftService.Draft(
            image: nil,
            content: "未完成内容",
            date: Date(),
            category: nil
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        let ctx = createVM(content: "正式保存内容", draftService: draftService)

        await ctx.vm.saveResult()

        #expect(ctx.vm.isSaved == true)
        #expect(draftService.hasDraft == false)
        #expect(draftService.clearCallCount == 1)
    }

    @Test("已提交 ID 与恢复后的新编辑冲突时保留草稿且不谎报成功")
    func saveResult_existingArchiveRetainsEditedDraft() async throws {
        let captureID = UUID()
        let draft = CaptureDraft(
            image: nil,
            content: "提交前内容",
            date: Date(),
            category: nil,
            token: CaptureDraftToken(
                captureID: captureID,
                generationID: UUID()
            )
        )
        let draftService = CaptureDraftServiceMock(initialDraft: draft)
        try repos.archive.insertAndSave(
            ArchiveItemModel(id: captureID, content: "已提交内容")
        )
        let ctx = createVM(
            content: "恢复后新编辑",
            draftService: draftService
        )

        await ctx.vm.saveResult()

        #expect(ctx.vm.isSaved == false)
        #expect(ctx.vm.showErrorAlert)
        #expect(try repos.archive.fetchModel(by: captureID)?.content == "已提交内容")
        guard case .recoverable(let remaining) = draftService.state() else {
            Issue.record("冲突的新编辑必须保留为可恢复草稿")
            return
        }
        #expect(remaining.content == "恢复后新编辑")
        #expect(draftService.pendingSettlementToken() == nil)

        CaptureDraftReconciler.reconcile(
            draftService: draftService,
            repositories: repos
        )
        guard case .recoverable(let reconciled) = draftService.state() else {
            Issue.record("没有 settlement 证据时，启动对账不得删除冲突后的新编辑")
            return
        }
        #expect(reconciled.content == "恢复后新编辑")
    }

    @Test("saveResult 保存失败时设置 showErrorAlert 和 errorMessage")
    func saveResult_failure_showsAlert() async throws {
        // 验证路径：文字和图片都为空 → 业务规则抛错 → catch 块执行
        let ctx = createVM(content: "", image: nil)

        await ctx.vm.saveResult()

        #expect(ctx.vm.isSaved == false)
        #expect(ctx.vm.showErrorAlert == true)
        #expect(ctx.vm.errorMessage != nil)
        // 确认没有数据被持久化
        let count = try ctx.repos.archive.totalCount()
        #expect(count == 0)
    }

    // MARK: - cancelTasks

    @Test("cancelTasks 不崩溃")
    func cancelTasks_noCrash() throws {
        let ctx = createVM()
        ctx.vm.cancelTasks()
    }

    // MARK: - 维度值选择（单值替换 / 多值切换）

    /// 一个维度 + 两个值的脚手架（避免 large_tuple）
    private struct SeededDimension {
        let dim: CategoryDimensionModel
        let a: CategoryValueModel
        let b: CategoryValueModel
    }

    /// 在 repos 种一个维度 + 两个值
    private func seedDimension(
        name: String,
        systemKey: String,
        isMultiValue: Bool,
        valueA: String,
        valueB: String
    ) throws -> SeededDimension {
        let dim = CategoryDimensionModel(
            name: name, isMultiValue: isMultiValue, isBuiltIn: true, systemKey: systemKey, sortOrder: 0
        )
        try repos.dimension.insertAndSave(dim)
        let a = CategoryValueModel(name: valueA, sortOrder: 0, dimension: dim)
        let b = CategoryValueModel(name: valueB, sortOrder: 1, dimension: dim)
        try repos.categoryValue.insertAndSave(a)
        try repos.categoryValue.insertAndSave(b)
        return SeededDimension(dim: dim, a: a, b: b)
    }

    @Test("单值维度 toggleValue：选第二个替换第一个，再点取消")
    func toggleValue_singleValue_replaces() throws {
        let seeded = try seedDimension(
            name: "分类", systemKey: CategorySystemKey.category,
            isMultiValue: false, valueA: "数学", valueB: "英语"
        )
        let ctx = createVM(content: "")   // 空内容跳过 AI 标注，避免预选干扰
        ctx.vm.loadFormData()

        ctx.vm.toggleValue(seeded.a.id, inDimension: seeded.dim.id)
        #expect(ctx.vm.selectedIds(forDimension: seeded.dim.id) == [seeded.a.id])

        ctx.vm.toggleValue(seeded.b.id, inDimension: seeded.dim.id)
        #expect(ctx.vm.selectedIds(forDimension: seeded.dim.id) == [seeded.b.id])  // 替换

        ctx.vm.toggleValue(seeded.b.id, inDimension: seeded.dim.id)
        #expect(ctx.vm.selectedIds(forDimension: seeded.dim.id).isEmpty)           // 再点取消
    }

    @Test("多值维度 toggleValue：可叠加，再点移除")
    func toggleValue_multiValue_toggles() throws {
        let seeded = try seedDimension(
            name: "标签", systemKey: CategorySystemKey.tag,
            isMultiValue: true, valueA: "易错", valueB: "重点"
        )
        let ctx = createVM(content: "")
        ctx.vm.loadFormData()

        ctx.vm.toggleValue(seeded.a.id, inDimension: seeded.dim.id)
        ctx.vm.toggleValue(seeded.b.id, inDimension: seeded.dim.id)
        #expect(ctx.vm.selectedIds(forDimension: seeded.dim.id) == [seeded.a.id, seeded.b.id])  // 叠加

        ctx.vm.toggleValue(seeded.a.id, inDimension: seeded.dim.id)
        #expect(ctx.vm.selectedIds(forDimension: seeded.dim.id) == [seeded.b.id])               // 移除 a
    }

    // MARK: - AI 标注回填（动态分类维度，S6-cut 后从写裸字段改为命中维度值选中）

    @Test("AI 标注：建议 category 命中分类维度值则选中")
    func aiTagging_backfillsCategoryOnly() async throws {
        let categoryDim = CategoryDimensionModel(
            name: "分类", isMultiValue: false, isBuiltIn: true,
            systemKey: CategorySystemKey.category, sortOrder: 0
        )
        try repos.dimension.insertAndSave(categoryDim)
        let math = CategoryValueModel(name: "数学", sortOrder: 0, dimension: categoryDim)
        try repos.categoryValue.insertAndSave(math)

        let tagging = ContentTaggingServiceMock()
        tagging.suggestResult = ContentTagSuggestion(category: "数学")
        let vm = CaptureResultViewModel(
            content: "一道关于函数的数学题",   // 非空，触发 AI 标注
            image: nil,
            repositories: repos,
            ocrService: MockOCRServiceShared(),
            analyticsService: AnalyticsServiceMock(),
            contentTaggingService: tagging,
            router: CaptureRouter(),
            draftService: CaptureDraftServiceMock()
        )

        vm.loadFormData()   // 触发异步 AI 标注 Task
        try await waitUntil { vm.selectedIds(forDimension: categoryDim.id).contains(math.id) }

        #expect(vm.selectedIds(forDimension: categoryDim.id) == [math.id])
    }

    // MARK: - 字段配置引导

    // 字段配置引导由 ProfileTipState 管理（per-profile UserDefaults 隔离），
    // ViewModel 通过 showFieldConfigTip / dismissFieldConfigTip() 控制展示。
    // ProfileTipState 的状态依赖 UserDefaults，集成测试在 Profile 切换场景中覆盖。
}
