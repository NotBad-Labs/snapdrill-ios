//
//  LocalLibraryRuntime.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  The one concrete runtime for the Profile-free local library.
//

import Foundation
import SwiftData
import SnapDrillCore

/// Owns the complete live object graph for one selected LocalLibrary generation.
///
/// Production composition must create exactly one instance and inject its repositories,
/// container, and image storage together. A failed open never returns a partial runtime.
@MainActor
public final class LocalLibraryRuntime {
    public let container: ModelContainer
    public let repositories: RepositoryContainer
    public let imageStorage: ImageStorage
    public let selection: LocalLibraryStartupSelection?

    private let executor: DataExecutor

    private init(
        executor: DataExecutor,
        repositories: RepositoryContainer,
        imageStorage: ImageStorage,
        selection: LocalLibraryStartupSelection?
    ) {
        self.executor = executor
        self.container = executor.container
        self.repositories = repositories
        self.imageStorage = imageStorage
        self.selection = selection
    }

    /// Opens the one production LocalLibrary beneath Application Support.
    public static func open(fileManager: FileManager = .default) async throws -> LocalLibraryRuntime {
        let storage = try AppOwnedStorage(fileManager: fileManager)
        return try await open(appOwnedRootURL: storage.rootURL)
    }

    /// Opens the one production LocalLibrary beneath an explicitly injected app-owned root.
    ///
    /// This overload exists for deterministic Data-layer tests. Production uses ``open(fileManager:)``.
    public static func open(appOwnedRootURL: URL) async throws -> LocalLibraryRuntime {
        let startup = try LocalLibraryStartup.prepare(
            layout: LocalLibraryLayout(appOwnedRootURL: appOwnedRootURL)
        )
        let executor = try await DataExecutor.openLocalLibraryStore(at: startup.selection.storeURL)
        let imageStorage = ImageStorage(baseDirectory: startup.selection.generationDirectoryURL)
        let repositories = RepositoryContainer(executor: executor, imageStorage: imageStorage)

        if startup.isFirstLaunch {
            try startup.publishInitialSelection()
        }

        return LocalLibraryRuntime(
            executor: executor,
            repositories: repositories,
            imageStorage: imageStorage,
            selection: startup.selection
        )
    }

    /// Creates an explicit in-memory runtime for tests and previews.
    ///
    /// It has no LocalLibrary selector and is never a production fallback.
    public static func makeInMemoryForTesting(
        imageRootURL: URL = FileManager.default.temporaryDirectory
    ) -> LocalLibraryRuntime {
        let executor = DataExecutor(inMemory: true)
        let imageStorage = ImageStorage(baseDirectory: imageRootURL)
        let repositories = RepositoryContainer(executor: executor, imageStorage: imageStorage)
        return LocalLibraryRuntime(
            executor: executor,
            repositories: repositories,
            imageStorage: imageStorage,
            selection: nil
        )
    }
}
