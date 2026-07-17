//
//  BackupImagePathValidator.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers
import ZIPFoundation
import SnapDrillCore

nonisolated enum BackupImagePathValidator {
    private static let maxJPEGDimension: Int64 = 16_384
    private static let maxJPEGPixelCount: Int64 = 100_000_000

    static func validatePayload(_ payload: BackupPayload) throws {
        guard hasUniqueIds(payload.profiles.map(\.profileId)) else {
            throw BackupError.invalidArchive
        }

        for profileData in payload.profiles {
            let dimensionIds = profileData.dimensions.map(\.id)
            let categoryValueIds = profileData.categoryValues.map(\.id)
            guard hasUniqueIds(profileData.reviewItems.map(\.id)),
                  hasUniqueIds(dimensionIds),
                  hasUniqueIds(categoryValueIds) else {
                throw BackupError.invalidArchive
            }

            let dimensionIdSet = Set(dimensionIds)
            for value in profileData.categoryValues {
                guard let dimensionId = value.dimensionId,
                      dimensionIdSet.contains(dimensionId) else {
                    throw BackupError.invalidArchive
                }
            }

            let categoryValueIdSet = Set(categoryValueIds)
            for item in profileData.reviewItems {
                guard hasUniqueIds(item.categoryValueIds),
                      item.categoryValueIds.allSatisfy(categoryValueIdSet.contains) else {
                    throw BackupError.invalidArchive
                }
                try validate(item.imagePath)
                try validate(item.answerImagePath)
            }
        }
    }

    static func validatedImageEntries(_ payload: BackupPayload, in archive: Archive) throws -> [Entry] {
        try validatePayload(payload)

        let expectedPaths = Set(payload.profiles.flatMap { profileData in
            let profilePrefix = "profiles/\(profileData.profileId.uuidString)/"
            return profileData.reviewItems.flatMap { item in
                [item.imagePath, item.answerImagePath].compactMap { path in
                    path.map { profilePrefix + $0 }
                }
            }
        })
        var actualPaths: Set<String> = []
        var imageEntries: [Entry] = []

        for entry in archive where isImageNamespacePath(entry.path) {
            guard entry.type == .file,
                  expectedPaths.contains(entry.path),
                  actualPaths.insert(entry.path).inserted else {
                throw BackupError.invalidArchive
            }
            imageEntries.append(entry)
        }

        guard actualPaths == expectedPaths else {
            throw BackupError.invalidArchive
        }
        return imageEntries.sorted { $0.path < $1.path }
    }

    static func validateJPEGData(_ data: Data) throws {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions),
              let typeIdentifier = CGImageSourceGetType(source) as String?,
              let imageType = UTType(typeIdentifier),
              imageType.conforms(to: .jpeg),
              CGImageSourceGetCount(source) > 0 else {
            throw BackupError.invalidArchive
        }
        try validateCompleteImageSource(source)
        try validateImageProperties(of: source)

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 1
        ]
        guard CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        ) != nil else {
            throw BackupError.invalidArchive
        }
    }

    static func validateCompleteImageSource(_ source: CGImageSource) throws {
        guard CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            throw BackupError.invalidArchive
        }
    }

    private static func validateImageProperties(of source: CGImageSource) throws {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.int64Value,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.int64Value,
              properties[kCGImagePropertyGPSDictionary] == nil else {
            throw BackupError.invalidArchive
        }
        try validatePixelDimensions(width: width, height: height)
    }

    static func validatePixelDimensions(width: Int64, height: Int64) throws {
        guard width > 0,
              height > 0,
              width <= maxJPEGDimension,
              height <= maxJPEGDimension,
              width <= maxJPEGPixelCount / height else {
            throw BackupError.invalidArchive
        }
    }

    static func readableImageURL(path: String, relativeTo baseDirectory: URL) throws -> URL {
        guard ImageStorage.isValidImagePath(path) else { throw BackupError.invalidArchive }
        guard let fileURL = ImageStorage(baseDirectory: baseDirectory).imageFileURL(path: path) else {
            throw BackupError.referencedImageUnavailable(path: path)
        }
        return fileURL
    }

    static func prepareDestination(
        at imageBasePath: URL,
        destinationURLs: [URL],
        fileManager: FileManager
    ) throws {
        guard !destinationURLs.isEmpty else { return }
        let imagesDirectory = imageBasePath.appendingPathComponent("images", isDirectory: true).standardizedFileURL
        guard try isMissingOrDirectory(imageBasePath, fileManager: fileManager),
              try isMissingOrDirectory(imagesDirectory, fileManager: fileManager) else {
            throw BackupError.invalidArchive
        }
        for destinationURL in destinationURLs {
            guard destinationURL.deletingLastPathComponent().standardizedFileURL == imagesDirectory,
                  try isMissingOrRegularFile(destinationURL, fileManager: fileManager) else {
                throw BackupError.invalidArchive
            }
        }
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
    }

    private static func validate(_ path: String?) throws {
        guard let path else { return }
        guard ImageStorage.isValidImagePath(path) else { throw BackupError.invalidArchive }
    }

    private static func hasUniqueIds(_ ids: [UUID]) -> Bool {
        Set(ids).count == ids.count
    }

    private static func isImageNamespacePath(_ path: String) -> Bool {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        return components.count >= 3
            && components[0] == "profiles"
            && components[2] == "images"
    }

    private static func isMissingOrDirectory(_ url: URL, fileManager: FileManager) throws -> Bool {
        try fileType(at: url, fileManager: fileManager).map { $0 == .typeDirectory } ?? true
    }

    private static func isMissingOrRegularFile(_ url: URL, fileManager: FileManager) throws -> Bool {
        try fileType(at: url, fileManager: fileManager).map { $0 == .typeRegular } ?? true
    }

    private static func fileType(at url: URL, fileManager: FileManager) throws -> FileAttributeType? {
        do {
            return try fileManager.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType
        } catch {
            guard !fileManager.fileExists(atPath: url.path) else { throw BackupError.invalidArchive }
            return nil
        }
    }
}
