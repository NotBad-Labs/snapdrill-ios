//
//  SettingsViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置页 ViewModel，处理数据清除等操作。
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillData

/// 设置页 ViewModel
///
/// 处理设置页面的数据操作（如清除全部数据、CSV 导入）。
/// 备份 / 恢复的事务编排逻辑已抽到 `SettingsBackupCoordinator`，本 VM 仅做薄包装
/// （管理 activityTracker、安全域访问、isBackupInProgress 与 @Observable 状态回写）。
@MainActor
@Observable
public final class SettingsViewModel {
    private let repositories: RepositoryContainer
    private let profileManager: ProfileManager
    private let backupService = BackupService()
    private let activityTracker: AppActivityTracker

    // MARK: - Properties

    /// 备份/恢复操作进度（0.0 ~ 1.0）
    public var backupProgress: Double = 0
    /// 是否正在执行备份/恢复操作
    public var isBackupInProgress = false
    /// 备份/恢复操作的状态消息
    public var backupStatusMessage = ""
    /// 备份/恢复错误信息
    public var backupError: String?
    /// 备份完成后的文件 URL（用于 ShareLink）
    public var backupFileURL: URL?
    /// 清空数据操作的错误信息
    public var clearError: String?

    // MARK: - Initialization

    /// 创建设置页 ViewModel
    /// - Parameters:
    ///   - repositories: 应用的数据仓库容器
    ///   - profileManager: Profile 管理器（备份恢复需要遍历所有 Profile）。未传入时使用测试用 in-memory 实例
    ///   - activityTracker: 活动追踪器（默认参数缝注入，避免静态单例污染测试）
    public init(
        repositories: RepositoryContainer,
        profileManager: ProfileManager = ProfileManager(inMemory: true),
        activityTracker: AppActivityTracker? = nil
    ) {
        self.repositories = repositories
        self.profileManager = profileManager
        self.activityTracker = activityTracker ?? AppActivityTracker.shared
    }

    // MARK: - Public API

    /// 清空所有题目数据并通知 UI 刷新
    ///
    /// 操作不可撤销，失败时自动回滚 `mainContext` 以防止脏数据。
    public func clearAllData() async {
        clearError = nil
        do {
            try await repositories.deleteAllData()
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            SnapDrillLogger.generic.info("所有数据已清空，已通知 UI 刷新。")
        } catch {
            // deleteAllData 是单次 saveContext 原子操作，失败时其内部已 rollback DB（旧数据完整保留）；
            // 此处 rollback 仅作防御性二次清理，确保本上下文无残留内存脏状态被后续操作意外持久化
            repositories.review.rollbackContext()
            SnapDrillLogger.generic.error("清空数据失败: \(error)")
            clearError = L10n.Settings.clearFailed
        }
    }

    // MARK: - Backup

    /// 创建全量备份文件
    ///
    /// 收集所有数据和图片，打包为 .zip 文件（编排逻辑在 `SettingsBackupCoordinator`）。
    /// 完成后将文件 URL 存入 `backupFileURL`，供 View 层触发分享。
    public func createBackup() async {
        guard !isBackupInProgress else { return }
        activityTracker.begin(.backupRestore)
        defer { activityTracker.end(.backupRestore) }
        isBackupInProgress = true
        defer { isBackupInProgress = false }
        backupProgress = 0
        backupError = nil
        backupFileURL = nil

        var coordinator = makeBackupCoordinator()
        coordinator.onProgress = { [weak self] in self?.backupProgress = $0 }
        coordinator.onStatus = { [weak self] in self?.backupStatusMessage = $0 }

        do {
            backupFileURL = try await coordinator.createBackup()
        } catch {
            backupError = L10n.Errors.backupFailed
            backupStatusMessage = ""
            SnapDrillLogger.generic.error("备份失败: \(error)")
        }
    }

    // MARK: - Restore

    /// 从备份文件恢复数据
    ///
    /// 恢复前先自动备份当前数据（安全网），然后全量替换（编排逻辑在 `SettingsBackupCoordinator`）。
    /// 安全域访问（fileImporter 选择的文件在沙箱外）在本方法处理。
    ///
    /// - Parameter fileURL: 用户选择的 .zip 备份文件路径
    public func restoreFromBackup(fileURL: URL) async {
        guard !isBackupInProgress else { return }
        activityTracker.begin(.backupRestore)
        defer { activityTracker.end(.backupRestore) }
        isBackupInProgress = true
        defer { isBackupInProgress = false }
        backupProgress = 0
        backupError = nil
        backupStatusMessage = L10n.Settings.restoreVerifying

        guard fileURL.startAccessingSecurityScopedResource() else {
            backupError = L10n.Errors.fileAccessDenied
            return
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }

        var coordinator = makeBackupCoordinator()
        coordinator.onProgress = { [weak self] in self?.backupProgress = $0 }
        coordinator.onStatus = { [weak self] in self?.backupStatusMessage = $0 }

        do {
            try await coordinator.restoreFromBackup(fileURL: fileURL)
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            backupStatusMessage = L10n.Settings.restoreComplete
        } catch {
            backupError = L10n.Errors.restoreFailed
            backupStatusMessage = ""
            SnapDrillLogger.generic.error("恢复失败: \(error)")
        }
    }

