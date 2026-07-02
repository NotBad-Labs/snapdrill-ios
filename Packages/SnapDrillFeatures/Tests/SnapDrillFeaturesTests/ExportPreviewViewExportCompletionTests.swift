//
//  ExportPreviewViewExportCompletionTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ExportPreviewView 的导出完成接线测试。
//
//  不驱动真实 UIPrintInteractionController / UIActivityViewController：
//  系统打印与分享面板仍留真机 dogfood；这里锁定的是 Feature 层
//  “系统回调 completed 后才触发 onExport” 的本地契约。
//

import Testing
import UIKit
import SwiftData
@testable import SnapDrillFeatureLibrary
@testable import SnapDrillData
@testable import SnapDrillCore
@testable import SnapDrillUI

@Suite("ExportPreviewView 导出完成接线测试", .serialized)
@MainActor
struct ExportPreviewViewExportCompletionTests {

    @Test("打印 completed 后 onExport 恰好触发一次")
    func printCompletedTriggersOnExportOnce() async throws {
        let presenter = MockPrintPresenter(result: .success(.completed))
        let outcome = try await presenter.present(
            pdfData: Data([0x25, 0x50, 0x44, 0x46]),
            jobName: "SmartPaper",
            anchor: .view(UIView())
        )

        var callCount = 0
        ExportPreviewView.notifyExportIfPrintCompleted(outcome) {
            callCount += 1
        }

        #expect(presenter.presentCallCount == 1)
        #expect(callCount == 1)
    }

    @Test("打印 cancelled 后 onExport 不触发")
    func printCancelledDoesNotTriggerOnExport() async throws {
        let presenter = MockPrintPresenter(result: .success(.cancelled))
        let outcome = try await presenter.present(
            pdfData: Data([0x25, 0x50, 0x44, 0x46]),
            jobName: "SmartPaper",
            anchor: .view(UIView())
        )

        var callCount = 0
        ExportPreviewView.notifyExportIfPrintCompleted(outcome) {
            callCount += 1
        }

        #expect(presenter.presentCallCount == 1)
        #expect(callCount == 0)
    }

    @Test("打印抛错后没有 outcome，onExport 不触发")
    func printErrorDoesNotTriggerOnExport() async {
        let presenter = MockPrintPresenter(result: .failure(PrintError.presentationFailed))
        var callCount = 0

        await #expect(throws: PrintError.presentationFailed) {
            let outcome = try await presenter.present(
                pdfData: Data([0x25, 0x50, 0x44, 0x46]),
                jobName: "SmartPaper",
                anchor: .view(UIView())
            )
            ExportPreviewView.notifyExportIfPrintCompleted(outcome) {
                callCount += 1
            }
        }

        #expect(presenter.presentCallCount == 1)
        #expect(callCount == 0)
    }

    @Test("SmartPaper 免费流：完成导出扣 1，取消不扣")
    func smartPaperFreeQuotaConsumesOnlyOnCompletedPrint() throws {
        let completedHarness = try makeSmartPaperHarness()
        #expect(completedHarness.vm.prepareGeneration(isProUser: false) == .preview)
        ExportPreviewView.notifyExportIfPrintCompleted(.completed) {
            completedHarness.vm.consumeFreeQuota()
        }
        #expect(completedHarness.vm.freeQuotaUsed == 1)

        let cancelledHarness = try makeSmartPaperHarness()
        #expect(cancelledHarness.vm.prepareGeneration(isProUser: false) == .preview)
        ExportPreviewView.notifyExportIfPrintCompleted(.cancelled) {
            cancelledHarness.vm.consumeFreeQuota()
        }
        #expect(cancelledHarness.vm.freeQuotaUsed == 0)
    }

    private struct SmartPaperHarness {
        let container: ModelContainer
        let vm: SmartPaperViewModel
    }

    private func makeSmartPaperHarness() throws -> SmartPaperHarness {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repos = RepositoryContainer(modelContext: container.mainContext)

        let dimension = CategoryDimensionModel(
            name: "分类",
            isMultiValue: false,
            isBuiltIn: true,
            systemKey: CategorySystemKey.category,
            sortOrder: 0,
            icon: "book"
        )
        try repos.dimension.insertAndSave(dimension)
        let category = CategoryValueModel(name: "资料", sortOrder: 0, dimension: dimension)
        try repos.categoryValue.insertAndSave(category)

        for index in 1...3 {
            let item = ArchiveItemModel(content: "资料 \(index)")
            item.categoryValues = [category]
            repos.archive.insert(item)
        }
        try repos.archive.saveContext()

        let suiteName = "ExportPreviewViewExportCompletionTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let vm = SmartPaperViewModel(repositories: repos, defaults: defaults)
        vm.questionCount = 3
        vm.refreshSelection(isProUser: false)
        return SmartPaperHarness(container: container, vm: vm)
    }
}
