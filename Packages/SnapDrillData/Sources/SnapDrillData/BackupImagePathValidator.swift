//
//  BackupImagePathValidator.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import ZIPFoundation
import SnapDrillCore

nonisolated enum BackupImagePathValidator {
    static func validatePayload(_ payload: BackupPayload) throws {
        for profileData in payload.profiles {
            for item in profileData.reviewItems {
                try validate(item.imagePath)
                try validate(item.answerImagePath)
            }
        }
    }

    static func validateArchivePaths(_ payload: BackupPayload, in archive: Archive) throws {
        try validatePayload(payload)
        for profileData in payload.profiles {
            let profilePrefix = "profiles/\(profileData.profileId.uuidString)/"
            let imagePrefix = profilePrefix + "images/"
            for entry in archive where entry.path.hasPrefix(imagePrefix) && entry.type == .file {
                try validate(String(entry.path.dropFirst(profilePrefix.count)))
            }
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
