//
//  ContextualErrorView.swift
//  NotBadUI
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  上下文相关的错误提示视图
//

import SwiftUI
import NotBadCore

/// 错误类型枚举
///
/// 定义应用中常见的错误场景，每种错误都有对应的友好提示。
public enum AppError: LocalizedError {
    case networkUnavailable
    case iCloudUnavailable
    case cameraPermissionDenied
    case photoLibraryPermissionDenied
    case ocrFailed(String)
    case exportFailed(String)
    case importFailed(String)
    case dataCorrupted
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return L10n.Errors.networkUnavailable
        case .iCloudUnavailable:
            return L10n.Errors.icloudUnavailable
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
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "请检查网络连接后重试。部分功能在离线模式下可能不可用。"
        case .iCloudUnavailable:
            return "请检查 iCloud 设置并确保已登录。数据将暂时保存在本地。"
        case .cameraPermissionDenied:
            return "请在「设置」→「NotBad」→「相机」中允许访问相机权限。"
        case .photoLibraryPermissionDenied:
            return "请在「设置」→「NotBad」→「照片」中允许访问相册权限。"
        case .ocrFailed(let detail):
            return "无法识别图片中的文字。\(detail.isEmpty ? "请确保图片清晰且包含文字内容。" : detail)"
        case .exportFailed(let detail):
            return "无法导出数据。\(detail.isEmpty ? "请稍后重试。" : detail)"
        case .importFailed(let detail):
            return "无法导入数据。\(detail.isEmpty ? "请确保文件格式正确。" : detail)"
        case .dataCorrupted:
            return "数据文件已损坏，无法读取。请尝试重新启动应用。"
        case .unknown(let error):
            return "发生了意外错误：\(error.localizedDescription)"
        }
    }
    
    public var icon: String {
        switch self {
        case .networkUnavailable:
            return "wifi.slash"
        case .iCloudUnavailable:
            return "icloud.slash"
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
    
    public var actionTitle: String? {
        switch self {
        case .cameraPermissionDenied, .photoLibraryPermissionDenied:
            return L10n.Common.openSettings
        case .networkUnavailable, .iCloudUnavailable:
            return L10n.Common.retry
        case .ocrFailed, .exportFailed, .importFailed:
            return L10n.Common.retry
        case .dataCorrupted:
            return L10n.Common.restartApp
        case .unknown:
            return L10n.Common.ok
        }
    }
}

/// 上下文错误视图
///
/// 根据错误类型显示相应的图标、标题、描述和操作按钮。
public struct ContextualErrorView: View {
    let error: AppError
    let onAction: (() -> Void)?
    
    public init(error: AppError, onAction: (() -> Void)? = nil) {
        self.error = error
        self.onAction = onAction
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.icon)
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 12) {
                Text(error.errorDescription ?? "发生错误")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal)
            
            if let actionTitle = error.actionTitle, let action = onAction {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 内联错误横幅
///
/// 用于在视图顶部显示非阻断性错误提示。
public struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void
    
    public init(error: AppError, onDismiss: @escaping () -> Void) {
        self.error = error
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.icon)
                .font(.title3)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(error.errorDescription ?? "发生错误")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding()
    }
}

#Preview("Network Error") {
    ContextualErrorView(error: .networkUnavailable) {
        NotBadLogger.generic.info("Retry tapped")
    }
}

#Preview("Camera Permission") {
    ContextualErrorView(error: .cameraPermissionDenied) {
        NotBadLogger.generic.info("Open Settings")
    }
}

#Preview("Error Banner") {
    VStack {
        ErrorBannerView(error: .iCloudUnavailable) {
            NotBadLogger.generic.info("Dismissed")
        }
        Spacer()
    }
}
