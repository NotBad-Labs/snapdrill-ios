//
//  PerformanceTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  性能基准测试：题库列表加载、搜索、PDF 导出。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillCore
@testable import SnapDrillData

@Suite("性能基准测试", .serialized)
final class PerformanceTests {

    private let container: ModelContainer
    private let context: ModelContext

    init() throws {
        let schema = Schema([ReviewItemModel.self, SubjectModel.self, SourceModel.self, GradeModel.self, TagModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    // MARK: - 题库列表加载（目标 < 500ms，200 题）

    @Test("200 题列表加载 < 500ms")
    func libraryListLoad200Items() throws {
        for i in 0..<200 {
            let item = ReviewItemModel(
                content: "测试题目内容 \(i)，包含一些用于搜索的文字",
                subject: ["数学", "英语", "语文"][i % 3],
                difficulty: (i % 5) + 1
            )
            context.insert(item)
        }
        try context.save()

        let repo = ReviewRepository(modelContext: context)

        // 预热
        _ = try repo.fetchFilteredModels(
            searchText: "", valueIdsByDimension: [:],
            sortDescriptors: [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
            limit: 50, offset: 0
        )

        let start = CFAbsoluteTimeGetCurrent()
        _ = try repo.fetchFilteredModels(
            searchText: "", valueIdsByDimension: [:],
            sortDescriptors: [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
            limit: 50, offset: 0
        )
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        #expect(elapsed < 0.5, "列表加载应在 500ms 内完成，实际 \(String(format: "%.3f", elapsed))s")
    }

    // MARK: - 搜索响应（目标 < 300ms）

    @Test("200 题搜索响应 < 300ms")
    func searchResponse200Items() throws {
        for i in 0..<200 {
            let item = ReviewItemModel(
                content: "这是第 \(i) 道关于抛物线和二次函数的数学题目",
                subject: "数学"
            )
            context.insert(item)
        }
        try context.save()

        let repo = ReviewRepository(modelContext: context)

        // 预热
        _ = try repo.fetchFilteredModels(
            searchText: "抛物线", valueIdsByDimension: [:],
            sortDescriptors: [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
            limit: 50, offset: 0
        )

        let start = CFAbsoluteTimeGetCurrent()
        _ = try repo.fetchFilteredModels(
            searchText: "抛物线", valueIdsByDimension: [:],
            sortDescriptors: [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
            limit: 50, offset: 0
        )
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        #expect(elapsed < 0.3, "搜索应在 300ms 内完成，实际 \(String(format: "%.3f", elapsed))s")
    }

    // MARK: - PDF 导出（目标 < 5s，50 题）

    @Test("50 题 PDF 导出 < 5s")
    func pdfExport50Items() async throws {
        var snapshots: [ReviewExportSnapshot] = []
        for i in 0..<50 {
            let item = ReviewItemModel(
                content: "PDF 导出测试题目 \(i)，包含较长的文字内容用于测试渲染性能。",
                subject: "数学",
                difficulty: (i % 5) + 1
            )
            snapshots.append(item.toExportSnapshot())
        }

        let service = PDFExportService()

        // 预热
        _ = try await service.createPDF(from: Array(snapshots.prefix(5))) { _ in nil }

        let start = CFAbsoluteTimeGetCurrent()
        _ = try await service.createPDF(from: snapshots) { _ in nil }
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        #expect(elapsed < 5.0, "PDF 导出 50 题应在 5 秒内完成，实际 \(String(format: "%.2f", elapsed))s")
    }
}
