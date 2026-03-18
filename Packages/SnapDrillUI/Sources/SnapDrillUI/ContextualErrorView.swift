//
//  ContextualErrorView.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  上下文相关的错误提示视图
//

import SwiftUI
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
    /// 其他未知错误，携带原始错误
    case unknown(Error)

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
        case .ocrFailed(let detail):
            if !detail.isEmpty { SnapDrillLogger.generic.error("OCR 失败细节: \(detail)") }
            return L10n.Errors.ocrFailedHelp
        case .exportFailed(let detail):
            if !detail.isEmpty { SnapDrillLogger.generic.error("导出失败细节: \(detail)") }
            return L10n.Errors.exportFailedHelp
        case .importFailed(let detail):
            if !detail.isEmpty { SnapDrillLogger.generic.error("导入失败细节: \(detail)") }
            return L10n.Errors.importFailedHelp
        case .dataCorrupted:
            return L10n.Errors.dataCorruptedHelp
        case .unknown(let error):
            // 仅记录技术细节到日志，不暴露给用户（隐私 + 安全）
            SnapDrillLogger.generic.error("未知错误: \(error.localizedDescription)")
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

/// 上下文错误视图
///
/// 根据错误类型显示相应的图标、标题、描述和操作按钮。
public struct ContextualErrorView: View {
    
    // MARK: - Properties
    
    let error: AppError
    let onAction: (() -> Void)?
    
    /// 创建上下文错误视图
    /// - Parameters:
    ///   - error: 要展示的错误类型
    ///   - onAction: 操作按钮点击回调；为 `nil` 时不显示按钮
    public init(error: AppError, onAction: (() -> Void)? = nil) {
        self.error = error
        self.onAction = onAction
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.icon)
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(error.errorDescription ?? L10n.Errors.errorOccurred)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                
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
    
    /// 创建内联错误横幅
    /// - Parameters:
    ///   - error: 要展示的错误类型
    ///   - onDismiss: 用户点击关闭时的回调
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
                Text(error.errorDescription ?? L10n.Errors.errorOccurred)
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

#Preview("Camera Permission") {
    ContextualErrorView(error: .cameraPermissionDenied) {
        SnapDrillLogger.generic.info("Open Settings")
    }
}

#Preview("Error Banner") {
    VStack {
        ErrorBannerView(error: .ocrFailed("测试错误")) {
            SnapDrillLogger.generic.info("Dismissed")
        }
        Spacer()
    }
}
