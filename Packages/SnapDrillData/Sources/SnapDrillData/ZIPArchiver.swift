//
//  ZIPArchiver.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/05/09.
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
    ///   - destination: 目标 ZIP 文件 URL（已存在则先清理）
    /// - Throws: Archive 创建或写入失败时抛出
    public func createArchive(entries: [ZIPEntry], at destination: URL) throws {
        try? FileManager.default.removeItem(at: destination) // best-effort: 清理旧文件

        let archive = try Archive(url: destination, accessMode: .create)

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
