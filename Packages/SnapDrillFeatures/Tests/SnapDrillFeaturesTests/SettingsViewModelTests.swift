//
//  SettingsViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SettingsViewModel 核心路径单元测试：数据清除、备份/恢复状态机、guard 防护。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureSettings
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("SettingsViewModel 测试", .serialized)
@MainActor
final class SettingsViewModelTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer

    init() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
    }

    // MARK: - clearAllData

    @Test("clearAllData 清空所有题目")
    func clearAllData_removesAllItems() async throws {
        let item1 = ArchiveItemModel(content: "题目1")
        let item2 = ArchiveItemModel(content: "题目2")
        repos.archive.insert(item1)
        repos.archive.insert(item2)
        try repos.archive.saveContext()

        let vm = SettingsViewModel(repositories: repos)
        await vm.clearAllData()

        let remaining = try repos.archive.fetchAllModels()
        #expect(remaining.isEmpty)
    }

    @Test("clearAllData 发送 reviewDataDidChange 通知")
    func clearAllData_postsNotification() async throws {
        let item = ArchiveItemModel(content: "题目")
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let vm = SettingsViewModel(repositories: repos)

        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .reviewDataDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        await vm.clearAllData()

        #expect(notificationReceived == true)
    }

    @Test("clearAllData 空数据库不崩溃")
    func clearAllData_emptyDB_noCrash() async {
        let vm = SettingsViewModel(repositories: repos)
        await vm.clearAllData()
    }

    // MARK: - 备份初始状态

    @Test("初始化后备份状态为默认值")
    func init_defaultBackupState() {
        let vm = SettingsViewModel(repositories: repos)

        #expect(vm.isBackupInProgress == false)
        #expect(vm.backupProgress == 0)
        #expect(vm.backupStatusMessage == "")
        #expect(vm.backupError == nil)
        #expect(vm.backupFileURL == nil)
    }

    // MARK: - createBackup 状态

    @Test("createBackup 设置 isBackupInProgress")
    func createBackup_setsInProgress() async {
        let vm = SettingsViewModel(repositories: repos)

        // createBackup 在真实环境下需要文件系统，这里验证状态转换
        await vm.createBackup()

        // 完成后 isBackupInProgress 应恢复为 false
        #expect(vm.isBackupInProgress == false)
    }

    @Test("createBackup 空数据库完成后有状态消息")
    func createBackup_emptyDB_completesWithMessage() async {
        let vm = SettingsViewModel(repositories: repos)
        await vm.createBackup()

        // 空数据库备份应成功或有明确状态
        // backupStatusMessage 或 backupError 至少有一个非空
        let hasStatus = !vm.backupStatusMessage.isEmpty || vm.backupError != nil
        #expect(hasStatus)
    }

    // MARK: - clearAllData 同时清理分类数据

    @Test("clearAllData 同时清空动态维度与值")
    func clearAllData_alsoRemovesTaxonomy() async throws {
        let dimension = CategoryDimensionModel(
            name: "分类", isMultiValue: false, isBuiltIn: true,
            systemKey: CategorySystemKey.category, sortOrder: 0, icon: "book"
        )
        try repos.dimension.insertAndSave(dimension)
        try repos.categoryValue.insertAndSave(CategoryValueModel(name: "数学", dimension: dimension))

        let vm = SettingsViewModel(repositories: repos)
        await vm.clearAllData()

        #expect(try repos.dimension.totalCount() == 0)
    }

    // MARK: - createBackup 完整路径

    @Test("createBackup 有数据时生成 backupFileURL")
    func createBackup_withData_producesFileURL() async throws {
        // 插入测试数据
        let item = ArchiveItemModel(content: "备份测试题目")
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let vm = SettingsViewModel(repositories: repos)
        await vm.createBackup()

        #expect(vm.backupFileURL != nil)
        #expect(vm.backupError == nil)
        #expect(vm.isBackupInProgress == false)
        #expect(vm.backupStatusMessage == "备份完成")

        // 清理临时文件
        if let url = vm.backupFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    @Test("createBackup 空数据库也能成功")
    func createBackup_emptyDB_succeeds() async {
        let vm = SettingsViewModel(repositories: repos)
        await vm.createBackup()

        // 空数据备份应成功（生成含空 payload 的 ZIP）
        #expect(vm.backupFileURL != nil)
        #expect(vm.backupError == nil)
        #expect(vm.isBackupInProgress == false)

        // 清理临时文件
        if let url = vm.backupFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    @Test("createBackup 完成后 isBackupInProgress 恢复为 false")
    func createBackup_resetsInProgressAfterCompletion() async throws {
        let item = ArchiveItemModel(content: "题目")
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let vm = SettingsViewModel(repositories: repos)
        await vm.createBackup()

        #expect(vm.isBackupInProgress == false)

        // 清理
        if let url = vm.backupFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - restoreFromBackup 完整路径

    @Test("restoreFromBackup 正常路径：round-trip 恢复")
    func restoreFromBackup_roundTrip() async throws {
        // 1. 准备原始数据——使用非默认 SM-2 值，区分"正确恢复"和"默认值重建"
        let categoryDim = CategoryDimensionModel(
            name: "分类", isMultiValue: false, isBuiltIn: true,
            systemKey: CategorySystemKey.category, sortOrder: 0, icon: "book"
        )
        try repos.dimension.insertAndSave(categoryDim)
        let english = CategoryValueModel(name: "英语", dimension: categoryDim)
        try repos.categoryValue.insertAndSave(english)
        let item = ArchiveItemModel(content: "恢复测试题目")
        item.categoryValues = [english]
        item.easeFactor = 1.8
        item.interval = 7
        item.repetitions = 3
        item.nextReviewAt = Date(timeIntervalSinceReferenceDate: 800_000_000)
        repos.archive.insert(item)
        try repos.archive.saveContext()

        // 2. 创建备份
        let vm = SettingsViewModel(repositories: repos)
        await vm.createBackup()
        guard let backupURL = vm.backupFileURL else {
            Issue.record("备份文件 URL 为 nil")
            return
        }
        defer { try? FileManager.default.removeItem(at: backupURL) }

        // 3. 清空数据
        await vm.clearAllData()
        let countAfterClear = try repos.archive.totalCount()
        #expect(countAfterClear == 0)

        // 4. 从备份恢复
        await vm.restoreFromBackup(fileURL: backupURL)

        // 5. 验证恢复结果——数量、内容字段、SM-2 调度字段均完整
        #expect(vm.backupError == nil)
        #expect(vm.isBackupInProgress == false)
        let restoredItems = try repos.archive.fetchAllModels()
        #expect(restoredItems.count == 1)
        let restored = restoredItems.first
        #expect(restored?.content == "恢复测试题目")
        #expect(restored?.categoryValues?.first?.name == "英语")
        #expect(restored?.easeFactor == 1.8)
        #expect(restored?.interval == 7)
        #expect(restored?.repetitions == 3)
    }

    @Test("restoreFromBackup 成功后发送 reviewDataDidChange 通知")
    func restoreFromBackup_postsNotification() async throws {
        // 准备备份文件
        let item = ArchiveItemModel(content: "通知测试")
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let vm = SettingsViewModel(repositories: repos)
        await vm.createBackup()
        guard let backupURL = vm.backupFileURL else {
            Issue.record("备份文件 URL 为 nil")
            return
        }
        defer { try? FileManager.default.removeItem(at: backupURL) }

        // 清空后恢复，监听通知
        await vm.clearAllData()

        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .reviewDataDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        await vm.restoreFromBackup(fileURL: backupURL)

        #expect(notificationReceived == true)
    }

    @Test("restoreFromBackup 完成后 isBackupInProgress 恢复为 false")
    func restoreFromBackup_resetsInProgressAfterCompletion() async throws {
        let item = ArchiveItemModel(content: "题目")
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let vm = SettingsViewModel(repositories: repos)
        await vm.createBackup()
        guard let backupURL = vm.backupFileURL else {
            Issue.record("备份文件 URL 为 nil")
            return
        }
        defer { try? FileManager.default.removeItem(at: backupURL) }

        await vm.restoreFromBackup(fileURL: backupURL)

        #expect(vm.isBackupInProgress == false)
    }

    @Test("restore 明确拒绝已退休的 schema v2")
    func restore_rejectsRetiredSchemaV2() async throws {
        let manifest = BackupManifest(
            schemaVersion: 2,
            createdAt: Date(timeIntervalSince1970: 0),
            appVersion: "test",
            totalItemCount: 0
        )
        let payload = BackupPayload(reviewItems: [], dimensions: [], categoryValues: [])
        let archiveURL = try makeArchive(manifest: manifest, payload: payload)
        defer { try? FileManager.default.removeItem(at: archiveURL) }

        let coordinator = SettingsBackupCoordinator(
            repositories: repos,
            backupService: BackupService()
        )
        do {
            try await coordinator.restoreFromBackup(fileURL: archiveURL)
            Issue.record("Retired schema v2 should be rejected before restore")
        } catch BackupError.unsupportedSchemaVersion(let fileVersion, let appVersion) {
            #expect(fileVersion == 2)
            #expect(appVersion == BackupManifest.currentSchemaVersion)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("图片恢复失败时 taxonomy-only 资料库也从自动备份回滚")
    func restore_imageFailureRollsBackTaxonomyOnlyLibrary() async throws {
        let dimension = CategoryDimensionModel(
            name: "保留分类",
            isMultiValue: false,
            isBuiltIn: false,
            systemKey: nil,
            sortOrder: 0,
            icon: "folder"
        )
        try repos.dimension.insertAndSave(dimension)

        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSince1970: 0),
            appVersion: "test",
            totalItemCount: 1
        )
        let payload = BackupPayload(
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: UUID(), content: "冲突图片", imagePath: "images/conflict",
                    createdAt: Date(), lastReviewedAt: .distantPast, nextReviewAt: .distantPast,
                    answerText: nil, answerImagePath: "images/conflict/child.jpg",
                    easeFactor: 2.5, interval: 0, repetitions: 0, categoryValueIds: []
                )
            ],
            dimensions: [],
            categoryValues: []
        )
        let archiveURL = try makeArchive(
            manifest: manifest,
            payload: payload,
            additionalEntries: [
                ZIPEntry(path: "images/conflict", data: Data("file".utf8)),
                ZIPEntry(path: "images/conflict/child.jpg", data: Data("child".utf8))
            ]
        )
        defer { try? FileManager.default.removeItem(at: archiveURL) }

        let coordinator = SettingsBackupCoordinator(
            repositories: repos,
            backupService: BackupService()
        )
        await #expect(throws: (any Error).self) {
            try await coordinator.restoreFromBackup(fileURL: archiveURL)
        }

        let restoredDimensions = try repos.dimension.fetchAllModels()
        #expect(restoredDimensions.contains { $0.name == "保留分类" })
        #expect(try repos.archive.totalCount() == 0)
    }

    @Test("当前资料库已缺图时仍可从完整备份恢复")
    func restore_damagedCurrentLibraryDoesNotDeadlock() async throws {
        let damagedItem = ArchiveItemModel(
            content: "当前损坏资料",
            imagePath: "images/missing.jpg"
        )
        repos.archive.insert(damagedItem)
        try repos.archive.saveContext()

        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSince1970: 0),
            appVersion: "test",
            totalItemCount: 0
        )
        let archiveURL = try makeArchive(
            manifest: manifest,
            payload: BackupPayload(reviewItems: [], dimensions: [], categoryValues: [])
        )
        defer { try? FileManager.default.removeItem(at: archiveURL) }

        let coordinator = SettingsBackupCoordinator(
            repositories: repos,
            backupService: BackupService()
        )
        try await coordinator.restoreFromBackup(fileURL: archiveURL)

        #expect(try repos.archive.totalCount() == 0)
    }

    @Test("输入备份只读校验失败时不创建安全网或改写资料库")
    func restore_preflightFailureDoesNotMutateLibrary() async throws {
        let currentItem = ArchiveItemModel(content: "保留当前资料")
        repos.archive.insert(currentItem)
        try repos.archive.saveContext()

        let payload = BackupPayload(
            reviewItems: [
                ArchiveItemBackupDTO(
                    id: UUID(), content: "缺图备份", imagePath: "images/missing.jpg",
                    createdAt: Date(), lastReviewedAt: .distantPast, nextReviewAt: .distantPast,
                    answerText: nil, answerImagePath: nil,
                    easeFactor: 2.5, interval: 0, repetitions: 0, categoryValueIds: []
                )
            ],
            dimensions: [],
            categoryValues: []
        )
        let manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion,
            createdAt: Date(timeIntervalSince1970: 0),
            appVersion: "test",
            totalItemCount: 1
        )
        let archiveURL = try makeArchive(manifest: manifest, payload: payload)
        defer { try? FileManager.default.removeItem(at: archiveURL) }

        let recoveryDirectory = repos.libraryDirectory.appendingPathComponent("Recovery")
        let coordinator = SettingsBackupCoordinator(
            repositories: repos,
            backupService: BackupService()
        )
        await #expect(throws: BackupError.self) {
            try await coordinator.restoreFromBackup(fileURL: archiveURL)
        }

        let remaining = try repos.archive.fetchAllModels()
        #expect(remaining.count == 1)
        #expect(remaining.first?.content == "保留当前资料")
        #expect(!FileManager.default.fileExists(atPath: recoveryDirectory.path))
    }

    // MARK: - cleanupBackupFile

    @Test("cleanupBackupFile 清理后 backupFileURL 为 nil")
    func cleanupBackupFile_clearsURL() async throws {
        let item = ArchiveItemModel(content: "题目")
        repos.archive.insert(item)
        try repos.archive.saveContext()

        let vm = SettingsViewModel(repositories: repos)
        await vm.createBackup()
        #expect(vm.backupFileURL != nil)

        vm.cleanupBackupFile()

        #expect(vm.backupFileURL == nil)
        #expect(vm.backupStatusMessage == "")
    }

    @Test("cleanupBackupFile 无文件时不崩溃")
    func cleanupBackupFile_noFile_noCrash() {
        let vm = SettingsViewModel(repositories: repos)
        #expect(vm.backupFileURL == nil)

        // 不应崩溃
        vm.cleanupBackupFile()

        #expect(vm.backupFileURL == nil)
    }

    private func makeArchive(
        manifest: BackupManifest,
        payload: BackupPayload,
        additionalEntries: [ZIPEntry] = []
    ) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let archiveURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingsRestore_\(UUID().uuidString).zip")
        try ZIPArchiver().createArchive(
            entries: [
                ZIPEntry(path: "manifest.json", data: try encoder.encode(manifest)),
                ZIPEntry(path: "data.json", data: try encoder.encode(payload))
            ] + additionalEntries,
            at: archiveURL
        )
        return archiveURL
    }

}
