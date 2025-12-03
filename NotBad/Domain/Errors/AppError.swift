//
//  AppError.swift
//  NotBad
//
//  统一错误类型定义
//

import Foundation

// MARK: - AppError

/// 应用统一错误类型
///
/// 定义应用中所有可能出现的错误，提供用户友好的错误消息。
///
/// ## 使用示例
///
/// ```swift
/// throw AppError.saveFailed(reason: "数据库写入失败")
///
/// do {
///     try await saveItem()
/// } catch let error as AppError {
///     showToast(.error(error.userMessage))
/// }
/// ```
enum AppError: LocalizedError, Sendable {
    
    // MARK: - Data Errors
    
    /// 保存失败
    case saveFailed(reason: String? = nil)
    
    /// 删除失败
    case deleteFailed(reason: String? = nil)
    
    /// 数据加载失败
    case loadFailed(reason: String? = nil)
    
    /// 数据不存在
    case notFound
    
    // MARK: - Image Errors
    
    /// 图片处理失败
    case imageProcessingFailed
    
    /// 图片格式不支持
    case unsupportedImageFormat
    
    /// 图片太大
    case imageTooLarge(maxSize: Int)
    
    // MARK: - OCR Errors
    
    /// OCR 识别失败
    case ocrFailed(reason: String? = nil)
    
    /// 设备不支持 OCR
    case ocrNotSupported
    
    // MARK: - Export Errors
    
    /// 导出失败
    case exportFailed(format: String)
    
    /// 分享失败
    case shareFailed
    
    // MARK: - Network Errors
    
    /// 网络不可用
    case networkUnavailable
    
    /// 同步失败
    case syncFailed(reason: String? = nil)
    
    // MARK: - Permission Errors
    
    /// 相机权限被拒绝
    case cameraPermissionDenied
    
    /// 相册权限被拒绝
    case photoLibraryPermissionDenied
    
    /// 通知权限被拒绝
    case notificationPermissionDenied
    
    // MARK: - Validation Errors
    
    /// 验证失败
    case validationFailed(field: String, reason: String)
    
    /// 输入无效
    case invalidInput(description: String)
    
    // MARK: - Unknown Error
    
    /// 未知错误
    case unknown(underlying: Error? = nil)
    
    // MARK: - User Message
    
    /// 用户友好的错误消息
    var userMessage: String {
        switch self {
        case .saveFailed(let reason):
            if let reason = reason {
                return String(format: String(localized: "error_save_failed_reason"), reason)
            }
            return String(localized: "error_save_failed")
            
        case .deleteFailed(let reason):
            if let reason = reason {
                return String(format: String(localized: "error_delete_failed_reason"), reason)
            }
            return String(localized: "error_delete_failed")
            
        case .loadFailed(let reason):
            if let reason = reason {
                return String(format: String(localized: "error_load_failed_reason"), reason)
            }
            return String(localized: "error_load_failed")
            
        case .notFound:
            return String(localized: "error_not_found")
            
        case .imageProcessingFailed:
            return String(localized: "error_image_processing")
            
        case .unsupportedImageFormat:
            return String(localized: "error_unsupported_image")
            
        case .imageTooLarge(let maxSize):
            return String(format: String(localized: "error_image_too_large"), maxSize)
            
        case .ocrFailed(let reason):
            if let reason = reason {
                return String(format: String(localized: "error_ocr_failed_reason"), reason)
            }
            return String(localized: "error_ocr_failed")
            
        case .ocrNotSupported:
            return String(localized: "error_ocr_not_supported")
            
        case .exportFailed(let format):
            return String(format: String(localized: "error_export_failed"), format)
            
        case .shareFailed:
            return String(localized: "error_share_failed")
            
        case .networkUnavailable:
            return String(localized: "error_network_unavailable")
            
        case .syncFailed(let reason):
            if let reason = reason {
                return String(format: String(localized: "error_sync_failed_reason"), reason)
            }
            return String(localized: "error_sync_failed")
            
        case .cameraPermissionDenied:
            return String(localized: "error_camera_permission")
            
        case .photoLibraryPermissionDenied:
            return String(localized: "error_photo_permission")
            
        case .notificationPermissionDenied:
            return String(localized: "error_notification_permission")
            
        case .validationFailed(let field, let reason):
            return String(format: String(localized: "error_validation_failed"), field, reason)
            
        case .invalidInput(let description):
            return String(format: String(localized: "error_invalid_input"), description)
            
        case .unknown:
            return String(localized: "error_unknown")
        }
    }
    
    // MARK: - LocalizedError
    
    var errorDescription: String? {
        userMessage
    }
    
    // MARK: - Recovery Suggestion
    
    /// 恢复建议
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .deleteFailed, .loadFailed:
            return String(localized: "error_suggestion_retry")
            
        case .networkUnavailable:
            return String(localized: "error_suggestion_check_network")
            
        case .cameraPermissionDenied, .photoLibraryPermissionDenied, .notificationPermissionDenied:
            return String(localized: "error_suggestion_settings")
            
        case .imageTooLarge:
            return String(localized: "error_suggestion_smaller_image")
            
        default:
            return nil
        }
    }
    
    // MARK: - Icon
    
    /// 错误图标
    var icon: String {
        switch self {
        case .networkUnavailable, .syncFailed:
            return "wifi.slash"
        case .cameraPermissionDenied:
            return "camera.fill"
        case .photoLibraryPermissionDenied:
            return "photo.fill"
        case .notificationPermissionDenied:
            return "bell.slash.fill"
        case .imageProcessingFailed, .unsupportedImageFormat, .imageTooLarge:
            return "photo.badge.exclamationmark"
        case .ocrFailed, .ocrNotSupported:
            return "text.viewfinder"
        case .exportFailed, .shareFailed:
            return "square.and.arrow.up.trianglebadge.exclamationmark"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Error Conversion

extension Error {
    /// 转换为 AppError
    var asAppError: AppError {
        if let appError = self as? AppError {
            return appError
        }
        return .unknown(underlying: self)
    }
}
