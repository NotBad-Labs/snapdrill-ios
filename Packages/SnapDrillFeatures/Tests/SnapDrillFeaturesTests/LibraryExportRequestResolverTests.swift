//
//  LibraryExportRequestResolverTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Testing
@testable import SnapDrillFeatureLibrary

struct LibraryExportRequestResolverTests {
    @Test("导出请求冻结完整选择并保持当前可见顺序")
    func freezesCompleteSelectionInVisibleOrder() throws {
        let first = UUID()
        let second = UUID()
        let unselected = UUID()
        var visibleIDs = [unselected, second, first]
        var selectedIDs: Set<UUID> = [first, second]

        let request = try LibraryExportRequest(
            visibleIDs: visibleIDs,
            selectedIDs: selectedIDs
        )

        visibleIDs.removeAll()
        selectedIDs.removeAll()

        #expect(request.orderedIDs == [second, first])
        #expect(request.idSet == [first, second])
    }

    @Test("隐藏或过期的已选 ID 使请求整体失败")
    func rejectsSelectionOutsideVisibleResults() {
        let visible = UUID()
        let stale = UUID()

        #expect(throws: LibraryExportRequestError.selectionChanged) {
            try LibraryExportRequest(
                visibleIDs: [visible],
                selectedIDs: [visible, stale]
            )
        }
    }

    @Test("重复可见 ID 不会被静默去重")
    func rejectsDuplicateRequestIDs() {
        let id = UUID()

        #expect(throws: LibraryExportRequestError.duplicateRequestID) {
            try LibraryExportRequest(
                visibleIDs: [id, id],
                selectedIDs: [id]
            )
        }
    }

    @Test("空选择被防御性拒绝")
    func rejectsEmptySelection() {
        #expect(throws: LibraryExportRequestError.emptySelection) {
            try LibraryExportRequest(visibleIDs: [], selectedIDs: [])
        }
    }

    @Test("仓储返回顺序不影响冻结后的解析顺序")
    func reordersResolvedElementsToFrozenRequest() throws {
        let first = UUID()
        let second = UUID()
        let request = try LibraryExportRequest(
            visibleIDs: [first, second],
            selectedIDs: [first, second]
        )

        let resolved = try request.resolve([
            TestElement(id: second),
            TestElement(id: first)
        ])

        #expect(resolved.map(\.id) == [first, second])
    }

    @Test("缺失、额外或重复解析结果均整体失败")
    func rejectsNonExactResolvedClosure() throws {
        let first = UUID()
        let second = UUID()
        let extra = UUID()
        let request = try LibraryExportRequest(
            visibleIDs: [first, second],
            selectedIDs: [first, second]
        )

        #expect(throws: LibraryExportRequestError.resolvedSelectionMismatch) {
            try request.resolve([TestElement(id: first)])
        }
        #expect(throws: LibraryExportRequestError.resolvedSelectionMismatch) {
            try request.resolve([
                TestElement(id: first),
                TestElement(id: second),
                TestElement(id: extra)
            ])
        }
        #expect(throws: LibraryExportRequestError.duplicateResolvedID) {
            try request.resolve([
                TestElement(id: first),
                TestElement(id: first),
                TestElement(id: second)
            ])
        }
    }
}

private struct TestElement: Identifiable {
    let id: UUID
}
