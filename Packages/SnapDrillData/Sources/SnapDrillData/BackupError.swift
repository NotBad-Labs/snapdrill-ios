//
//  BackupError.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SnapDrillCore

/// 备份操作错误
public enum BackupError: LocalizedError {
    case archiveCreationFailed
    case invalidArchive
    case missingManifest
    case missingDataFile
    case schemaVersionTooNew(fileVersion: Int, appVersion: Int)
    case unsupportedSchemaVersion(fileVersion: Int, appVersion: Int)
    case insufficientDiskSpace
    case archiveEntryTooLarge(path: String, limitBytes: Int64)

    public var errorDescription: String? {
        switch self {
        case .archiveCreationFailed:
            return L10n.BackupErrors.archiveCreationFailed
        case .invalidArchive:
            return L10n.BackupErrors.invalidArchive
        case .missingManifest:
            return L10n.BackupErrors.missingManifest
        case .missingDataFile:
            return L10n.BackupErrors.missingDataFile
        case .schemaVersionTooNew(let fileVersion, let appVersion):
            return L10n.BackupErrors.schemaVersionTooNew(fileVersion, appVersion)
        case .unsupportedSchemaVersion(let fileVersion, let appVersion):
            return L10n.BackupErrors.unsupportedSchemaVersion(fileVersion, appVersion)
        case .insufficientDiskSpace:
            return L10n.BackupErrors.insufficientDiskSpace
        case .archiveEntryTooLarge:
            return L10n.BackupErrors.invalidArchive
        }
    }
}
