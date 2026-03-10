//
//  LibraryEditViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  LibraryEditViewModel 核心路径单元测试：init 状态映射、save 持久化、图片操作。
//

import Testing
import SwiftData
import Foundation
import UIKit
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("LibraryEditViewModel 编辑与保存测试", .serialized)
@MainActor
final class LibraryEditViewModelTests {

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
        let vm: LibraryEditViewModel
        let repos: RepositoryContainer
        let item: ReviewItemModel
    }

    private func createVM(
        content: String? = "原始题目",
        imagePath: String? = nil,
        answerText: String? = "原始答案",
        subject: String = "数学",
        source: String = "试卷",
        difficulty: Int = 1,
        grade: String = "三年级"
    ) throws -> TestContext {
        try seedDefaultTaxonomy(repos: repos)

        let item = ReviewItemModel(
            content: content,
            imagePath: imagePath,
            subject: subject,
            source: source,
            answerText: answerText,
            difficulty: difficulty,
            grade: grade
        )
        repos.review.insert(item)

        let vm = LibraryEditViewModel(
            item: item,
            repositories: repos,
            ocrService: MockOCRServiceShared()
        )
        return TestContext(vm: vm, repos: repos, item: item)
    }

    // MARK: - init 状态映射

    @Test("init 从 ReviewItemModel 正确映射所有字段")
    func init_mapsAllFields() throws {
        let ctx = try createVM(
            content: "测试内容",
            answerText: "测试答案",
            subject: "英语",
            source: "课本",
            difficulty: 3,
            grade: "五年级"
        )

        #expect(ctx.vm.content == "测试内容")
        #expect(ctx.vm.answer == "测试答案")
        #expect(ctx.vm.selectedSubject == "英语")
        #expect(ctx.vm.selectedSource == "课本")
        #expect(ctx.vm.difficulty == .three)
        #expect(ctx.vm.grade == "五年级")
    }

    @Test("init content 为 nil 时映射为空字符串")
    func init_nilContent_mapsToEmpty() throws {
        let ctx = try createVM(content: nil, answerText: nil)

        #expect(ctx.vm.content == "")
        #expect(ctx.vm.answer == "")
    }

    // MARK: - loadData

    @Test("loadData 加载分类元数据")
    func loadData_loadsTaxonomy() throws {
        let ctx = try createVM()

        ctx.vm.loadData()

        #expect(ctx.vm.subjects.count >= 1)
        #expect(ctx.vm.sources.count >= 1)
        #expect(ctx.vm.grades.count >= 1)
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

    @Test("handleNewAnswerImage 设置图片并清除 cleared 标志")
    func handleNewAnswerImage_setsImageAndClearsFlag() throws {
        let ctx = try createVM()
        ctx.vm.isAnswerImageCleared = true

        let newImage = createTestImage()
        ctx.vm.handleNewAnswerImage(newImage)

        #expect(ctx.vm.answerDisplayedImage != nil)
        #expect(ctx.vm.isAnswerImageCleared == false)
    }

    @Test("handleNewImage 更新显示图片并触发 OCR")
    func handleNewImage_triggersOCR() async throws {
        let mockOCR = MockOCRServiceShared()
        mockOCR.recognizeTextResult = "OCR 新文本"
        try seedDefaultTaxonomy(repos: repos)
        let item = ReviewItemModel(content: "旧文本", subject: "数学")
        repos.review.insert(item)

        let vm = LibraryEditViewModel(item: item, repositories: repos, ocrService: mockOCR)

        vm.handleNewImage(createTestImage())

        #expect(vm.isProcessing == true)
        // 轮询等待 OCR 任务完成（观测 ViewModel 最终状态，而非 Mock 中间状态）
        try await waitUntil { vm.isProcessing == false }
        #expect(vm.content == "OCR 新文本")
        #expect(mockOCR.recognizeTextCallCount == 1)
    }

    // MARK: - save

    @Test("save 更新 @Model 属性")
    func save_updatesModelProperties() async throws {
        let ctx = try createVM()

        ctx.vm.content = "修改后的内容"
        ctx.vm.answer = "修改后的答案"
        ctx.vm.selectedSubject = "英语"
        ctx.vm.difficulty = .four

        await ctx.vm.save()

        #expect(ctx.vm.isSavedNormally == true)
        #expect(ctx.item.content == "修改后的内容")
        #expect(ctx.item.answerText == "修改后的答案")
        #expect(ctx.item.subject == "英语")
        #expect(ctx.item.difficulty == 4)
    }

    @Test("save 同步标签到 @Model")
    func save_syncsTags() async throws {
        let ctx = try createVM()
        ctx.vm.tagList = ["易错", "考前必看"]

        await ctx.vm.save()

        let tagNames = (ctx.item.tags ?? []).map(\.name).sorted()
        #expect(tagNames == ["易错", "考前必看"])
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
