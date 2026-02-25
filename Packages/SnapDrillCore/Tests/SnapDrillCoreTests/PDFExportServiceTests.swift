//
//  PDFExportServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import Testing
import UIKit
@testable import SnapDrillCore

struct PDFExportServiceTests {
    
    // MARK: - Helper Methods
    
    private func createDummyItems(count: Int) -> [ReviewItem] {
        return (1...count).map { index in
            ReviewItem(
                id: UUID(),
                content: "测试题目 \(index)",
                subject: "数学",
                source: "测试",
                difficulty: index % 5 + 1,
                answerText: "答案 \(index)",
                createdAt: Date(),
                lastReviewedAt: nil,
                nextReviewAt: Date()
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

    // MARK: - Concurrency & Cancellation
    
    @Test("测试 Task Cooperative Cancellation: 导出大量数据时中途发起取消应该抛出 CancellationError")
    func generationCancellation() async throws {
        let service = PDFExportService.shared
        // 伪造 1000 个超长题库，这会导致耗时的渲染循环
        let heavyItems = createDummyItems(count: 1000)
        
        let task = Task {
            try await service.createPDF(from: heavyItems) { _ in
                // 模拟图片 IO 或解码耗时
                Thread.sleep(forTimeInterval: 0.05)
                return nil
            }
        }
        
        // 让任务先跑一点点
        try await Task.sleep(nanoseconds: 50_000_000)
        
        // 关键点：发起取销
        task.cancel()
        
        // 验证任务抛出了期待的结构化取消异常
        do {
            _ = try await task.value
            Issue.record("任务没有正确响应取消，或者执行得太快没拦住。")
        } catch is CancellationError {
            // Excellent!
        } catch {
            Issue.record("抛出了非期望的错误类型: \(error)")
        }
    }
}
