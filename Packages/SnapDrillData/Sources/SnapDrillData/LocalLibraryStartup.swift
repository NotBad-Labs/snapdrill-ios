//
//  LocalLibraryStartup.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Fail-closed startup selection for the single Profile-free local library.
//

import Darwin
import Foundation
import SnapDrillCore

/// Stable startup failures owned by the Local Library Data Contract.
public nonisolated enum LocalLibraryStartupError: String, Error, Equatable, Sendable {
    case libraryRootUnsafe
    case activeSelectorInvalid
    case libraryOperationInProgress
    case libraryStoreUnavailable
}

/// Paths selected for the one concrete production LocalLibrary runtime.
public nonisolated struct LocalLibraryStartupSelection: Equatable, Sendable {
    public let generationID: String
    public let generationDirectoryURL: URL
    public let storeURL: URL
    public let imagesDirectoryURL: URL

    init(id: LocalLibraryUUID, layout: LocalLibraryLayout) {
        generationID = id.canonicalString
        generationDirectoryURL = layout.generationDirectoryURL(for: id)
        storeURL = generationDirectoryURL.appendingPathComponent("library.store", isDirectory: false)
        imagesDirectoryURL = generationDirectoryURL.appendingPathComponent("images", isDirectory: true)
    }
}

/// Prepared startup state. A first-launch selection is not active until its store is opened and
/// ``publishInitialSelection()`` succeeds.
nonisolated struct LocalLibraryStartup {
    let selection: LocalLibraryStartupSelection
    let isFirstLaunch: Bool

    private let layout: LocalLibraryLayout
    private let generationID: LocalLibraryUUID

    static func prepare(
        layout: LocalLibraryLayout,
        firstGenerationID: UUID = UUID()
    ) throws -> LocalLibraryStartup {
        let firstID = LocalLibraryUUID(firstGenerationID)
        let localLibraryKind = nodeKind(at: layout.localLibraryDirectoryURL)
        try validateOptionalRecoveryRoot(layout.recoveryIncidentsDirectoryURL)

        switch localLibraryKind {
        case .absent:
            return try prepareFirstLaunch(layout: layout, generationID: firstID)
        case .directory:
            return try resolveExisting(layout: layout)
        case .regularFile, .other:
            throw LocalLibraryStartupError.libraryRootUnsafe
        }
    }

    /// Publishes the first active selector only after SwiftData has created and opened the store.
    ///
    /// Existing-library startup never rewrites the selector.
    func publishInitialSelection() throws {
        guard isFirstLaunch,
              Self.nodeKind(at: selection.storeURL) == .regularFile,
              Self.nodeKind(at: selection.imagesDirectoryURL) == .directory,
              Self.nodeKind(at: layout.activeGenerationSelectorURL) == .absent else {
            throw LocalLibraryStartupError.libraryStoreUnavailable
        }
        try Self.requireEmptyDirectory(layout.transactionsDirectoryURL)
        try Self.requireNoRecoveryIncidents(layout.recoveryIncidentsDirectoryURL)

        let bytes = LocalLibraryActiveGenerationSelector.encode(generationID)
        let stagingName = ".active-generation.\(generationID.canonicalString).staging"
        let stagingURL = layout.localLibraryDirectoryURL.appendingPathComponent(stagingName)
        guard Self.nodeKind(at: stagingURL) == .absent else {
            throw LocalLibraryStartupError.libraryRootUnsafe
        }

        let staging = try DurableRegularFilePublisher.RelativeFile(fileName: stagingName)
        let destination = try DurableRegularFilePublisher.RelativeFile(fileName: "active-generation")
        do {
            try DurableRegularFilePublisher().publish(
                bytes,
                staging: staging,
                destination: destination,
                beneath: layout.localLibraryDirectoryURL,
                isExcludedFromBackup: false
            )
        } catch let error as DurableRegularFilePublicationError
            where error.outcome == .publicationOutcomeUncertain {
            guard try Self.readSelector(layout.activeGenerationSelectorURL) == generationID else {
                throw LocalLibraryStartupError.activeSelectorInvalid
            }
        } catch {
            throw LocalLibraryStartupError.activeSelectorInvalid
        }

        guard try Self.readSelector(layout.activeGenerationSelectorURL) == generationID else {
            throw LocalLibraryStartupError.activeSelectorInvalid
        }
    }
}

