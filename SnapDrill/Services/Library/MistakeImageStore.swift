import Foundation
import UIKit

enum ImageStoreError: Error, LocalizedError, Sendable {
    case insufficientDiskSpace
    case imageEncodingFailed
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .insufficientDiskSpace:
            return String(localized: "Not enough storage space on your iPhone to save this problem.")
        case .imageEncodingFailed:
            return String(localized: "Could not encode the image for storage.")
        case .writeFailed(let detail):
            return detail
        }
    }
}

/// Manages sandbox image storage under Documents/SnapDrillImages with compression and disk-space checks (PRD §8.6, §9).
final class MistakeImageStore: @unchecked Sendable {
    let rootDirectory: URL

    init(rootDirectory: URL? = nil) {
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.rootDirectory = docs.appendingPathComponent("SnapDrillImages", isDirectory: true)
        }
    }

    /// Saves JPEG data under a relative path, downscaling/compressing to keep size ≤ ~900 KB per image.
    func saveJPEG(_ data: Data, relativePath: String, minFreeBytes: Int64 = 15 * 1024 * 1024) throws -> String {
        try ensureDiskCapacity(minFreeBytes: minFreeBytes)

        let prepared = compressToBudget(data, maxBytes: 900 * 1024)
        let targetURL = rootDirectory.appendingPathComponent(relativePath)
        let parent = targetURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        do {
            try prepared.write(to: targetURL, options: [.atomic])
            return relativePath
        } catch {
            throw ImageStoreError.writeFailed(error.localizedDescription)
        }
    }

    func loadImage(relativePath: String?) -> UIImage? {
        guard let relativePath, !relativePath.isEmpty else { return nil }
        let url = rootDirectory.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func loadData(relativePath: String?) -> Data? {
        guard let relativePath, !relativePath.isEmpty else { return nil }
        let url = rootDirectory.appendingPathComponent(relativePath)
        return try? Data(contentsOf: url)
    }

    func deleteFile(relativePath: String?) {
        guard let relativePath, !relativePath.isEmpty else { return }
        let url = rootDirectory.appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Total bytes occupied by stored images on disk.
    func totalStorageBytes() -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: rootDirectory,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize else {
                continue
            }
            total += Int64(size)
        }
        return total
    }

    /// Removes any image file not referenced by active MistakeItem records.
    @discardableResult
    func pruneOrphanedFiles(keepingRelativePaths validPaths: Set<String>) -> Int {
        guard let enumerator = FileManager.default.enumerator(
            at: rootDirectory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        let rootPath = rootDirectory.standardizedFileURL.path
        var removedCount = 0

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  values.isRegularFile == true else {
                continue
            }
            let fullPath = fileURL.standardizedFileURL.path
            guard fullPath.hasPrefix(rootPath + "/") else { continue }
            let relPath = String(fullPath.dropFirst(rootPath.count + 1))
            if !validPaths.contains(relPath) {
                try? FileManager.default.removeItem(at: fileURL)
                removedCount += 1
            }
        }
        return removedCount
    }

    // MARK: - Helpers

    private func ensureDiskCapacity(minFreeBytes: Int64) throws {
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        if let values = try? rootDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let available = values.volumeAvailableCapacityForImportantUsage,
           available < minFreeBytes {
            throw ImageStoreError.insufficientDiskSpace
        }
    }

    private func compressToBudget(_ data: Data, maxBytes: Int) -> Data {
        if data.count <= maxBytes {
            return data
        }
        guard let image = UIImage(data: data) else {
            return data
        }
        var quality: CGFloat = 0.80
        while quality >= 0.45 {
            if let compressed = image.jpegData(compressionQuality: quality), compressed.count <= maxBytes {
                return compressed
            }
            quality -= 0.12
        }
        return image.jpegData(compressionQuality: 0.45) ?? data
    }
}
