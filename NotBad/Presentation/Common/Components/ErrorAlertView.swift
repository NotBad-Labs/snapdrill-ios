//
//  ErrorAlertView.swift
//  NotBad
//
//  统一错误提示视图
//

import SwiftUI

// MARK: - ErrorAlertModifier

/// 错误提示修饰器
///
/// 统一处理应用中的错误提示展示。
struct ErrorAlertModifier: ViewModifier {
    
    /// 错误状态
    @Binding var error: AppError?
    
    /// 重试回调
    var onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                String(localized: "error_title"),
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { error in
                // 按钮
                Button(String(localized: "error_button_ok"), role: .cancel) {
                    self.error = nil
                }
                
                if onRetry != nil && error.recoverySuggestion != nil {
                    Button(String(localized: "error_button_retry")) {
                        self.error = nil
                        onRetry?()
                    }
                }
                
                // 权限相关错误显示设置按钮
                if case .cameraPermissionDenied = error {
                    settingsButton
                } else if case .photoLibraryPermissionDenied = error {
                    settingsButton
                } else if case .notificationPermissionDenied = error {
                    settingsButton
                }
            } message: { error in
                VStack {
                    Text(error.userMessage)
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
    }
    
    /// 打开设置按钮
    private var settingsButton: some View {
        Button(String(localized: "error_button_settings")) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// 添加统一错误处理
    ///
    /// - Parameters:
    ///   - error: 错误状态绑定
    ///   - onRetry: 可选的重试回调
    /// - Returns: 带错误处理的视图
    ///
    /// ## 使用示例
    ///
    /// ```swift
    /// @State private var error: AppError?
    ///
    /// var body: some View {
    ///     ContentView()
    ///         .errorAlert($error) {
    ///             // 重试逻辑
    ///         }
    /// }
    /// ```
    func errorAlert(_ error: Binding<AppError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(error: error, onRetry: onRetry))
    }
}

// MARK: - ErrorBannerView

/// 错误横幅视图
///
/// 显示在视图顶部或底部的错误提示横幅。
struct ErrorBannerView: View {
    
    /// 错误
    let error: AppError
    
    /// 关闭回调
    var onDismiss: (() -> Void)?
    
    /// 重试回调
    var onRetry: (() -> Void)?
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 图标
            Image(systemName: error.icon)
                .font(.title3)
                .foregroundStyle(.white)
            
            // 消息
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs / 2) {
                Text(error.userMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            // 重试按钮
            if let onRetry = onRetry {
                Button {
                    onRetry()
                } label: {
                    Text("error_button_retry")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2), in: Capsule())
                }
            }
            
            // 关闭按钮
            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.brand.error, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Error Alert") {
    struct PreviewWrapper: View {
        @State private var error: AppError? = .saveFailed(reason: "数据库连接失败")
        
        var body: some View {
            VStack {
                Button("Show Error") {
                    error = .saveFailed(reason: "数据库连接失败")
                }
            }
            .errorAlert($error) {
                // Retry action
            }
        }
    }
    
    return PreviewWrapper()
}

#Preview("Error Banner") {
    VStack {
        ErrorBannerView(
            error: .networkUnavailable,
            onDismiss: {},
            onRetry: {}
        )
        
        ErrorBannerView(
            error: .cameraPermissionDenied,
            onDismiss: {}
        )
        
        Spacer()
    }
}
