//
//  CaptureResultViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
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
        let schema = Schema([
            ReviewItemModel.self,
            TagModel.self,
            SubjectModel.self,
            SourceModel.self,
            GradeModel.self
        ])
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
        image: UIImage? = nil
    ) -> TestContext {
        let analytics = AnalyticsServiceMock()
        let router = CaptureRouter()
        let vm = CaptureResultViewModel(
            content: content,
            image: image,
            repositories: repos,
            ocrService: MockOCRServiceShared(),
            analyticsService: analytics,
            contentTaggingService: ContentTaggingServiceMock(),
            router: router
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

    // MARK: - loadFormData

    @Test("loadFormData 加载分类选项")
    func loadFormData_loadsTaxonomy() throws {
        let ctx = createVM()
        try seedDefaultTaxonomy(repos: ctx.repos)

        ctx.vm.loadFormData()

        #expect(ctx.vm.availableSubjects.count == 1)
        #expect(ctx.vm.availableSources.count == 1)
        #expect(ctx.vm.availableGrades.count == 1)
    }

    // MARK: - confirmNewSubject / Source / Grade

    @Test("confirmNewSubject 创建学科并选中")
    func confirmNewSubject_createsAndSelects() throws {
        let ctx = createVM()
        try seedDefaultTaxonomy(repos: ctx.repos)
        ctx.vm.loadFormData()

        ctx.vm.newSubjectName = "物理"
        ctx.vm.confirmNewSubject()

        #expect(ctx.vm.selectedSubject == "物理")
        #expect(ctx.vm.availableSubjects.contains(where: { $0.name == "物理" }))
    }

    @Test("confirmNewSubject 空名称不创建")
    func confirmNewSubject_emptyName_noOp() throws {
        let ctx = createVM()
        try seedDefaultTaxonomy(repos: ctx.repos)
        ctx.vm.loadFormData()
        let originalCount = ctx.vm.availableSubjects.count

        ctx.vm.newSubjectName = "   "
        ctx.vm.confirmNewSubject()

        #expect(ctx.vm.availableSubjects.count == originalCount)
    }

    @Test("confirmNewSource 创建来源并选中")
    func confirmNewSource_createsAndSelects() throws {
        let ctx = createVM()
        try seedDefaultTaxonomy(repos: ctx.repos)
        ctx.vm.loadFormData()

        ctx.vm.newSourceName = "课本"
        ctx.vm.confirmNewSource()

        #expect(ctx.vm.selectedSource == "课本")
        #expect(ctx.vm.availableSources.contains(where: { $0.name == "课本" }))
    }

    @Test("confirmNewGrade 创建年级并选中")
    func confirmNewGrade_createsAndSelects() throws {
        let ctx = createVM()
        try seedDefaultTaxonomy(repos: ctx.repos)
        ctx.vm.loadFormData()

        ctx.vm.newGradeName = "四年级"
        ctx.vm.confirmNewGrade()

        #expect(ctx.vm.grade == "四年级")
        #expect(ctx.vm.availableGrades.contains(where: { $0.name == "四年级" }))
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
        let items = try ctx.repos.review.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.content == "纯文字题目")
        #expect(ctx.analytics.hasTrackedEvent(.captureSaved))
    }

    @Test("saveResult 纯图片成功保存")
    func saveResult_imageOnly_saves() async throws {
        let ctx = createVM(content: "", image: createTestImage())

        await ctx.vm.saveResult()

        #expect(ctx.vm.isSaved == true)
        let items = try ctx.repos.review.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.content == nil)
        #expect(items.first?.imagePath != nil)
    }

    @Test("saveResult 保存分类信息")
    func saveResult_savesMetadata() async throws {
        let ctx = createVM(content: "有元数据的题目")
        ctx.vm.selectedSubject = "英语"
        ctx.vm.selectedSource = "课本"
        ctx.vm.difficulty = .three
        ctx.vm.grade = "三年级"

        await ctx.vm.saveResult()

        let item = try ctx.repos.review.fetchAllModels().first
        #expect(item?.subject == "英语")
        #expect(item?.source == "课本")
        #expect(item?.difficulty == 3)
        #expect(item?.grade == "三年级")
    }

    @Test("saveResult 保存标签")
    func saveResult_savesTags() async throws {
        let ctx = createVM(content: "有标签的题目")
        ctx.vm.tagList = ["易错", "重点"]

        await ctx.vm.saveResult()

        let item = try ctx.repos.review.fetchAllModels().first
        let tagNames = (item?.tags ?? []).map(\.name).sorted()
        #expect(tagNames == ["易错", "重点"])
    }

    @Test("saveResult 触发埋点和 UserDefaults 偏好持久化")
    func saveResult_tracksAnalyticsAndPreferences() async throws {
        let ctx = createVM(content: "埋点测试")
        ctx.vm.selectedSubject = "物理"
        ctx.vm.selectedSource = "作业"

        await ctx.vm.saveResult()

        #expect(ctx.analytics.hasTrackedEvent(.captureSaved))
        #expect(UserDefaults.standard.string(forKey: UDKey.lastSelectedSubject) == "物理")
        #expect(UserDefaults.standard.string(forKey: UDKey.lastSelectedSource) == "作业")
    }

    // MARK: - generateDraftIfNeeded

    @Test("generateDraftIfNeeded 未保存且有内容时生成草稿")
    func generateDraftIfNeeded_unsavedWithContent_savesDraft() async throws {
        CaptureDraftService.shared.clearDraft()
        let ctx = createVM(content: "草稿内容", image: createTestImage())

        await ctx.vm.generateDraftIfNeeded()

        #expect(CaptureDraftService.shared.hasDraft == true)
        CaptureDraftService.shared.clearDraft()
    }

    @Test("generateDraftIfNeeded 已保存时不生成草稿")
    func generateDraftIfNeeded_alreadySaved_noDraft() async throws {
        CaptureDraftService.shared.clearDraft()
        let ctx = createVM(content: "已保存", image: createTestImage())
        // 模拟已保存
        ctx.vm.isSaved = true

        await ctx.vm.generateDraftIfNeeded()

        #expect(CaptureDraftService.shared.hasDraft == false)
    }

    @Test("generateDraftIfNeeded 无内容且无图片时不生成草稿")
    func generateDraftIfNeeded_emptyContentNoImage_noDraft() async throws {
        CaptureDraftService.shared.clearDraft()
        // PR #336 放宽草稿条件：image != nil 即保存（不看 content）
        // 因此测试"不保存"须同时去掉图片
        let ctx = createVM(content: "", image: nil)

        await ctx.vm.generateDraftIfNeeded()

        #expect(CaptureDraftService.shared.hasDraft == false)
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
            router: router
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
        let items = try ctx.repos.review.fetchAllModels()
        #expect(items.count == 1)
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
        let count = try ctx.repos.review.totalCount()
        #expect(count == 0)
    }

    // MARK: - cancelTasks

    @Test("cancelTasks 不崩溃")
    func cancelTasks_noCrash() throws {
        let ctx = createVM()
        ctx.vm.cancelTasks()
    }

    // MARK: - 字段配置引导

    // 字段配置引导由 ProfileTipState 管理（per-profile UserDefaults 隔离），
    // ViewModel 通过 showFieldConfigTip / dismissFieldConfigTip() 控制展示。
    // ProfileTipState 的状态依赖 UserDefaults，集成测试在 Profile 切换场景中覆盖。
}
