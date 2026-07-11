//
//  LibrarySession.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SwiftData
import SnapDrillCore

/// App-lifetime owner of SnapDrill's one local library.
@MainActor
public final class LibrarySession {
    public let container: ModelContainer
    public let repositories: RepositoryContainer
    public let isUsingInMemoryFallback: Bool
    public let storeRecoveryEvent: StoreRecoveryEvent?

    private let executor: DataExecutor

    private init(
        executor: DataExecutor,
        repositories: RepositoryContainer,
        isUsingInMemoryFallback: Bool,
        storeRecoveryEvent: StoreRecoveryEvent?
    ) {
        self.executor = executor
        self.container = executor.container
        self.repositories = repositories
        self.isUsingInMemoryFallback = isUsingInMemoryFallback
        self.storeRecoveryEvent = storeRecoveryEvent
    }

    public static func create(
        inMemory: Bool = false,
        layout requestedLayout: LibraryLayout? = nil
    ) async -> LibrarySession {
        let layout = requestedLayout ?? defaultLayout(inMemory: inMemory)
        do {
            try layout.prepareDirectories()
        } catch {
            SnapDrillLogger.data.error("LibrarySession: 无法创建资料库目录: \(error.localizedDescription)")
        }

        let executor = await DataExecutor.createOffMainActor(
            inMemory: inMemory,
            storeURL: inMemory ? nil : layout.storeURL
        )
        let repositories = RepositoryContainer(executor: executor, libraryDirectory: layout.rootURL)
        let isUsingInMemoryFallback = await executor.isUsingInMemoryFallback
        let storeRecoveryEvent = await executor.storeRecoveryEvent

        return LibrarySession(
            executor: executor,
            repositories: repositories,
            isUsingInMemoryFallback: isUsingInMemoryFallback,
            storeRecoveryEvent: storeRecoveryEvent
        )
    }

    private static func defaultLayout(inMemory: Bool) -> LibraryLayout {
        guard inMemory else { return LibraryLayout() }
        return LibraryLayout(
            rootURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("SnapDrill-InMemory-\(UUID().uuidString)", isDirectory: true)
        )
    }
}
