//
//  BackupService.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  备份/恢复服务，将全量数据（JSON + 图片）打包为 .snapdrill (ZIP) 文件。
//

import Foundation
import ZIPFoundation
import SnapDrillCore

/// 备份/恢复服务
///
/// 负责将 SnapDrill 全量数据（题目、分类、图片）打包为 `.snapdrill` (ZIP) 文件，
/// 以及从备份文件中恢复数据。使用流式 ZIP 写入，避免一次性加载所有图片到内存。
public actor BackupService {

    /// 备份进度回调（已处理数 / 总数）
    public typealias ProgressHandler = @Sendable (Int, Int) -> Void

    // MARK: - Initialization

    public init() {}

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
    /// - Returns: 生成的 .snapdrill 文件 URL（位于临时目录）
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
        let backupURL = tempDir.appendingPathComponent("SnapDrill_Backup_\(timestamp).snapdrill")

        // 清理可能存在的旧文件
        try? fileManager.removeItem(at: backupURL)

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
    /// - Parameter backupURL: .snapdrill 文件路径
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

        var manifestData = Data()
        _ = try archive.extract(manifestEntry) { data in
            manifestData.append(data)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupManifest.self, from: manifestData)
    }

    /// 从备份文件中提取全量数据
    ///
    /// - Parameter backupURL: .snapdrill 文件路径
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

        var payloadData = Data()
        _ = try archive.extract(dataEntry) { data in
            payloadData.append(data)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupPayload.self, from: payloadData)
    }

    /// 从备份文件中恢复指定 Profile 的图片
    ///
    /// - Parameters:
    ///   - backupURL: .snapdrill 文件路径
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

        // 筛选该 Profile 的图片条目：profiles/<id>/images/...
        let prefix = "profiles/\(profileId.uuidString)/images/"
        let imageEntries = archive.filter { $0.path.hasPrefix(prefix) && $0.type == .file }
        let totalImages = imageEntries.count

        let fileManager = FileManager.default
        let imagesDir = imageBasePath.appendingPathComponent("images")
        if !fileManager.fileExists(atPath: imagesDir.path) {
            try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        }

        let basePath = imageBasePath.standardizedFileURL.path + "/"
        var lastReportedPercent = -1
        for (index, entry) in imageEntries.enumerated() {
            // 去掉 profiles/<id>/ 前缀，得到相对路径（如 images/xxx.jpg）
            let profilePrefix = "profiles/\(profileId.uuidString)/"
            let relativePath = String(entry.path.dropFirst(profilePrefix.count))

            let pathComponents = relativePath.split(separator: "/")
            let destinationURL = imageBasePath.appendingPathComponent(relativePath).standardizedFileURL
            guard !pathComponents.contains(".."),
                  destinationURL.path.hasPrefix(basePath) else {
                SnapDrillLogger.generic.warning("跳过可疑路径: \(entry.path)")
                reportProgress(index + 1, totalImages, lastPercent: &lastReportedPercent, handler: onProgress)
                continue
            }

            let parentDir = destinationURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: parentDir.path) {
                try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
            }

            var fileData = Data()
            _ = try archive.extract(entry) { data in
                fileData.append(data)
            }
            try fileData.write(to: destinationURL)

            reportProgress(index + 1, totalImages, lastPercent: &lastReportedPercent, handler: onProgress)
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
        }
    }
}
