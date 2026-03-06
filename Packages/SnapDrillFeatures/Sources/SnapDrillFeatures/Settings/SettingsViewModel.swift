//
//  SettingsViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设置页 ViewModel，处理数据清除等操作。
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillData

@Observable
@MainActor
public final class SettingsViewModel {
    private let repositories: RepositoryContainer

    // MARK: - Initialization

    public init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public API

    public func clearAllData() async {
        do {
            try await repositories.deleteAllData()
            NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
            SnapDrillLogger.generic.info("所有数据已清空，已通知 UI 刷新。")
        } catch {
            // deleteAllData 内部为多步写入，部分已落盘的步骤无法通过 rollback 撤回；
            // 此处 rollback 仅清理内存脏状态，防止未落盘的待删对象被后续操作意外持久化
            repositories.review.rollbackContext()
            SnapDrillLogger.generic.error("清空数据失败: \(error)")
        }
    }
}
