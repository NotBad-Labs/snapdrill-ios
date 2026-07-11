//
//  StoreRecoveryEvent.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation

/// 磁盘 store 打不开且已隔离重建时上报给 shell 的恢复事件。
///
/// 容器已重建为可用空库，因此这不是 in-memory fallback；B2 UI 通过该事件提示用户
/// 从备份恢复、保留空库继续或稍后人工处理隔离目录。
nonisolated public struct StoreRecoveryEvent: Sendable, Equatable {
    /// 原始 store 路径，例如 `Library/default.store`。
    public let storeURL: URL

    /// 被隔离保留的 store 文件所在目录，例如 `Library/corrupted/<timestamp>/`。
    public let isolationDirectoryURL: URL

    /// 首次打开失败的错误描述。
    public let originalErrorDescription: String

    /// 重试打开失败的错误描述。
    public let retryErrorDescription: String

    public init(
        storeURL: URL,
        isolationDirectoryURL: URL,
        originalErrorDescription: String,
        retryErrorDescription: String
    ) {
        self.storeURL = storeURL
        self.isolationDirectoryURL = isolationDirectoryURL
        self.originalErrorDescription = originalErrorDescription
        self.retryErrorDescription = retryErrorDescription
    }
}
