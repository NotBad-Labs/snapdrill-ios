//
//  PDFExportServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出服务测试，依赖 UIKit 渲染引擎，仅在 iOS 环境下运行。
//

#if canImport(UIKit)
import Testing
import Foundation
@testable import SnapDrillCore

// MARK: - Test Double

/// PDFExportable mock for test isolation (no SnapDrillDomain dependency in Core tests)
private struct MockPDFItem: PDFExportable {
    var content: String?
    var imagePath: String?
}

struct PDFExportServiceTests {

    // MARK: - Helper Methods

    private func createDummyItems(count: Int) -> [MockPDFItem] {
        return (1...count).map { index in
            MockPDFItem(content: "测试题目 \(index)", imagePath: nil)
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

    // MARK: - Concurrency & Cancellation

    @Test("测试 Task Cooperative Cancellation: 导出大量数据时中途发起取消应该抛出 CancellationError")
    func generationCancellation() async throws {
        let service = PDFExportService.shared
        // 伪造 1000 个超长题库，这会导致耗时的渲染循环
        let heavyItems = createDummyItems(count: 1000)

        let task = Task {
            try await service.createPDF(from: heavyItems) { _ in
                // imageProvider 是同步闭包（(String) -> UIImage?），无法使用 Task.sleep。
                // Thread.sleep 在此处有意为之：模拟每项 50ms 的图片 IO 耗时，
                // 使总工作量（50ms × 1000 = 50s）远超外部 cancel 等待时间，
                // 保证取消测试的确定性。限制为 50ms 以控制对协作线程池的影响。
                Thread.sleep(forTimeInterval: 0.05)
                return nil
            }
        }

        // 让任务先跑一点点
        try await Task.sleep(nanoseconds: 50_000_000)

        // 关键点：发起取消
        task.cancel()

        // 验证任务抛出了期待的结构化取消异常
        do {
            _ = try await task.value
            Issue.record("任务没有正确响应取消，或者执行得太快没拦住。")
        } catch is CancellationError {
            // 正确响应取消
        } catch {
            Issue.record("抛出了非期望的错误类型: \(error)")
        }
    }
}
#endif
