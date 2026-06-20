//
//  ZIPArchiver.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通用 ZIP 打包工具，封装 ZIPFoundation。供 Features 层通过 Data 层间接使用，
//  消除 Features 对 ZIPFoundation 的重复直接依赖（架构泄漏修复）。
//

import Foundation
import ZIPFoundation
import SnapDrillCore

/// ZIP 打包条目
nonisolated public struct ZIPEntry: Sendable {
    /// 归档内相对路径（如 "images/001.jpg"）
    public let path: String
    /// 文件数据
    public let data: Data

    public init(path: String, data: Data) {
        self.path = path
        self.data = data
    }
}

/// ZIP 打包文件条目（从现有文件按需读取，避免把大文件常驻内存）。
nonisolated public struct ZIPFileEntry: Sendable {
    /// 归档内相对路径（如 "images/001.jpg"）
    public let path: String
    /// 源文件 URL
    public let fileURL: URL

    public init(path: String, fileURL: URL) {
        self.path = path
        self.fileURL = fileURL
    }
}

/// 通用 ZIP 打包工具
///
/// 封装 ZIPFoundation，提供面向业务语义的简单 API。
/// 纯值类型，无 actor 隔离需求，可从任意执行器调用。
nonisolated public struct ZIPArchiver: Sendable {

    public init() {}

    /// 创建 ZIP 文件
    ///
    /// - Parameters:
    ///   - entries: 要打包的文件条目
    ///   - destination: 目标 ZIP 文件 URL（已存在则原子替换）
    /// - Throws: Archive 创建或写入失败时抛出
    public func createArchive(entries: [ZIPEntry], at destination: URL) throws {
        try createArchive(at: destination) { archive in
            for entry in entries {
                try autoreleasepool {
                    try archive.addEntry(
                        with: entry.path,
                        type: .file,
                        uncompressedSize: Int64(entry.data.count),
                        compressionMethod: .deflate,
                        provider: { position, size in
                            entry.data[Int(position) ..< Int(position) + size]
                        }
                    )
                }
            }
        }
    }

    /// 创建 ZIP 文件，条目内容从现有文件按需读取。
    ///
    /// 图片批量导出使用此入口，避免把所有 JPEG 解码成 `UIImage` 或一次性保存在
    /// `[Data]` 中。调用方仍负责提供稳定、已验证可读的文件 URL。
    public func createArchive(fileEntries: [ZIPFileEntry], at destination: URL) throws {
        try createArchive(at: destination) { archive in
            for entry in fileEntries {
                try autoreleasepool {
                    let values = try entry.fileURL.resourceValues(forKeys: [.fileSizeKey])
                    guard let fileSize = values.fileSize else {
                        throw CocoaError(.fileReadUnknown)
                    }
                    let handle = try FileHandle(forReadingFrom: entry.fileURL)
                    defer { try? handle.close() }
                    try archive.addEntry(
                        with: entry.path,
                        type: .file,
                        uncompressedSize: Int64(fileSize),
                        compressionMethod: .deflate,
                        provider: { position, size in
                            try handle.seek(toOffset: UInt64(position))
                            return handle.readData(ofLength: size)
                        }
                    )
                }
            }
        }
    }

    private func createArchive(at destination: URL, writeEntries: (Archive) throws -> Void) throws {
        let fileManager = FileManager.default
        let temporaryDestination = destination.appendingPathExtension("tmp")

        try? fileManager.removeItem(at: temporaryDestination)

        do {
            do {
                let archive = try Archive(url: temporaryDestination, accessMode: .create)
                try writeEntries(archive)
            }

            if fileManager.fileExists(atPath: destination.path) {
                _ = try fileManager.replaceItemAt(
                    destination,
                    withItemAt: temporaryDestination,
                    backupItemName: nil,
                    options: []
                )
            } else {
                try fileManager.moveItem(at: temporaryDestination, to: destination)
            }
        } catch {
            try? fileManager.removeItem(at: temporaryDestination)
            throw error
        }
    }
}
