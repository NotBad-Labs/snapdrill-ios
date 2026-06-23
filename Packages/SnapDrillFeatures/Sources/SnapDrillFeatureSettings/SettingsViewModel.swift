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

    /// 清空所有资料数据并通知 UI 刷新
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
            repositories.archive.rollbackContext()
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

    /// 从 CSV 文件导入资料数据
    ///
    /// CSV 首行为列名，支持的列：Content, Category, Source, Answer, Level, Tags，以及用户自定义维度。
    /// 列名不区分大小写，缺失列使用默认值。
    /// 内置维度列（Category/Source/Level/Tags）经 systemKey 兜底匹配——跨 locale 命中内置维度、
    /// 不建孤儿重复维度；其余非固定列按显示名匹配现有维度或新建用户维度。
    /// cell 以 ";" 分隔多值；单值维度只取首值。
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

            // 预载现有维度：按小写名 + systemKey 两路索引。
            // systemKey 索引供「文档承诺的英文列名跨 locale 兜底命中内置维度」（不依赖本地化 name）。
            var dimensionsByName: [String: CategoryDimensionModel] = [:]
            var dimensionsBySystemKey: [String: CategoryDimensionModel] = [:]
            for dimension in try repositories.dimension.fetchAllModels() {
                dimensionsByName[dimension.name.lowercased()] = dimension
                if let systemKey = dimension.systemKey {
                    dimensionsBySystemKey[systemKey] = dimension
                }
            }
            let fixedKeys: Set<String> = ["id", "content", "answer", "createdat", "lastreviewed", "nextreview"]
            let context = CSVImportContext(
                fixedKeys: fixedKeys,
                dimensionsBySystemKey: dimensionsBySystemKey,
                multiValueColumns: Self.inferMultiValueColumns(rows: rows, fixedKeys: fixedKeys)
            )

            // 批量创建 ArchiveItemModel（每 50 条 yield 一次，避免长时间阻塞主线程）
            for (index, row) in rows.enumerated() {
                let model = ArchiveItemModel(
                    content: row["content"],
                    answerText: row["answer"]
                )
                repositories.archive.insert(model)
                model.categoryValues = importCategoryValues(from: row, context: context, dimensionsByName: &dimensionsByName)

                backupProgress = Double(index + 1) / Double(rows.count)

                // 每 50 条让出主线程，让 UI 更新进度
                if (index + 1).isMultiple(of: 50) {
                    await Task.yield()
                }
            }

            try repositories.archive.saveContext()

            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            backupStatusMessage = L10n.Settings.importComplete(rows.count)
            SnapDrillLogger.generic.info("CSV 导入完成: \(rows.count) 道题")
        } catch {
            repositories.archive.rollbackContext()
            backupError = L10n.Settings.importFailed
            backupStatusMessage = ""
            SnapDrillLogger.generic.error("CSV 导入失败: \(error)")
        }

        isBackupInProgress = false
    }

    /// CSV 动态维度列导入的只读上下文（避免参数膨胀）。
    private struct CSVImportContext {
        let fixedKeys: Set<String>
        /// systemKey → 内置维度，供英文列名跨 locale 兜底匹配
        let dimensionsBySystemKey: [String: CategoryDimensionModel]
        /// 列内任一 cell 含 ";" 的列（新建维度据此推断 isMultiValue，避免按首行猜错丢数据）
        let multiValueColumns: Set<String>
    }

    /// 文档承诺的内置列名（小写）→ systemKey。CSVParser 已把列头小写化；「Tags」复数也映射到 tag。
    /// 用于显示名匹配失败时兜底命中内置维度，不建孤儿重复维度（修 zh 设备导英文列的 desync）。
    private static let builtInColumnAliases: [String: String] = [
        "category": CategorySystemKey.category,
        "source": CategorySystemKey.source,
        "level": CategorySystemKey.level,
        "tag": CategorySystemKey.tag,
        "tags": CategorySystemKey.tag
    ]

    /// 预扫描所有行：返回任一 cell 含 ";" 的非固定列集合。新建维度据此设 isMultiValue，
    /// 避免按首行单值就把整列定成单值、后续多值 cell 被截断丢数据。
    private static func inferMultiValueColumns(rows: [[String: String]], fixedKeys: Set<String>) -> Set<String> {
        var result: Set<String> = []
        for row in rows {
            for (key, cell) in row where !fixedKeys.contains(key) && cell.contains(";") {
                result.insert(key)
            }
        }
        return result
    }

    /// CSV 动态维度列导入：列名→维度（显示名精确匹配 → systemKey 别名兜底命中内置 → 新建用户维度），
    /// cell 以 ";" 分隔为多值；单值维度强制只收首值。纯内存（由调用方统一 saveContext 原子提交）。
    private func importCategoryValues(
        from row: [String: String],
        context: CSVImportContext,
        dimensionsByName: inout [String: CategoryDimensionModel]
    ) -> [CategoryValueModel] {
        var result: [CategoryValueModel] = []
        for (key, cell) in row where !context.fixedKeys.contains(key) && !cell.isEmpty {
            let dimension = resolveDimension(forColumn: key, context: context, dimensionsByName: &dimensionsByName)
            var valueNames = cell.components(separatedBy: ";")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            // 单值维度强制单值：分号多值场景只取首值（对齐录入表单 toggleValue replace 语义 + §11.4 应用层不变量）
            if !dimension.isMultiValue {
                valueNames = Array(valueNames.prefix(1))
            }
            for name in valueNames {
                result.append(repositories.categoryValue.fetchOrCreate(name: name, in: dimension))
            }
        }
        return result
    }

    /// 解析列名对应的维度：① 显示名精确匹配（最具体）② systemKey 别名命中内置维度 ③ 新建用户维度。
    private func resolveDimension(
        forColumn key: String,
        context: CSVImportContext,
        dimensionsByName: inout [String: CategoryDimensionModel]
    ) -> CategoryDimensionModel {
        if let existing = dimensionsByName[key] {
            return existing
        }
        if let systemKey = Self.builtInColumnAliases[key],
           let builtIn = context.dimensionsBySystemKey[systemKey] {
            dimensionsByName[key] = builtIn   // 缓存别名→维度，同次导入后续行直接命中
            return builtIn
        }
        let created = CategoryDimensionModel(
            name: key, isMultiValue: context.multiValueColumns.contains(key), isBuiltIn: false,
            systemKey: nil, sortOrder: dimensionsByName.count, icon: "tag"
        )
        repositories.dimension.insert(created)
        dimensionsByName[key] = created
        return created
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
