import Foundation
import SwiftData

/// Live storage/sync topology exposed to Settings diagnostics.
enum StoreSyncStatus: Equatable, Sendable {
    case localOnly
    case cloudKitPrivate
    case cloudKitFallbackToLocal(String)
}

/// Outcome of initializing the SwiftData ModelContainer.
struct ContainerLoadResult: @unchecked Sendable {
    let container: ModelContainer?
    let syncStatus: StoreSyncStatus
    let errorDescription: String?
}

/// Centralizes CloudKit-aware ModelContainer creation, non-destructive corrupted-store archival,
/// and full DB + images recovery ZIP export (PRD §8.6, AC-08, AC-09).
enum ModelContainerFactory {
    static let schema = Schema([
        Subject.self,
        MistakeItem.self,
        MistakeTag.self,
        CustomCause.self
    ])

    static func defaultStoreURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("SnapDrill.sqlite")
    }

    static func makeContainer(
        cloudKitRequested: Bool,
        storeURL: URL = defaultStoreURL(),
        containerIdentifier: String = AppConfig.cloudKitContainerIdentifier
    ) -> ContainerLoadResult {
        try? FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if cloudKitRequested {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .private(containerIdentifier)
            )
            do {
                let container = try ModelContainer(for: schema, configurations: [cloudConfig])
                return ContainerLoadResult(
                    container: container,
                    syncStatus: .cloudKitPrivate,
                    errorDescription: nil
                )
            } catch {
                // Gracefully keep local store operational when CloudKit entitlement or iCloud account is unavailable
                let localFallbackConfig = ModelConfiguration(
                    schema: schema,
                    url: storeURL,
                    cloudKitDatabase: .none
                )
                do {
                    let container = try ModelContainer(for: schema, configurations: [localFallbackConfig])
                    return ContainerLoadResult(
                        container: container,
                        syncStatus: .cloudKitFallbackToLocal(error.localizedDescription),
                        errorDescription: nil
                    )
                } catch let localError {
                    return ContainerLoadResult(
                        container: nil,
                        syncStatus: .localOnly,
                        errorDescription: localError.localizedDescription
                    )
                }
            }
        } else {
            let localConfig = ModelConfiguration(
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            do {
                let container = try ModelContainer(for: schema, configurations: [localConfig])
                return ContainerLoadResult(
                    container: container,
                    syncStatus: .localOnly,
                    errorDescription: nil
                )
            } catch {
                return ContainerLoadResult(
                    container: nil,
                    syncStatus: .localOnly,
                    errorDescription: error.localizedDescription
                )
            }
        }
    }

    /// Exports BOTH the SwiftData store files (.sqlite/.sqlite-wal/.sqlite-shm) and stored images into a recovery ZIP (AC-09).
    static func createRecoveryPackageArchive(
        storeURL: URL = defaultStoreURL(),
        imageStore: MistakeImageStore,
        errorSummary: String = "",
        outputDirectory: URL? = nil
    ) throws -> URL {
        let fm = FileManager.default
        let stagingDir = fm.temporaryDirectory.appendingPathComponent("SnapDrill-Recovery-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: stagingDir) }

        let dbDest = stagingDir.appendingPathComponent("database", isDirectory: true)
        try fm.createDirectory(at: dbDest, withIntermediateDirectories: true)
        for fileURL in matchingStoreFiles(storeURL: storeURL) {
            let target = dbDest.appendingPathComponent(fileURL.lastPathComponent)
            try? fm.copyItem(at: fileURL, to: target)
        }

        let imagesDest = stagingDir.appendingPathComponent("images", isDirectory: true)
        if fm.fileExists(atPath: imageStore.rootDirectory.path) {
            try fm.copyItem(at: imageStore.rootDirectory, to: imagesDest)
        } else {
            try fm.createDirectory(at: imagesDest, withIntermediateDirectories: true)
        }

        if !errorSummary.isEmpty {
            let infoURL = stagingDir.appendingPathComponent("recovery_error.txt")
            try? errorSummary.data(using: .utf8)?.write(to: infoURL, options: [.atomic])
        }

        let targetDir = outputDirectory ?? fm.temporaryDirectory
        try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let zipURL = targetDir.appendingPathComponent("SnapDrill-Recovery-\(formatter.string(from: .now)).zip")
        try? fm.removeItem(at: zipURL)

        var coordinatorError: NSError?
        var copyError: Error?
        NSFileCoordinator().coordinate(readingItemAt: stagingDir, options: .forUploading, error: &coordinatorError) { zippedURL in
            do {
                try fm.copyItem(at: zippedURL, to: zipURL)
            } catch {
                copyError = error
            }
        }

        if let coordinatorError { throw coordinatorError }
        if let copyError { throw copyError }
        return zipURL
    }

    /// Moves unreadable store files into a timestamped archive folder so user assets are preserved while letting a fresh store boot.
    @discardableResult
    static func archiveCorruptedStoreFiles(storeURL: URL = defaultStoreURL()) throws -> URL {
        let fm = FileManager.default
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let archiveDir = storeURL.deletingLastPathComponent()
            .appendingPathComponent("CorruptedStores/\(formatter.string(from: .now))-\(UUID().uuidString.prefix(6))", isDirectory: true)
        try fm.createDirectory(at: archiveDir, withIntermediateDirectories: true)

        for fileURL in matchingStoreFiles(storeURL: storeURL) {
            let dest = archiveDir.appendingPathComponent(fileURL.lastPathComponent)
            try fm.moveItem(at: fileURL, to: dest)
        }
        return archiveDir
    }

    static func matchingStoreFiles(storeURL: URL) -> [URL] {
        let fm = FileManager.default
        let parent = storeURL.deletingLastPathComponent()
        guard let contents = try? fm.contentsOfDirectory(at: parent, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return []
        }
        let targetPrefix = storeURL.lastPathComponent
        return contents.filter { url in
            let name = url.lastPathComponent
            return name.hasPrefix(targetPrefix) || name.hasPrefix("default.store")
        }
    }
}
