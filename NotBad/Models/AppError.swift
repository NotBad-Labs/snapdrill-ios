//
//  AppError.swift
//  NotBad
//
//  应用错误定义
//

import Foundation

// MARK: - AppError

/// 应用错误
enum AppError: Error, LocalizedError, Sendable {
    case saveFailed(reason: String)
    case loadFailed(reason: String)
    case deleteFailed(reason: String)
    case networkUnavailable
    case invalidData
    case cameraPermissionDenied
    case photoLibraryPermissionDenied
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let reason):
            return String(localized: "保存失败：\(reason)")
        case .loadFailed(let reason):
            return String(localized: "加载失败：\(reason)")
        case .deleteFailed(let reason):
            return String(localized: "删除失败：\(reason)")
        case .networkUnavailable:
            return String(localized: "网络不可用")
        case .invalidData:
            return String(localized: "数据无效")
        case .cameraPermissionDenied:
            return String(localized: "相机权限被拒绝")
        case .photoLibraryPermissionDenied:
            return String(localized: "相册权限被拒绝")
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed:
            return String(localized: "请稍后重试")
        case .loadFailed:
            return String(localized: "请检查数据是否存在")
        case .deleteFailed:
            return String(localized: "请稍后重试")
        case .networkUnavailable:
            return String(localized: "请检查网络连接")
        case .invalidData:
            return String(localized: "请检查输入数据")
        case .cameraPermissionDenied:
            return String(localized: "请在设置中开启相机权限")
        case .photoLibraryPermissionDenied:
            return String(localized: "请在设置中开启相册权限")
        case .unknown:
            return String(localized: "请重启应用或联系支持")
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .saveFailed, .loadFailed, .deleteFailed, .networkUnavailable:
            return true
        case .invalidData, .unknown, .cameraPermissionDenied, .photoLibraryPermissionDenied:
            return false
        }
    }
}