    /// 清理备份产生的临时文件
    ///
    /// 在 ShareSheet 关闭后调用，删除临时目录中的 .zip 文件。
    public func cleanupBackupFile() {
        guard let url = backupFileURL else { return }
        try? FileManager.default.removeItem(at: url) // best-effort: 临时备份文件残留不影响功能
        backupFileURL = nil
        backupStatusMessage = ""
        SnapDrillLogger.generic.info("已清理备份临时文件: \(url.lastPathComponent)")
    }

    // MARK: - CSV 导入

    /// 从 CSV 文件导入题目数据
    ///
    /// CSV 首行为列名，支持的列：Content, Subject, Source, Difficulty, Answer, Grade, Tags。
    /// 列名不区分大小写，缺失列使用默认值。
    public func importCSV(fileURL: URL) async {
        guard !isBackupInProgress else { return }
        activityTracker.begin(.backupRestore)
        defer { activityTracker.end(.backupRestore) }
        isBackupInProgress = true; backupProgress = 0
        backupError = nil; backupStatusMessage = L10n.Settings.importReading
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer { if accessing { fileURL.stopAccessingSecurityScopedResource() } }

        do {
            let csvString = try String(contentsOf: fileURL, encoding: .utf8)
            backupStatusMessage = L10n.Settings.importParsing

            let rows = CSVParser.parse(csvString)
            guard !rows.isEmpty else {
                backupError = L10n.Settings.importNoValidRows
                isBackupInProgress = false
                backupStatusMessage = ""
                return
            }

            backupStatusMessage = L10n.Settings.importSaving(rows.count)

            // 预载现有维度（按小写名匹配 CSVParser 小写化的列头）；A2 动态列：非固定列即维度
            var dimensionsByName: [String: CategoryDimensionModel] = [:]
            for dimension in try repositories.dimension.fetchAllModels() {
                dimensionsByName[dimension.name.lowercased()] = dimension
            }
            let fixedKeys: Set<String> = ["id", "content", "difficulty", "answer", "createdat", "lastreviewed", "nextreview"]

            // 批量创建 ReviewItemModel（每 50 条 yield 一次，避免长时间阻塞主线程）
            for (index, row) in rows.enumerated() {
                let model = ReviewItemModel(
                    content: row["content"],
                    answerText: row["answer"],
                    difficulty: min(5, max(1, Int(row["difficulty"] ?? "1") ?? 1))
                )
                repositories.review.insert(model)
                model.categoryValues = importCategoryValues(from: row, fixedKeys: fixedKeys, dimensionsByName: &dimensionsByName)

                backupProgress = Double(index + 1) / Double(rows.count)

                // 每 50 条让出主线程，让 UI 更新进度
                if (index + 1).isMultiple(of: 50) {
                    await Task.yield()
                }
            }

            try repositories.review.saveContext()

            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            backupStatusMessage = L10n.Settings.importComplete(rows.count)
            SnapDrillLogger.generic.info("CSV 导入完成: \(rows.count) 道题")
        } catch {
            repositories.review.rollbackContext()
            backupError = L10n.Settings.importFailed
            backupStatusMessage = ""
            SnapDrillLogger.generic.error("CSV 导入失败: \(error)")
        }

        isBackupInProgress = false
    }

    /// CSV 动态维度列导入：非固定列即维度（按列名 fetchOrCreate），cell 以 ";" 分隔为多值。
    /// 维度按列名匹配现有/缓存，无则建用户维度；纯内存（不 save，由调用方统一 saveContext 原子提交）。
    private func importCategoryValues(
        from row: [String: String],
        fixedKeys: Set<String>,
        dimensionsByName: inout [String: CategoryDimensionModel]
    ) -> [CategoryValueModel] {
        var result: [CategoryValueModel] = []
        for (key, cell) in row where !fixedKeys.contains(key) && !cell.isEmpty {
            let dimension: CategoryDimensionModel
            if let existing = dimensionsByName[key] {
                dimension = existing
            } else {
                let created = CategoryDimensionModel(
                    name: key, isMultiValue: false, isBuiltIn: false,
                    systemKey: nil, sortOrder: dimensionsByName.count, icon: "tag"
                )
                repositories.dimension.insert(created)
                dimensionsByName[key] = created
                dimension = created
            }
            let valueNames = cell.components(separatedBy: ";")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            for name in valueNames {
                result.append(repositories.categoryValue.fetchOrCreate(name: name, in: dimension))
            }
        }
        return result
    }

    // CSV 解析已迁移到 `CSVParser.swift`（enum 纯函数，与 ViewModel 状态分离）

    // MARK: - Coordinator Factory

    /// 构造备份 / 恢复编排器（注入 VM 持有的依赖）
    private func makeBackupCoordinator() -> SettingsBackupCoordinator {
        SettingsBackupCoordinator(
            repositories: repositories,
            profileManager: profileManager,
            backupService: backupService
        )
    }
}
