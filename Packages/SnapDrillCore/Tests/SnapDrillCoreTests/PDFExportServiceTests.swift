//
//  PDFExportServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出服务测试，依赖 UIKit 渲染引擎，仅在 iOS 环境下运行。
//

import Testing
import Foundation
import PDFKit
import CoreImage
import UIKit
@testable import SnapDrillCore

// MARK: - Test Double

/// PDFExportable mock for test isolation (no SnapDrillDomain dependency in Core tests)
private struct MockPDFItem: PDFExportable {
    var content: String?
    var imagePath: String?
    var answerText: String?
    var exportCategory: String?
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
                exportCategory: "数学"
            )
        }
    }

    private func makeSolidImage(color: UIColor) -> UIImage {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        return UIGraphicsImageRenderer(bounds: bounds).image { context in
            color.setFill()
            context.fill(bounds)
        }
    }

    private func render(page: PDFPage) -> UIImage {
        let bounds = page.bounds(for: .mediaBox)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(bounds: bounds, format: format).image { context in
            UIColor.white.setFill()
            context.fill(bounds)
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: bounds.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()
        }
    }

    private func averageLuminance(of image: UIImage) -> Double {
        guard let inputImage = CIImage(image: image),
              let filter = CIFilter(name: "CIAreaAverage") else {
            return 255
        }

        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: inputImage.extent), forKey: kCIInputExtentKey)
        guard let outputImage = filter.outputImage else {
            return 255
        }

        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext().render(
            outputImage,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )
        return (Double(pixel[0]) + Double(pixel[1]) + Double(pixel[2])) / 3
    }

    // MARK: - Normal Generation

    @Test("验证正常的从单条和多条记录生成 PDF")
    func properGeneration() async throws {
        let service = PDFExportService.shared

        await #expect(throws: PDFExportError.emptyInput) {
            try await service.createPDF(from: [], imageProvider: { _ in nil })
        }

        let singleItemData = try await service.createPDF(from: createDummyItems(count: 1), imageProvider: { _ in nil })
        let document = try #require(PDFDocument(data: singleItemData))
        #expect(document.pageCount == 1, "单条资料应直接位于第一页，不生成封面")
        #expect(document.page(at: 0)?.string?.contains("测试题目 1") == true)
    }

    // MARK: - 多页分页

    @Test("5 个 items 跨多页生成 PDF")
    func multiPageGeneration() async throws {
        let service = PDFExportService.shared
        let items = createDummyItems(count: 5)

        let data = try await service.createPDF(from: items, imageProvider: { _ in nil })

        let document = try #require(PDFDocument(data: data))
        #expect(document.pageCount == 3, "5 条资料按每页 2 条应生成 3 个物理页")
        #expect(document.page(at: 0)?.string?.contains("测试题目 1") == true, "第一页必须直接包含资料，不得是封面")
    }

    @Test("图片不可读但文字可读时仅使用文字")
    func imageNotFound_usesTextFallback() async throws {
        let service = PDFExportService.shared
        let items = [MockPDFItem(content: "有图路径但图片不存在", imagePath: "nonexistent/image.jpg")]
        let calls = LockedCounter()

        let data = try await service.createPDF(from: items) { _ in
            calls.increment()
            return nil
        }

        let text = try #require(PDFDocument(data: data)?.string)
        #expect(text.contains("有图路径但图片不存在"))
        #expect(calls.value == 1)
    }

    @Test("空白文字且图片不可读时整体失败")
    func emptyItem_failsClosed() async {
        let service = PDFExportService.shared
        let items = [MockPDFItem(content: " \n ", imagePath: "some/image.jpg")]

        await #expect(throws: PDFExportError.unreadableItem(position: 1)) {
            try await service.createPDF(from: items, imageProvider: { _ in UIImage() })
        }
    }

    @Test("无法保证可读布局的高密度在加载图片前失败")
    func unsupportedItemDensity_failsBeforeImageLoading() async {
        let calls = LockedCounter()
        let items = [MockPDFItem(content: "密度边界", imagePath: "images/item.jpg")]
        let options = PDFExportOptions(itemsPerPage: 100)

        await #expect(throws: PDFExportError.unsupportedItemDensity(itemsPerPage: 100)) {
            try await PDFExportService.shared.createPDF(
                from: items,
                options: options
            ) { _ in
                calls.increment()
                return nil
            }
        }
        #expect(calls.value == 0)
    }

    @Test(
        "1/2/4 密度均精确分页且每条 marker 只出现一次",
        arguments: [1, 2, 4]
    )
    func exactPaginationAndMarkerOrder(itemsPerPage: Int) async throws {
        let markers = ["标记甲", "标记乙", "标记丙", "标记丁", "标记戊"]
        let items = markers.map { MockPDFItem(content: $0, imagePath: nil) }
        let options = PDFExportOptions(
            showBlankAnswerArea: false,
            showHeader: false,
            itemsPerPage: itemsPerPage
        )

        let data = try await PDFExportService.shared.createPDF(
            from: items,
            options: options,
            imageProvider: { _ in nil }
        )
        let document = try #require(PDFDocument(data: data))
        let text = try #require(document.string)

        #expect(document.pageCount == Int(ceil(Double(items.count) / Double(itemsPerPage))))
        #expect(document.page(at: 0)?.string?.contains(markers[0]) == true)

        var searchStart = text.startIndex
        for marker in markers {
            #expect(text.components(separatedBy: marker).count - 1 == 1)
            guard let range = text.range(of: marker, range: searchStart..<text.endIndex) else {
                Issue.record("未按冻结顺序找到 marker: \(marker)")
                return
            }
            searchStart = range.upperBound
        }
    }

    @Test("纯图片条目只加载一次且第一页像素非空")
    func imageOnlyItemLoadsOnceAndRendersNonblankPixels() async throws {
        let source = LockedImageProvider(
            image: makeSolidImage(color: .black),
            removeAfterRead: true
        )
        let item = MockPDFItem(content: nil, imagePath: "images/item.jpg")
        let options = PDFExportOptions(
            showBlankAnswerArea: false,
            showHeader: false,
            itemsPerPage: 1
        )

        let data = try await PDFExportService.shared.createPDF(
            from: [item],
            options: options
        ) { _ in
            source.load()
        }
        let document = try #require(PDFDocument(data: data))
        let page = try #require(document.page(at: 0))
        let renderedPage = render(page: page)

        #expect(source.callCount == 1)
        #expect(source.isAvailable == false, "准备完成后移除源图片不应影响已分离的页载荷")
        #expect(averageLuminance(of: renderedPage) < 230, "纯图片页应包含明显的非白色像素")
    }

    @Test("加载下一页前释放上一页图片")
    func releasesPreviousPageImageBeforeLoadingNextPage() async throws {
        let probe = PageImageLifetimeProbe()
        let items = [
            MockPDFItem(content: nil, imagePath: "images/first.jpg"),
            MockPDFItem(content: nil, imagePath: "images/second.jpg")
        ]
        let options = PDFExportOptions(
            showBlankAnswerArea: false,
            showHeader: false,
            itemsPerPage: 1
        )

        _ = try await PDFExportService.shared.createPDF(
            from: items,
            options: options
        ) { path in
            probe.load(path: path)
        }

        #expect(probe.didReleaseFirstImageBeforeSecondLoad)
    }

    @Test("纯文字、纯图片和图文混合条目均可渲染")
    func textImageAndMixedItemsRender() async throws {
        let source = LockedImageProvider(image: makeSolidImage(color: .black))
        let items = [
            MockPDFItem(content: "纯文字甲", imagePath: nil),
            MockPDFItem(content: nil, imagePath: "images/pure.jpg"),
            MockPDFItem(content: "图文混合乙", imagePath: "images/mixed.jpg")
        ]
        let options = PDFExportOptions(
            showBlankAnswerArea: false,
            showHeader: false,
            itemsPerPage: 2
        )

        let data = try await PDFExportService.shared.createPDF(
            from: items,
            options: options
        ) { _ in
            source.load()
        }
        let document = try #require(PDFDocument(data: data))
        let text = try #require(document.string)

        #expect(document.pageCount == 2)
        #expect(text.contains("纯文字甲"))
        #expect(text.contains("图文混合乙"))
        #expect(source.callCount == 2)
    }

    // MARK: - Concurrency & Cancellation

    // UIGraphicsPDFRenderer.pdfData 是同步渲染，Thread.sleep 在 CI 的协作线程池中
    // 行为不确定（编译器优化、调度器跳过），导致任务在 cancel 前已完成。
    // 本地开发机可通过，CI Mac mini 上不稳定。暂时禁用，待重构为确定性机制后恢复。
    @Test(
        "测试 Task Cooperative Cancellation: 导出大量数据时中途发起取消应该抛出 CancellationError",
        .disabled("CI 环境下时序不稳定，见 PR #597 讨论")
    )
    func generationCancellation() async throws {
        let service = PDFExportService.shared
        let heavyItems = createDummyItems(count: 1000)

        let task = Task {
            try await service.createPDF(from: heavyItems) { _ in
                Thread.sleep(forTimeInterval: 0.05)
                return nil
            }
        }

        try await Task.sleep(for: .milliseconds(200))
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

    @Test("hideAnswers=true 时答案文本不出现在 PDF 内容中（去答案打印硬需求）")
    func hideAnswers_omitsAnswerTextFromPDFContent() async throws {
        let service = PDFExportService.shared
        let items = createItemsWithAnswers(count: 3)  // answerText = "测试答案 N"

        let hideOptions = PDFExportOptions(hideAnswers: true, showBlankAnswerArea: false, showHeader: false)
        let showOptions = PDFExportOptions(hideAnswers: false, showBlankAnswerArea: false, showHeader: false)

        let hiddenData = try await service.createPDF(from: items, options: hideOptions, imageProvider: { _ in nil })
        let shownData = try await service.createPDF(from: items, options: showOptions, imageProvider: { _ in nil })

        // ground truth：直接解析 PDF 文本内容，而非 byte-size 代理
        let hiddenText = try #require(PDFDocument(data: hiddenData)?.string, "应能解析隐藏答案 PDF 的文本")
        let shownText = try #require(PDFDocument(data: shownData)?.string, "应能解析显示答案 PDF 的文本")

        for index in 1...3 {
            let answer = "测试答案 \(index)"
            // shownText 含答案：既验功能、也证明中文文本确实可被提取（否则下方负向断言会假阳性通过）
            #expect(shownText.contains(answer), "显示答案模式应包含答案文本「\(answer)」")
            #expect(!hiddenText.contains(answer), "去答案模式不得泄露答案文本「\(answer)」")
        }
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

    @Test("单一分类页眉正常显示")
    func singleCategoryHeader() async throws {
        let service = PDFExportService.shared
        let items = [
            MockPDFItem(content: "题1", exportCategory: "数学"),
            MockPDFItem(content: "题2", exportCategory: "数学")
        ]

        let category = service.resolveCategory(from: items)
        #expect(category == "数学")
    }

    @Test("混合分类页眉显示综合练习")
    func mixedCategoryHeader() async throws {
        let service = PDFExportService.shared
        let items = [
            MockPDFItem(content: "题1", exportCategory: "数学"),
            MockPDFItem(content: "题2", exportCategory: "语文")
        ]

        let category = service.resolveCategory(from: items)
        // resolveCategory 在多分类时返回 L10n.Export.mixedCategory 的值
        #expect(category.isEmpty == false)
        #expect(category != "数学")
        #expect(category != "语文")
    }
}

nonisolated private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.withLock { count }
    }

    func increment() {
        lock.withLock {
            count += 1
        }
    }
}

