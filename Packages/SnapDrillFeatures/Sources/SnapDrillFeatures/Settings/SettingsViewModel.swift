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

    public func clearAllData() {
        do {
            try repositories.deleteAllData()
            SnapDrillLogger.generic.info("Successfully cleared all data.")
        } catch {
            SnapDrillLogger.generic.error("Failed to clear data: \(error)")
        }
    }
}
