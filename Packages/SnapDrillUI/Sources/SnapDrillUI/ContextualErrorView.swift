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