nonisolated private final class LockedImageProvider: @unchecked Sendable {
    private let lock = NSLock()
    private var image: UIImage?
    private var calls = 0
    private let removeAfterRead: Bool

    init(image: UIImage, removeAfterRead: Bool = false) {
        self.image = image
        self.removeAfterRead = removeAfterRead
    }

    var callCount: Int {
        lock.withLock { calls }
    }

    var isAvailable: Bool {
        lock.withLock { image != nil }
    }

    func load() -> UIImage? {
        lock.withLock {
            calls += 1
            let loadedImage = image
            if removeAfterRead {
                image = nil
            }
            return loadedImage
        }
    }
}

nonisolated private final class PageImageLifetimeProbe: @unchecked Sendable {
    private let lock = NSLock()
    private weak var firstImage: UIImage?
    private var firstImageReleasedBeforeSecondLoad = false

    var didReleaseFirstImageBeforeSecondLoad: Bool {
        lock.withLock { firstImageReleasedBeforeSecondLoad }
    }

    func load(path: String) -> UIImage? {
        lock.withLock {
            if path.hasSuffix("second.jpg") {
                firstImageReleasedBeforeSecondLoad = firstImage == nil
            }

            let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
            let image = UIGraphicsImageRenderer(bounds: bounds).image { context in
                UIColor.black.setFill()
                context.fill(bounds)
            }
            if path.hasSuffix("first.jpg") {
                firstImage = image
            }
            return image
        }
    }
}
