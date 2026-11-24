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

/// Manages sandbox image storage under Documents/SnapDrillImages with adaptive downscale+JPEG compression,
/// disk-space checks, and CloudKit asset hydration caching (PRD §8.6, §9).
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

    /// Saves JPEG data under a relative path, enforcing <= maxBytes (default 450 KB/image so dual orig+clean stays < 1 MB/question).
    func saveJPEG(
        _ data: Data,
        relativePath: String,
        maxBytes: Int = 450 * 1024,
        minFreeBytes: Int64 = 15 * 1024 * 1024
    ) throws -> String {
        try saveJPEGWithData(data, relativePath: relativePath, maxBytes: maxBytes, minFreeBytes: minFreeBytes).relativePath
    }

    /// Compresses once and writes atomically to disk, returning both relativePath and exact bytes for SwiftData externalStorage sync.
    func saveJPEGWithData(
        _ data: Data,
        relativePath: String,
        maxBytes: Int = 450 * 1024,
        minFreeBytes: Int64 = 15 * 1024 * 1024
    ) throws -> (relativePath: String, compressedData: Data) {
        try ensureDiskCapacity(minFreeBytes: minFreeBytes)

        let prepared = Self.compressToBudget(data, maxBytes: maxBytes)
        let targetURL = rootDirectory.appendingPathComponent(relativePath)
        let parent = targetURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        do {
            try prepared.write(to: targetURL, options: [.atomic])
            return (relativePath, prepared)
        } catch {
            throw ImageStoreError.writeFailed(error.localizedDescription)
        }
    }

    /// Lazily writes CloudKit-synced bytes onto local disk cache when absent locally.
    func cacheRawDataIfMissing(_ data: Data, relativePath: String) throws {
        guard !relativePath.isEmpty, !data.isEmpty else { return }
        let targetURL = rootDirectory.appendingPathComponent(relativePath)
        guard !FileManager.default.fileExists(atPath: targetURL.path) else { return }
        try FileManager.default.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: targetURL, options: [.atomic])
    }

    func loadImage(relativePath: String?) -> UIImage? {
        guard let data = loadData(relativePath: relativePath) else { return nil }
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

    // MARK: - Compression Budget Helpers

    private func ensureDiskCapacity(minFreeBytes: Int64) throws {
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        if let values = try? rootDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let available = values.volumeAvailableCapacityForImportantUsage,
           available < minFreeBytes {
            throw ImageStoreError.insufficientDiskSpace
        }
    }

    /// Progressively lowers JPEG quality and longest edge resolution until encoded size fits inside maxBytes.
    static func compressToBudget(_ data: Data, maxBytes: Int) -> Data {
        if data.count <= maxBytes {
            return data
        }
        guard let original = UIImage(data: data) else {
            return data
        }

        for quality in [CGFloat(0.80), 0.68, 0.56] {
            if let encoded = original.jpegData(compressionQuality: quality), encoded.count <= maxBytes {
                return encoded
            }
        }

        let longest = max(original.size.width, original.size.height)
        for maxDim in [CGFloat(1600), 1280, 1024, 800, 640] {
            let candidateImage = longest > maxDim ? downscale(original, maxDimension: maxDim) : original
            for quality in [CGFloat(0.76), 0.64, 0.52, 0.44] {
                if let encoded = candidateImage.jpegData(compressionQuality: quality), encoded.count <= maxBytes {
                    return encoded
                }
            }
        }

        return downscale(original, maxDimension: 640).jpegData(compressionQuality: 0.44) ?? data
    }

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let ratio = maxDimension / longest
        let target = CGSize(
            width: max(16, (size.width * ratio).rounded(.down)),
            height: max(16, (size.height * ratio).rounded(.down))
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
