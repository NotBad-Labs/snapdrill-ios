//
//  AppError.swift
//  SnapDrillUI
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  应用级错误枚举，定义常见错误场景和用户友好提示。
//

import Foundation
import SnapDrillCore

/// 错误类型枚举
///
/// 定义应用中常见的错误场景，每种错误都有对应的友好提示。
public enum AppError: LocalizedError {

    // MARK: - Cases

    /// 相机权限被拒绝
    case cameraPermissionDenied
    /// 相册权限被拒绝
    case photoLibraryPermissionDenied
    /// OCR 文字识别失败，携带失败详情
    case ocrFailed(String)
    /// 数据导出失败，携带失败详情
    case exportFailed(String)
    /// 数据导入失败，携带失败详情
    case importFailed(String)
    /// 数据文件已损坏
    case dataCorrupted
    /// 其他未知错误
    case unknown

    // MARK: - Computed Properties

    /// 面向用户的错误标题（遵循 `LocalizedError`）
    public var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return L10n.Errors.cameraPermissionDenied
        case .photoLibraryPermissionDenied:
            return L10n.Errors.photoPermissionDenied
        case .ocrFailed:
            return L10n.Errors.ocrFailed
        case .exportFailed:
            return L10n.Errors.exportFailed
        case .importFailed:
            return L10n.Errors.importFailed
        case .dataCorrupted:
            return L10n.Errors.dataCorrupted
        case .unknown:
            return L10n.Common.unknownError
        }
    }

    /// 给用户的恢复建议（遵循 `LocalizedError`）
    public var recoverySuggestion: String? {
        switch self {
        case .cameraPermissionDenied:
            return L10n.Errors.cameraPermissionHelp
        case .photoLibraryPermissionDenied:
            return L10n.Errors.photoPermissionHelp
        case .ocrFailed:
            return L10n.Errors.ocrFailedHelp
        case .exportFailed:
            return L10n.Errors.exportFailedHelp
        case .importFailed:
            return L10n.Errors.importFailedHelp
        case .dataCorrupted:
            return L10n.Errors.dataCorruptedHelp
        case .unknown:
            return L10n.Errors.unknownErrorHelp
        }
    }

    /// 错误对应的 SF Symbol 名称
    public var icon: String {
        switch self {
        case .cameraPermissionDenied:
            return "camera.fill"
        case .photoLibraryPermissionDenied:
            return "photo.fill"
        case .ocrFailed:
            return "doc.text.viewfinder"
        case .exportFailed:
            return "square.and.arrow.up.trianglebadge.exclamationmark"
        case .importFailed:
            return "square.and.arrow.down.trianglebadge.exclamationmark"
        case .dataCorrupted:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "exclamationmark.circle.fill"
        }
    }

    /// 操作按钮标题；`nil` 表示该错误无可操作项
    public var actionTitle: String? {
        switch self {
        case .cameraPermissionDenied, .photoLibraryPermissionDenied:
            return L10n.Common.openSettings
        case .ocrFailed, .exportFailed, .importFailed:
            return L10n.Common.retry
        case .dataCorrupted:
            return L10n.Common.restartApp
        case .unknown:
            return L10n.Common.ok
        }
    }
}
