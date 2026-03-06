//
//  RepositoryContainer+Environment.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/03/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  将 RepositoryContainer 注册为 SwiftUI 环境变量键，供 ViewModel 直接调用 Repository。
//

import SwiftUI
import SwiftData

// MARK: - Environment Key

@MainActor
private struct RepositoryContainerKey: EnvironmentKey {
    nonisolated static let defaultValue: RepositoryContainer = {
        MainActor.assumeIsolated {
            // 预览/测试用：内存 ModelContainer
            let schema = Schema([
                ReviewItemModel.self,
                SubjectModel.self,
                SourceModel.self,
                TagModel.self,
                GradeModel.self
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                let container = try ModelContainer(for: schema, configurations: [config])
                return RepositoryContainer(modelContext: container.mainContext)
            } catch {
                fatalError("无法创建预览/测试用内存 ModelContainer：\(error)")
            }
        }
    }()
}

// MARK: - EnvironmentValues 扩展

public extension EnvironmentValues {
    /// 数据仓库容器，供 ViewModel 直接调用具体 Repository
    var repositories: RepositoryContainer {
        get { self[RepositoryContainerKey.self] }
        set { self[RepositoryContainerKey.self] = newValue }
    }
}
