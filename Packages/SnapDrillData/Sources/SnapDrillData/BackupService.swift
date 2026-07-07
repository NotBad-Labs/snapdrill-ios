//
//  BackupService.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  备份/恢复服务，将全量数据（JSON + 图片）打包为 .zip 文件。
//

import Foundation
import ZIPFoundation
import SnapDrillCore

/// 备份/恢复服务
///
/// 负责将 SnapDrill 全量数据（题目、分类、图片）打包为 `.zip` 文件，
/// 以及从备份文件中恢复数据。使用流式 ZIP 写入，避免一次性加载所有图片到内存。
public actor BackupService {

    /// 备份进度回调（已处理数 / 总数）
    public typealias ProgressHandler = @Sendable (Int, Int) -> Void

    private struct StagedImageFile {
        let stagedURL: URL
        let destinationURL: URL
    }

    private struct ImageRestoreStageContext {
        let imageEntries: [Entry]
        let archive: Archive
        let profileId: UUID
        let imageBasePath: URL
        let stagingDir: URL
    }

    private struct ExtractedEntryData {
        let data: Data
        let byteCount: Int64
    }

    struct RestoreSizeLimits: Sendable {
        let maxSingleEntryBytes: Int64
        let maxTotalEntryBytes: Int64

        static let production = RestoreSizeLimits(
            maxSingleEntryBytes: 50 * 1024 * 1024,
            maxTotalEntryBytes: 1024 * 1024 * 1024
        )
    }

    private let restoreSizeLimits: RestoreSizeLimits

    // MARK: - Initialization

    public init() {
        self.restoreSizeLimits = .production
    }

    init(restoreSizeLimits: RestoreSizeLimits) {
        self.restoreSizeLimits = restoreSizeLimits
    }

    // MARK: - Export

    /// 创建备份文件
    ///
    /// 将全量数据序列化为 JSON + 图片目录，打包为 ZIP 文件存储到临时目录。
    ///
    /// - Parameters:
    ///   - payload: 所有 Profile 数据的 Codable 快照
    ///   - manifest: 备份元数据清单
    ///   - profileDirectories: 每个 Profile 的图片目录（与 payload.profiles 一一对应）
    ///   - onProgress: 进度回调（当前已处理图片数 / 总图片数）
    /// - Returns: 生成的 .zip 文件 URL（位于临时目录）
    public func createBackup(
        payload: BackupPayload,
        manifest: BackupManifest,
        profileDirectories: [URL],
        onProgress: ProgressHandler? = nil
    ) throws -> URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backupURL = tempDir.appendingPathComponent("SnapDrill_Backup_\(timestamp).zip")

        // 清理可能存在的旧文件
        do {
            try fileManager.removeItem(at: backupURL)
        } catch {
            // 文件不存在是正常的，只记录非 fileNotFound 错误
            if (error as NSError).code != NSFileNoSuchFileError {
                SnapDrillLogger.generic.warning("备份旧文件清理失败: \(error.localizedDescription)")
            }
        }

        // 创建 ZIP 归档
        let archive: Archive
        do {
            archive = try Archive(url: backupURL, accessMode: .create)
        } catch {
            throw BackupError.archiveCreationFailed
        }

        // 1. 写入 manifest.json
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let manifestData = try encoder.encode(manifest)
        try archive.addEntry(
            with: "manifest.json",
            type: .file,
            uncompressedSize: Int64(manifestData.count),
            provider: { position, size in manifestData[Int(position) ..< Int(position) + size] }
        )

        // 2. 写入 data.json
        let payloadData = try encoder.encode(payload)
        try archive.addEntry(
            with: "data.json",
            type: .file,
            uncompressedSize: Int64(payloadData.count),
            provider: { position, size in payloadData[Int(position) ..< Int(position) + size] }
        )

        // 3. 逐个 Profile 写入图片
        try writeProfileImages(
            to: archive, payload: payload,
            profileDirectories: profileDirectories, onProgress: onProgress
        )

        return backupURL
    }

    /// 将各 Profile 的图片写入 ZIP 归档（Store 模式，不压缩——JPEG 已压缩）
    private func writeProfileImages(
        to archive: Archive,
        payload: BackupPayload,
        profileDirectories: [URL],
        onProgress: ProgressHandler?
    ) throws {
        let fileManager = FileManager.default
        var totalImages = 0
        for profileData in payload.profiles {
            for item in profileData.reviewItems {
                if item.imagePath != nil { totalImages += 1 }
                if item.answerImagePath != nil { totalImages += 1 }
            }
        }

        var processedImages = 0
        var lastReportedPercent = -1

        for (profileIndex, profileData) in payload.profiles.enumerated() {
            let imageBasePath = profileIndex < profileDirectories.count
                ? profileDirectories[profileIndex] : profileDirectories[0]

            var imagePaths: [String] = []
            for item in profileData.reviewItems {
                if let path = item.imagePath { imagePaths.append(path) }
                if let path = item.answerImagePath { imagePaths.append(path) }
            }

            let profilePrefix = "profiles/\(profileData.profileId.uuidString)"
            for relativePath in Set(imagePaths) {
                let absoluteURL = imageBasePath.appendingPathComponent(relativePath)
                guard fileManager.fileExists(atPath: absoluteURL.path) else {
                    SnapDrillLogger.generic.warning("备份跳过缺失图片: \(relativePath)")
                    processedImages += 1
                    reportProgress(processedImages, totalImages, lastPercent: &lastReportedPercent, handler: onProgress)
                    continue
                }

                let fileData = try Data(contentsOf: absoluteURL)
                try archive.addEntry(
                    with: "\(profilePrefix)/\(relativePath)",
                    type: .file,
                    uncompressedSize: Int64(fileData.count),
                    compressionMethod: .none,
                    provider: { position, size in fileData[Int(position) ..< Int(position) + size] }
                )
                processedImages += 1
                reportProgress(processedImages, totalImages, lastPercent: &lastReportedPercent, handler: onProgress)
            }
        }
    }

    // MARK: - Import

    /// 读取备份文件的 manifest（用于预检查版本兼容性）
    ///
    /// - Parameter backupURL: .zip 文件路径
    /// - Returns: 备份清单信息
    public func readManifest(from backupURL: URL) throws -> BackupManifest {
        let archive: Archive
        do {
            archive = try Archive(url: backupURL, accessMode: .read)
        } catch {
            throw BackupError.invalidArchive
        }
        guard let manifestEntry = archive["manifest.json"] else {
            throw BackupError.missingManifest
        }

        let manifestData = try extractEntryData(manifestEntry, from: archive).data

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupManifest.self, from: manifestData)
    }

    /// 从备份文件中提取全量数据
    ///
    /// - Parameter backupURL: .zip 文件路径
    /// - Returns: 反序列化的数据载荷
    public func extractPayload(from backupURL: URL) throws -> BackupPayload {
        let archive: Archive
        do {
            archive = try Archive(url: backupURL, accessMode: .read)
        } catch {
            throw BackupError.invalidArchive
        }
        guard let dataEntry = archive["data.json"] else {
            throw BackupError.missingDataFile
        }

        let payloadData = try extractEntryData(dataEntry, from: archive).data

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupPayload.self, from: payloadData)
    }

    /// 从备份文件中恢复指定 Profile 的图片
    ///
    /// - Parameters:
    ///   - backupURL: .zip 文件路径
    ///   - profileId: 要恢复的 Profile ID（对应 ZIP 中 profiles/<id>/ 前缀）
    ///   - imageBasePath: 目标 Profile 的图片目录
    ///   - onProgress: 进度回调（当前已恢复图片数 / 总图片数）
    public func restoreImages(
        from backupURL: URL,
        profileId: UUID,
        to imageBasePath: URL,
        onProgress: ProgressHandler? = nil
    ) throws {
        let archive: Archive
        do {
            archive = try Archive(url: backupURL, accessMode: .read)
        } catch {
            throw BackupError.invalidArchive
        }

        let imageEntries = extractImageEntries(from: archive, profileId: profileId)
        let totalImages = imageEntries.count

        let fileManager = FileManager.default
        let stagingDir = fileManager.temporaryDirectory
            .appendingPathComponent("restore-images-\(UUID().uuidString)", isDirectory: true)
        var lastReportedPercent = -1

        do {
            try fileManager.createDirectory(at: stagingDir, withIntermediateDirectories: true)
            let context = ImageRestoreStageContext(
                imageEntries: imageEntries,
                archive: archive,
                profileId: profileId,
                imageBasePath: imageBasePath,
                stagingDir: stagingDir
            )
            let stagedFiles = try stageImageEntries(
                context,
                lastReportedPercent: &lastReportedPercent,
                onProgress: onProgress
            )
            try commitStagedFiles(stagedFiles, fileManager: fileManager)
        } catch {
            try? fileManager.removeItem(at: stagingDir)
            throw error
        }

        try? fileManager.removeItem(at: stagingDir)
    }
    // MARK: - Private Helpers

    /// 节流进度回调：仅在整数百分比变化时触发，避免高频 MainActor 微任务
    private func reportProgress(_ current: Int, _ total: Int, lastPercent: inout Int, handler: ProgressHandler?) {
        guard let handler else { return }
        let percent = total > 0 ? current * 100 / total : 100
        if percent != lastPercent {
            lastPercent = percent
            handler(current, total)
        }
    }

    private func extractImageEntries(from archive: Archive, profileId: UUID) -> [Entry] {
        let prefix = "profiles/\(profileId.uuidString)/images/"
        return archive.filter { $0.path.hasPrefix(prefix) && $0.type == .file }
    }

    private func stageImageEntries(
        _ context: ImageRestoreStageContext,
        lastReportedPercent: inout Int,
        onProgress: ProgressHandler?
    ) throws -> [StagedImageFile] {
        let fileManager = FileManager.default
        let totalImages = context.imageEntries.count
        let basePath = context.imageBasePath.standardizedFileURL.path + "/"
        let stagingBasePath = context.stagingDir.standardizedFileURL.path + "/"
        let profilePrefix = "profiles/\(context.profileId.uuidString)/"
        var stagedFiles: [StagedImageFile] = []
        var totalRestoredBytes: Int64 = 0

        for (index, entry) in context.imageEntries.enumerated() {
            let relativePath = String(entry.path.dropFirst(profilePrefix.count))
            let pathComponents = relativePath.split(separator: "/")
            let destinationURL = context.imageBasePath.appendingPathComponent(relativePath).standardizedFileURL
            let stagedURL = context.stagingDir.appendingPathComponent(relativePath).standardizedFileURL

            guard !pathComponents.contains(".."),
                  destinationURL.path.hasPrefix(basePath),
                  stagedURL.path.hasPrefix(stagingBasePath) else {
                SnapDrillLogger.generic.warning("跳过可疑路径: \(entry.path)")
                reportProgress(index + 1, totalImages, lastPercent: &lastReportedPercent, handler: onProgress)
                continue
            }

            let restoredBytes = try stageImageEntry(
                entry,
                from: context.archive,
                to: stagedURL,
                fileManager: fileManager,
                totalBytesSoFar: totalRestoredBytes
            )
            totalRestoredBytes += restoredBytes
            stagedFiles.append(StagedImageFile(stagedURL: stagedURL, destinationURL: destinationURL))
            reportProgress(index + 1, totalImages, lastPercent: &lastReportedPercent, handler: onProgress)
        }

        return stagedFiles
    }

    private func stageImageEntry(
        _ entry: Entry,
        from archive: Archive,
        to stagedURL: URL,
        fileManager: FileManager,
        totalBytesSoFar: Int64
    ) throws -> Int64 {
        let stagingParentDir = stagedURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: stagingParentDir.path) {
            try fileManager.createDirectory(at: stagingParentDir, withIntermediateDirectories: true)
        }

        let extracted = try extractEntryData(entry, from: archive, totalBytesSoFar: totalBytesSoFar)
        try extracted.data.write(to: stagedURL)
        return extracted.byteCount
    }

    private func extractEntryData(
        _ entry: Entry,
        from archive: Archive,
        totalBytesSoFar: Int64? = nil
    ) throws -> ExtractedEntryData {
        try validateSingleEntrySize(entry)
        var fileData = Data()
        var extractedBytes: Int64 = 0
        _ = try archive.extract(entry) { data in
            extractedBytes += Int64(data.count)
            guard extractedBytes <= restoreSizeLimits.maxSingleEntryBytes else {
                throw BackupError.archiveEntryTooLarge(
                    path: entry.path,
                    limitBytes: restoreSizeLimits.maxSingleEntryBytes
                )
            }
            if let totalBytesSoFar {
                guard totalBytesSoFar + extractedBytes <= restoreSizeLimits.maxTotalEntryBytes else {
                    throw BackupError.archiveEntryTooLarge(
                        path: entry.path,
                        limitBytes: restoreSizeLimits.maxTotalEntryBytes
                    )
                }
            }
            fileData.append(data)
        }
        return ExtractedEntryData(data: fileData, byteCount: extractedBytes)
    }

    private func validateSingleEntrySize(_ entry: Entry) throws {
        guard Int64(entry.uncompressedSize) <= restoreSizeLimits.maxSingleEntryBytes else {
            throw BackupError.archiveEntryTooLarge(
                path: entry.path,
                limitBytes: restoreSizeLimits.maxSingleEntryBytes
            )
        }
    }

    private func commitStagedFiles(_ stagedFiles: [StagedImageFile], fileManager: FileManager) throws {
        for file in stagedFiles {
            let parentDir = file.destinationURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: parentDir.path) {
                try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
            }

            if fileManager.fileExists(atPath: file.destinationURL.path) {
                _ = try fileManager.replaceItemAt(
                    file.destinationURL,
                    withItemAt: file.stagedURL,
                    backupItemName: nil,
                    options: []
                )
            } else {
                try fileManager.moveItem(at: file.stagedURL, to: file.destinationURL)
            }
        }
    }
}

