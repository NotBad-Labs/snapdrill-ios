//
//  PrivacySettingsViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/04/15.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PrivacySettingsViewModel 数据导出逻辑单元测试。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureSettings
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("PrivacySettingsViewModel 导出测试", .serialized)
final class PrivacySettingsViewModelTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer
    private let analytics: AnalyticsServiceMock

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
        analytics = AnalyticsServiceMock()
    }

    private func makeVM() -> PrivacySettingsViewModel {
        PrivacySettingsViewModel(repositories: repos, analyticsService: analytics)
    }

    // MARK: - 初始状态

    @Test("初始状态：isExporting/exportError/exportedFileURL 均为默认值")
    func initialState() {
        let vm = makeVM()
        #expect(vm.isExporting == false)
        #expect(vm.exportError == nil)
        #expect(vm.exportedFileURL == nil)
        #expect(vm.showingShareSheet == false)
    }

    // MARK: - JSON 导出

    @Test("JSON 导出：插入数据后导出成功，文件存在且为有效 JSON")
    func jsonExport_withData_succeeds() async throws {
        let item = ReviewItemModel(content: "JSON 测试题目", subject: "数学", source: "作业")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = makeVM()
        vm.startExport(format: .json)

        try await waitUntilExportDone(vm)
        #expect(vm.exportError == nil)
        #expect(vm.showingShareSheet == true)

        let url = try #require(vm.exportedFileURL)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(json?.count == 1)
        #expect(json?[0]["content"] as? String == "JSON 测试题目")
    }

    // MARK: - CSV 导出

    @Test("CSV 导出：插入数据后导出成功，文件存在且包含列头和数据行")
    func csvExport_withData_succeeds() async throws {
        let item = ReviewItemModel(content: "CSV 测试题目", subject: "英语", source: "试卷")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = makeVM()
        vm.startExport(format: .csv)

        try await waitUntilExportDone(vm)
        #expect(vm.exportError == nil)

        let url = try #require(vm.exportedFileURL)
        defer { try? FileManager.default.removeItem(at: url) }

        let csvString = try String(contentsOf: url, encoding: .utf8)
        let lines = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count >= 2)
    }

    // MARK: - 空数据库

    @Test("空数据库导出：文件有效但无数据行")
    func export_emptyDatabase_producesValidFile() async throws {
        let vm = makeVM()
        vm.startExport(format: .json)

        try await waitUntilExportDone(vm)
        #expect(vm.exportError == nil)

        let url = try #require(vm.exportedFileURL)
        defer { try? FileManager.default.removeItem(at: url) }

        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(json?.isEmpty == true)
    }

    // MARK: - 埋点

    @Test("导出成功后触发 dataExported 埋点")
    func export_tracksAnalytics() async throws {
        let item = ReviewItemModel(content: "埋点测试", subject: "数学")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = makeVM()
        vm.startExport(format: .json)

        try await waitUntilExportDone(vm)

        #expect(analytics.hasTrackedEvent(.dataExported))
        let event = analytics.trackedEvents.first { $0.event == .dataExported }
        #expect(event?.parameters["format"] == "json")
        #expect(event?.parameters["item_count"] == "1")

        if let url = vm.exportedFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - AppActivityTracker 集成

    @Test("导出期间 AppActivityTracker 追踪 .exporting 活动")
    func export_tracksActivity() async throws {
        let vm = makeVM()
        vm.startExport(format: .json)

        // 导出完成后 defer 已执行 end()，活动应清空
        try await waitUntilExportDone(vm)
        #expect(AppActivityTracker.shared.canSwitchProfile == true)
    }

    // MARK: - 任务取消

    @Test("cancelExport 重复调用不崩溃")
    func cancelExport_multipleCalls_noCrash() {
        let vm = makeVM()
        vm.cancelExport()
        vm.cancelExport()
        vm.cancelExport()
    }

    // MARK: - 并发 startExport

    @Test("连续调用 startExport 旧任务被取消，只有最后一次生效")
    func startExport_overridesPrevious() async throws {
        let item = ReviewItemModel(content: "并发测试", subject: "数学")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = makeVM()
        // 连续调用两次，第一次应被取消
        vm.startExport(format: .csv)
        vm.startExport(format: .json)

        try await waitUntilExportDone(vm)

        // 最终结果应是 JSON 格式
        let url = try #require(vm.exportedFileURL)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(url.pathExtension == "json")
    }

    // MARK: - Helpers

    /// 等待导出完成（成功或失败），超时则记录 Issue
    private func waitUntilExportDone(
        _ vm: PrivacySettingsViewModel,
        timeout: Duration = .seconds(5)
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while vm.isExporting || (vm.exportedFileURL == nil && vm.exportError == nil) {
            guard ContinuousClock.now < deadline else {
                Issue.record("waitUntilExportDone 超时：isExporting=\(vm.isExporting), error=\(vm.exportError ?? "nil")")
                return
            }
            try await Task.sleep(for: .milliseconds(50))
        }
    }
}