nonisolated private extension LocalLibraryStartup {
    enum NodeKind: Equatable {
        case absent
        case regularFile
        case directory
        case other
    }

    static let localLibraryChildren = Set([
        "active-generation",
        "generations",
        "transactions"
    ])

    static let activeGenerationChildren = Set([
        "images",
        "library.store",
        "library.store-shm",
        "library.store-wal"
    ])

    static func prepareFirstLaunch(
        layout: LocalLibraryLayout,
        generationID: LocalLibraryUUID
    ) throws -> LocalLibraryStartup {
        guard nodeKind(at: layout.activeGenerationSelectorURL) == .absent,
              nodeKind(at: layout.generationsDirectoryURL) == .absent,
              nodeKind(at: layout.transactionsDirectoryURL) == .absent else {
            throw LocalLibraryStartupError.activeSelectorInvalid
        }

        do {
            try createProtectedDirectory(layout.appOwnedRootURL, withIntermediateDirectories: true)
            try createProtectedDirectory(layout.localLibraryDirectoryURL)
            try createProtectedDirectory(layout.generationsDirectoryURL)
            try createProtectedDirectory(layout.transactionsDirectoryURL)
            try createProtectedDirectory(layout.recoveryIncidentsDirectoryURL)

            let generationURL = layout.generationDirectoryURL(for: generationID)
            try createProtectedDirectory(generationURL)
            try createProtectedDirectory(generationURL.appendingPathComponent("images", isDirectory: true))
        } catch let error as LocalLibraryStartupError {
            throw error
        } catch {
            throw LocalLibraryStartupError.libraryRootUnsafe
        }

        return LocalLibraryStartup(
            selection: LocalLibraryStartupSelection(id: generationID, layout: layout),
            isFirstLaunch: true,
            layout: layout,
            generationID: generationID
        )
    }

    static func resolveExisting(layout: LocalLibraryLayout) throws -> LocalLibraryStartup {
        let rootChildren = Set(try directoryChildren(layout.localLibraryDirectoryURL))
        guard rootChildren.isSubset(of: localLibraryChildren),
              rootChildren.contains("generations"),
              rootChildren.contains("transactions") else {
            throw LocalLibraryStartupError.libraryRootUnsafe
        }
        guard rootChildren.contains("active-generation") else {
            throw LocalLibraryStartupError.activeSelectorInvalid
        }
        try requireEmptyDirectory(layout.transactionsDirectoryURL)
        try requireNoRecoveryIncidents(layout.recoveryIncidentsDirectoryURL)

        let generationID = try readSelector(layout.activeGenerationSelectorURL)
        try validateGenerationDirectories(layout.generationsDirectoryURL)

        let selection = LocalLibraryStartupSelection(id: generationID, layout: layout)
        guard nodeKind(at: selection.generationDirectoryURL) == .directory else {
            throw LocalLibraryStartupError.activeSelectorInvalid
        }
        let generationChildren = try directoryChildren(selection.generationDirectoryURL)
        let imagesKind = nodeKind(at: selection.imagesDirectoryURL)
        let storeKind = nodeKind(at: selection.storeURL)
        guard Set(generationChildren).isSubset(of: activeGenerationChildren),
              generationChildren.contains("images"),
              generationChildren.contains("library.store") else {
            throw LocalLibraryStartupError.libraryStoreUnavailable
        }
        guard imagesKind != .other,
              imagesKind != .regularFile,
              storeKind != .other,
              storeKind != .directory else {
            throw LocalLibraryStartupError.libraryRootUnsafe
        }
        guard imagesKind == .directory,
              storeKind == .regularFile else {
            throw LocalLibraryStartupError.libraryStoreUnavailable
        }
        for child in generationChildren where child != "images" {
            let url = selection.generationDirectoryURL.appendingPathComponent(child)
            guard nodeKind(at: url) == .regularFile else {
                throw LocalLibraryStartupError.libraryRootUnsafe
            }
        }

        return LocalLibraryStartup(
            selection: selection,
            isFirstLaunch: false,
            layout: layout,
            generationID: generationID
        )
    }

    static func validateGenerationDirectories(_ generationsURL: URL) throws {
        guard nodeKind(at: generationsURL) == .directory else {
            throw LocalLibraryStartupError.libraryRootUnsafe
        }
        for name in try directoryChildren(generationsURL) {
            guard LocalLibraryUUID(canonicalString: name) != nil,
                  nodeKind(at: generationsURL.appendingPathComponent(name)) == .directory else {
                throw LocalLibraryStartupError.libraryRootUnsafe
            }
        }
    }

    static func validateOptionalRecoveryRoot(_ url: URL) throws {
        switch nodeKind(at: url) {
        case .absent, .directory:
            return
        case .regularFile, .other:
            throw LocalLibraryStartupError.libraryRootUnsafe
        }
    }

    static func requireNoRecoveryIncidents(_ url: URL) throws {
        guard nodeKind(at: url) == .directory else {
            throw LocalLibraryStartupError.libraryRootUnsafe
        }
        guard try directoryChildren(url).isEmpty else {
            throw LocalLibraryStartupError.libraryOperationInProgress
        }
    }

    static func requireEmptyDirectory(_ url: URL) throws {
        guard nodeKind(at: url) == .directory else {
            throw LocalLibraryStartupError.libraryRootUnsafe
        }
        guard try directoryChildren(url).isEmpty else {
            throw LocalLibraryStartupError.libraryOperationInProgress
        }
    }

    static func readSelector(_ url: URL) throws -> LocalLibraryUUID {
        var metadata = stat()
        let result = url.path.withCString { Darwin.lstat($0, &metadata) }
        guard result == 0,
              metadata.st_mode & S_IFMT == S_IFREG,
              metadata.st_nlink == 1,
              metadata.st_size == off_t(LocalLibraryActiveGenerationSelector.byteCount) else {
            throw LocalLibraryStartupError.activeSelectorInvalid
        }
        let bytes: Data
        do {
            bytes = try Data(contentsOf: url, options: .uncached)
        } catch {
            throw LocalLibraryStartupError.activeSelectorInvalid
        }
        guard let generationID = LocalLibraryActiveGenerationSelector.decode(bytes) else {
            throw LocalLibraryStartupError.activeSelectorInvalid
        }
        return generationID
    }

    static func createProtectedDirectory(
        _ url: URL,
        withIntermediateDirectories: Bool = false
    ) throws {
        switch nodeKind(at: url) {
        case .directory:
            return
        case .regularFile, .other:
            throw LocalLibraryStartupError.libraryRootUnsafe
        case .absent:
            break
        }
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: withIntermediateDirectories,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        guard nodeKind(at: url) == .directory else {
            throw LocalLibraryStartupError.libraryRootUnsafe
        }
    }

    static func directoryChildren(_ url: URL) throws -> [String] {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: url.path)
        } catch {
            throw LocalLibraryStartupError.libraryRootUnsafe
        }
    }

    static func nodeKind(at url: URL) -> NodeKind {
        var metadata = stat()
        let result = url.path.withCString { Darwin.lstat($0, &metadata) }
        guard result == 0 else {
            return errno == ENOENT ? .absent : .other
        }
        switch metadata.st_mode & S_IFMT {
        case S_IFREG:
            return metadata.st_nlink == 1 ? .regularFile : .other
        case S_IFDIR:
            return .directory
        default:
            return .other
        }
    }
}