// MARK: - Errors

/// 备份操作错误
public enum BackupError: LocalizedError {
    /// 无法创建 ZIP 归档
    case archiveCreationFailed
    /// 备份文件格式无效或已损坏
    case invalidArchive
    /// 备份文件中缺少 manifest.json
    case missingManifest
    /// 备份文件中缺少 data.json
    case missingDataFile
    /// 备份文件的 Schema 版本高于当前 App，需要升级
    case schemaVersionTooNew(fileVersion: Int, appVersion: Int)
    /// 磁盘空间不足
    case insufficientDiskSpace
    /// ZIP entry 解压体积超过恢复上限
    case archiveEntryTooLarge(path: String, limitBytes: Int64)

    public var errorDescription: String? {
        switch self {
        case .archiveCreationFailed:
            return L10n.BackupErrors.archiveCreationFailed
        case .invalidArchive:
            return L10n.BackupErrors.invalidArchive
        case .missingManifest:
            return L10n.BackupErrors.missingManifest
        case .missingDataFile:
            return L10n.BackupErrors.missingDataFile
        case .schemaVersionTooNew(let fileVersion, let appVersion):
            return L10n.BackupErrors.schemaVersionTooNew(fileVersion, appVersion)
        case .insufficientDiskSpace:
            return L10n.BackupErrors.insufficientDiskSpace
        case .archiveEntryTooLarge:
            return L10n.BackupErrors.invalidArchive
        }
    }
}
