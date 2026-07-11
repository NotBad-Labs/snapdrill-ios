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
        let relativePath: String
        let stagedURL: URL
        let destinationURL: URL
    }

    private struct ImageRestoreStageContext {
        let imageEntries: [Entry]
        let archive: Archive
        let libraryDirectory: URL
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
    ///   - payload: 唯一资料库的 Codable 快照
    ///   - manifest: 备份元数据清单
    ///   - libraryDirectory: 唯一资料库根目录
    ///   - onProgress: 进度回调（当前已处理图片数 / 总图片数）
    /// - Returns: 生成的 .zip 文件 URL（位于临时目录）
    public func createBackup(
        payload: BackupPayload,
        manifest: BackupManifest,
        libraryDirectory: URL,
        allowsMissingImages: Bool = false,
        onProgress: ProgressHandler? = nil
    ) throws -> URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backupURL = tempDir.appendingPathComponent(
            "SnapDrill_Backup_\(timestamp)_\(UUID().uuidString).zip"
        )
        var completed = false
        defer {
            if !completed {
                try? fileManager.removeItem(at: backupURL)
            }
        }

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

        // 3. 写入图片
        try writeImages(
            to: archive,
            payload: payload,
            libraryDirectory: libraryDirectory,
            allowsMissingImages: allowsMissingImages,
            onProgress: onProgress
        )

        completed = true
        return backupURL
    }

    /// 将图片写入 ZIP 归档（Store 模式，不压缩——JPEG 已压缩）
    private func writeImages(
        to archive: Archive,
        payload: BackupPayload,
        libraryDirectory: URL,
        allowsMissingImages: Bool,
        onProgress: ProgressHandler?
    ) throws {
        let fileManager = FileManager.default
        let imagePaths = Set(payload.reviewItems.flatMap { item in
            [item.imagePath, item.answerImagePath].compactMap { $0 }
        })
        let totalImages = imagePaths.count
        var processedImages = 0
        var lastReportedPercent = -1

        for relativePath in imagePaths {
            guard ImageStorage.isSafeRelativeImagePath(relativePath) else {
                if allowsMissingImages {
                    SnapDrillLogger.generic.warning("安全网备份跳过非法图片路径: \(relativePath)")
                    processedImages += 1
                    reportProgress(processedImages, totalImages, lastPercent: &lastReportedPercent, handler: onProgress)
                    continue
                }
                SnapDrillLogger.generic.error("备份包含非法图片路径: \(relativePath)")
                throw BackupError.archiveCreationFailed
            }
            let absoluteURL = libraryDirectory.appendingPathComponent(relativePath)
            guard fileManager.fileExists(atPath: absoluteURL.path) else {
                if allowsMissingImages {
                    SnapDrillLogger.generic.warning("安全网备份跳过缺失图片: \(relativePath)")
                    processedImages += 1
                    reportProgress(processedImages, totalImages, lastPercent: &lastReportedPercent, handler: onProgress)
                    continue
                }
                SnapDrillLogger.generic.error("备份缺失数据库引用的图片: \(relativePath)")
                throw BackupError.archiveCreationFailed
            }

            let fileData = try Data(contentsOf: absoluteURL)
            try archive.addEntry(
                with: relativePath,
                type: .file,
                uncompressedSize: Int64(fileData.count),
                compressionMethod: .none,
                provider: { position, size in fileData[Int(position) ..< Int(position) + size] }
            )
            processedImages += 1
            reportProgress(processedImages, totalImages, lastPercent: &lastReportedPercent, handler: onProgress)
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

    /// 从备份文件中恢复图片
    ///
    /// - Parameters:
    ///   - backupURL: .zip 文件路径
    ///   - libraryDirectory: 目标资料库根目录
    ///   - onProgress: 进度回调（当前已恢复图片数 / 总图片数）
    public func validateImages(in backupURL: URL, expectedPaths: Set<String>) throws {
        let archive: Archive
        do {
            archive = try Archive(url: backupURL, accessMode: .read)
        } catch {
            throw BackupError.invalidArchive
        }
        _ = try validatedImageEntries(from: archive, expectedPaths: expectedPaths)
    }

    @discardableResult
    public func restoreImages(
        from backupURL: URL,
        to libraryDirectory: URL,
        expectedPaths: Set<String>? = nil,
        onProgress: ProgressHandler? = nil
    ) throws -> Set<String> {
        let archive: Archive
        do {
            archive = try Archive(url: backupURL, accessMode: .read)
        } catch {
            throw BackupError.invalidArchive
        }

        let imageEntries = try validatedImageEntries(from: archive, expectedPaths: expectedPaths)
        let fileManager = FileManager.default
        let stagingDir = fileManager.temporaryDirectory
            .appendingPathComponent("restore-images-\(UUID().uuidString)", isDirectory: true)
        var lastReportedPercent = -1

        do {
            try fileManager.createDirectory(at: stagingDir, withIntermediateDirectories: true)
            let context = ImageRestoreStageContext(
                imageEntries: imageEntries,
                archive: archive,
                libraryDirectory: libraryDirectory,
                stagingDir: stagingDir
            )
            let stagedFiles = try stageImageEntries(
                context,
                lastReportedPercent: &lastReportedPercent,
                onProgress: onProgress
            )
            try commitStagedFiles(stagedFiles, fileManager: fileManager)
            try? fileManager.removeItem(at: stagingDir)
            return Set(stagedFiles.map(\.relativePath))
        } catch {
            try? fileManager.removeItem(at: stagingDir)
            throw error
        }
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

    private func extractImageEntries(from archive: Archive) -> [Entry] {
        archive.filter { $0.path.hasPrefix("images/") && $0.type == .file }
    }

    private func validatedImageEntries(
        from archive: Archive,
        expectedPaths: Set<String>?
    ) throws -> [Entry] {
        let entries = extractImageEntries(from: archive)
        guard let expectedPaths else { return entries }
        guard expectedPaths.allSatisfy(ImageStorage.isSafeRelativeImagePath) else {
            throw BackupError.invalidArchive
        }

        let availablePaths = Set(entries.compactMap { entry in
            ImageStorage.isSafeRelativeImagePath(entry.path) ? entry.path : nil
        })
        guard expectedPaths.isSubset(of: availablePaths) else {
            throw BackupError.invalidArchive
        }
        return entries.filter { expectedPaths.contains($0.path) }
    }

    private func stageImageEntries(
        _ context: ImageRestoreStageContext,
        lastReportedPercent: inout Int,
        onProgress: ProgressHandler?
    ) throws -> [StagedImageFile] {
        let fileManager = FileManager.default
        let totalImages = context.imageEntries.count
        let basePath = context.libraryDirectory.standardizedFileURL.path + "/"
        let stagingBasePath = context.stagingDir.standardizedFileURL.path + "/"
        var stagedFiles: [StagedImageFile] = []
        var totalRestoredBytes: Int64 = 0

        for (index, entry) in context.imageEntries.enumerated() {
            let relativePath = entry.path
            let pathComponents = relativePath.split(separator: "/")
            let destinationURL = context.libraryDirectory.appendingPathComponent(relativePath).standardizedFileURL
            let stagedURL = context.stagingDir.appendingPathComponent(relativePath).standardizedFileURL

            guard ImageStorage.isSafeRelativeImagePath(relativePath),
                  !pathComponents.contains(".."),
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
            stagedFiles.append(
                StagedImageFile(
                    relativePath: relativePath,
                    stagedURL: stagedURL,
                    destinationURL: destinationURL
                )
            )
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
