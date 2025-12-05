//
//  InfrastructureError.swift
//  NotBad
//
//  Infrastructure Layer - 基础设施错误类型
//

import Foundation

// MARK: - InfrastructureError

/// Infrastructure 层错误
///
/// 表示外部服务和系统级错误。
///
/// ## 使用场景
///
/// - OCR 服务失败
/// - 文件系统错误
/// - 权限错误
/// - 网络错误（未来）
///
/// ## 使用示例
///
/// ```swift
/// do {
///     let text = try await ocrService.recognize(image: data)
/// } catch {
///     throw InfrastructureError.ocrFailed(reason: error.localizedDescription)
/// }
/// ```
enum InfrastructureError: Error, LocalizedError, Sendable {
    
    // MARK: - OCR Errors
    
    /// OCR 识别失败
    case ocrFailed(reason: String)
    
    /// OCR 服务不可用
    case ocrServiceUnavailable
    
    /// 不支持的图片格式
    case unsupportedImageFormat(format: String)
    
    // MARK: - File System Errors
    
    /// 文件读取失败
    case fileReadFailed(path: String, underlying: Error)
    
    /// 文件写入失败
    case fileWriteFailed(path: String, underlying: Error)
    
    /// 文件不存在
    case fileNotFound(path: String)
    
    /// 磁盘空间不足
    case insufficientDiskSpace(required: Int64, available: Int64)
    
    // MARK: - Permission Errors
    
    /// 权限被拒绝
    case permissionDenied(resource: String)
    
    /// 需要权限
    case permissionRequired(resource: String, reason: String)
    
    // MARK: - Export Errors
    
    /// 导出失败
    case exportFailed(format: String, reason: String)
    
    /// PDF 生成失败
    case pdfGenerationFailed(underlying: Error)
    
    // MARK: - Network Errors (Future)
    
    /// 网络不可用
    case networkUnavailable
    
    /// 请求超时
    case requestTimeout
    
    /// 服务器错误
    case serverError(statusCode: Int, message: String?)
    
    // MARK: - LocalizedError
    
    var errorDescription: String? {
        switch self {
        case .ocrFailed(let reason):
            return String(localized: "文字识别失败：\(reason)")
            
        case .ocrServiceUnavailable:
            return String(localized: "文字识别服务暂不可用")
            
        case .unsupportedImageFormat(let format):
            return String(localized: "不支持的图片格式：\(format)")
            
        case .fileReadFailed(let path, _):
            return String(localized: "无法读取文件：\(path)")
            
        case .fileWriteFailed(let path, _):
            return String(localized: "无法写入文件：\(path)")
            
        case .fileNotFound(let path):
            return String(localized: "文件不存在：\(path)")
            
        case .insufficientDiskSpace(let required, let available):
            let requiredMB = required / 1024 / 1024
            let availableMB = available / 1024 / 1024
            return String(localized: "磁盘空间不足：需要 \(requiredMB)MB，可用 \(availableMB)MB")
            
        case .permissionDenied(let resource):
            return String(localized: "\(resource)权限被拒绝")
            
        case .permissionRequired(let resource, let reason):
            return String(localized: "需要\(resource)权限：\(reason)")
            
        case .exportFailed(let format, let reason):
            return String(localized: "\(format)导出失败：\(reason)")
            
        case .pdfGenerationFailed:
            return String(localized: "PDF 生成失败")
            
        case .networkUnavailable:
            return String(localized: "网络不可用，请检查网络连接")
            
        case .requestTimeout:
            return String(localized: "请求超时，请重试")
            
        case .serverError(let code, let message):
            if let message = message {
                return String(localized: "服务器错误(\(code))：\(message)")
            }
            return String(localized: "服务器错误(\(code))")
        }
    }
    
    // MARK: - Recovery Suggestion
    
    var recoverySuggestion: String? {
        switch self {
        case .ocrFailed:
            return String(localized: "请确保图片清晰，或尝试重新拍摄")
            
        case .ocrServiceUnavailable:
            return String(localized: "请稍后重试")
            
        case .permissionDenied, .permissionRequired:
            return String(localized: "请在「设置」中开启相应权限")
            
        case .insufficientDiskSpace:
            return String(localized: "请清理磁盘空间后重试")
            
        case .networkUnavailable:
            return String(localized: "请检查网络连接后重试")
            
        default:
            return nil
        }
    }
}
