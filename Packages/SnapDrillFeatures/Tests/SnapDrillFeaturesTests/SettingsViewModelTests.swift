//
//  SettingsViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SettingsViewModel 核心路径单元测试：数据清除与通知。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureSettings
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("SettingsViewModel 数据清除测试", .serialized)
@MainActor
final class SettingsViewModelTests {

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

    // MARK: - clearAllData

    @Test("clearAllData 清空所有题目")
    func clearAllData_removesAllItems() async throws {
        let item1 = ReviewItemModel(content: "题目1")
        let item2 = ReviewItemModel(content: "题目2")
        repos.review.insert(item1)
        repos.review.insert(item2)
        try repos.review.saveContext()

        let vm = SettingsViewModel(repositories: repos)
        await vm.clearAllData()

        let remaining = try repos.review.fetchAllModels()
        #expect(remaining.isEmpty)
    }

    @Test("clearAllData 发送 reviewDataDidChange 通知")
    func clearAllData_postsNotification() async throws {
        let item = ReviewItemModel(content: "题目")
        repos.review.insert(item)
        try repos.review.saveContext()

        let vm = SettingsViewModel(repositories: repos)

        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .reviewDataDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }

        await vm.clearAllData()

        NotificationCenter.default.removeObserver(observer)
        #expect(notificationReceived == true)
    }

    @Test("clearAllData 空数据库不崩溃")
    func clearAllData_emptyDB_noCrash() async {
        let vm = SettingsViewModel(repositories: repos)
        await vm.clearAllData()
    }
}
