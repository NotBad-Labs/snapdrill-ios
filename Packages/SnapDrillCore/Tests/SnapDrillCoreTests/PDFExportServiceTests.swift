//
//  PDFExportServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出服务测试，依赖 UIKit 渲染引擎，仅在 iOS 环境下运行。
//

import Testing
import Foundation
@testable import SnapDrillCore

// MARK: - Test Double

/// PDFExportable mock for test isolation (no SnapDrillDomain dependency in Core tests)
private struct MockPDFItem: PDFExportable {
    var content: String?
    var imagePath: String?
    var answerText: String?
    var exportSubject: String?
}

struct PDFExportServiceTests {

    // MARK: - Helper Methods

    private func createDummyItems(count: Int) -> [MockPDFItem] {
        return (1...count).map { index in
            MockPDFItem(content: "测试题目 \(index)", imagePath: nil)
        }
    }

    private func createItemsWithAnswers(count: Int) -> [MockPDFItem] {
        return (1...count).map { index in
            MockPDFItem(
                content: "测试题目 \(index)",
                imagePath: nil,
                answerText: "测试答案 \(index)",
                exportSubject: "数学"
            )
        }
    }

    // MARK: - Normal Generation

    @Test("验证正常的从单条和多条记录生成 PDF")
    func properGeneration() async throws {
        let service = PDFExportService.shared

        let emptyData = try await service.createPDF(from: [], imageProvider: { _ in nil })
        #expect(emptyData.isEmpty == false, "至少要生成标题页")

        let singleItemData = try await service.createPDF(from: createDummyItems(count: 1), imageProvider: { _ in nil })
        #expect(singleItemData.count > emptyData.count, "多一个项目的 PDF 应该更大")
    }

    // MARK: - 多页分页

    @Test("5 个 items 跨多页生成 PDF")
    func multiPageGeneration() async throws {
        let service = PDFExportService.shared
        let items = createDummyItems(count: 5)

        let data = try await service.createPDF(from: items, imageProvider: { _ in nil })

        // 5 items 应触发多页渲染（2 items/page + 1 标题页）
        // 此处验证产出数据量显著大于单 item
        let singleItemData = try await service.createPDF(from: createDummyItems(count: 1), imageProvider: { _ in nil })
        #expect(data.count > singleItemData.count)
    }

    @Test("imageProvider 返回 nil 时不崩溃")
    func imageNotFound_noCrash() async throws {
        let service = PDFExportService.shared
        let items = [MockPDFItem(content: "有图路径但图片不存在", imagePath: "nonexistent/image.jpg")]

        let data = try await service.createPDF(from: items, imageProvider: { _ in nil })

        #expect(data.isEmpty == false)
    }

    @Test("content 和 image 均为空的题目不崩溃")
    func emptyItem_noCrash() async throws {
        let service = PDFExportService.shared
        let items = [MockPDFItem(content: nil, imagePath: "some/image.jpg")]

        // content 为 nil 且 imageProvider 返回 nil——验证空白题目不崩溃
        let data = try await service.createPDF(from: items, imageProvider: { _ in nil })

        #expect(data.isEmpty == false)
    }

    // MARK: - Concurrency & Cancellation

    @Test("测试 Task Cooperative Cancellation: 导出大量数据时中途发起取消应该抛出 CancellationError")
    func generationCancellation() async throws {
        let service = PDFExportService.shared
        // 100 项 * 10ms = 1s 总工作量，足够验证取消但不阻塞 CI
        let heavyItems = createDummyItems(count: 100)

        let task = Task {
            try await service.createPDF(from: heavyItems) { _ in
                Thread.sleep(forTimeInterval: 0.01)
                return nil
            }
        }

        // 让任务先跑一点点
        try await Task.sleep(for: .milliseconds(50))

        task.cancel()

        do {
            _ = try await task.value
            Issue.record("任务没有正确响应取消，或者执行得太快没拦住。")
        } catch is CancellationError {
            // 正确响应取消
        } catch {
            Issue.record("抛出了非期望的错误类型: \(error)")
        }
    }

    // MARK: - 导出选项测试

    @Test("向后兼容：不传 options 仍能正常生成 PDF")
    func backwardCompatibility() async throws {
        let service = PDFExportService.shared
        let items = createDummyItems(count: 2)

        // 不传 options 参数（使用默认值）
        let data = try await service.createPDF(from: items, imageProvider: { _ in nil })
        #expect(data.isEmpty == false)
    }

    @Test("显示答案 vs 隐藏答案产生不同大小的 PDF")
    func showAnswersVsHideAnswers() async throws {
        let service = PDFExportService.shared
        let items = createItemsWithAnswers(count: 3)

        let hideOptions = PDFExportOptions(hideAnswers: true, showBlankAnswerArea: false, showHeader: false)
        let showOptions = PDFExportOptions(hideAnswers: false, showBlankAnswerArea: false, showHeader: false)

        let hiddenData = try await service.createPDF(from: items, options: hideOptions, imageProvider: { _ in nil })
        let shownData = try await service.createPDF(from: items, options: showOptions, imageProvider: { _ in nil })

        // 显示答案的 PDF 应该比隐藏答案的更大（包含更多渲染内容）
        #expect(shownData.count > hiddenData.count)
    }

    @Test("answerText 为 nil 时显示答案不崩溃")
    func showAnswersWithNilAnswer() async throws {
        let service = PDFExportService.shared
        let items = [MockPDFItem(content: "无答案的题目", imagePath: nil, answerText: nil)]
        let options = PDFExportOptions(hideAnswers: false, showBlankAnswerArea: false, showHeader: true)

        let data = try await service.createPDF(from: items, options: options, imageProvider: { _ in nil })
        #expect(data.isEmpty == false)
    }

    @Test("留白答题区正常生成 PDF")
    func blankAnswerArea() async throws {
        let service = PDFExportService.shared
        let items = createDummyItems(count: 3)
        let options = PDFExportOptions(hideAnswers: true, showBlankAnswerArea: true, showHeader: true)

        let data = try await service.createPDF(from: items, options: options, imageProvider: { _ in nil })
        #expect(data.isEmpty == false)
    }

    @Test("单一学科页眉正常显示")
    func singleSubjectHeader() async throws {
        let service = PDFExportService.shared
        let items = [
            MockPDFItem(content: "题1", exportSubject: "数学"),
            MockPDFItem(content: "题2", exportSubject: "数学")
        ]

        let subject = service.resolveSubject(from: items)
        #expect(subject == "数学")
    }

    @Test("混合学科页眉显示综合练习")
    func mixedSubjectHeader() async throws {
        let service = PDFExportService.shared
        let items = [
            MockPDFItem(content: "题1", exportSubject: "数学"),
            MockPDFItem(content: "题2", exportSubject: "语文")
        ]

        let subject = service.resolveSubject(from: items)
        // resolveSubject 在多学科时返回 L10n.Export.mixedSubject 的值
        #expect(subject.isEmpty == false)
        #expect(subject != "数学")
        #expect(subject != "语文")
    }
}
