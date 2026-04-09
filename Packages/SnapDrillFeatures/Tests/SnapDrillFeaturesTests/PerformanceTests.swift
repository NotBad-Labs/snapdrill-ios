//
//  PerformanceTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/04/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  性能基准测试：OCR、题库列表加载、PDF 导出。
//  通过 Xcode Simulator 运行（SPM 仅声明 iOS 平台，swift test 不可用）。
//

import XCTest
import SwiftData
@testable import SnapDrillCore
@testable import SnapDrillData

final class PerformanceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([ReviewItemModel.self, SubjectModel.self, SourceModel.self, GradeModel.self, TagModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    // MARK: - 题库列表加载（目标 < 500ms，200 题）

    func testLibraryListLoad200Items() throws {
        // 填充 200 条测试数据
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

        // 预热（首次查询初始化 SwiftData 内部缓存）
        _ = try repo.fetchFilteredModels(
            searchText: "", subjects: [], tags: [],
            sortDescriptors: [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
            limit: 50, offset: 0
        )

        measure {
            _ = try? repo.fetchFilteredModels(
                searchText: "", subjects: [], tags: [],
                sortDescriptors: [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
                limit: 50, offset: 0
            )
        }
    }

    // MARK: - 搜索响应（目标 < 300ms）

    func testSearchResponse200Items() throws {
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
            searchText: "抛物线", subjects: [], tags: [],
            sortDescriptors: [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
            limit: 50, offset: 0
        )

        measure {
            _ = try? repo.fetchFilteredModels(
                searchText: "抛物线", subjects: [], tags: [],
                sortDescriptors: [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
                limit: 50, offset: 0
            )
        }
    }

    // MARK: - PDF 导出（目标 < 5s，50 题）

    func testPDFExport50Items() async throws {
        var snapshots: [ReviewExportSnapshot] = []
        for i in 0..<50 {
            let item = ReviewItemModel(
                content: "PDF 导出测试题目 \(i)，包含较长的文字内容用于测试渲染性能。这道题考查的是二次函数的基本性质。",
                subject: "数学",
                difficulty: (i % 5) + 1
            )
            snapshots.append(item.toExportSnapshot())
        }

        let service = PDFExportService()

        // 预热
        _ = try await service.createPDF(from: snapshots.prefix(5).map { $0 }) { _ in nil }

        let start = CFAbsoluteTimeGetCurrent()
        _ = try await service.createPDF(from: snapshots) { _ in nil }
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertLessThan(elapsed, 5.0, "PDF 导出 50 题应在 5 秒内完成，实际耗时 \(String(format: "%.2f", elapsed)) 秒")
    }
}
