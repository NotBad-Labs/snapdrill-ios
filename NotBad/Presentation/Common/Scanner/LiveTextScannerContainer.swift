//
//  LiveTextScannerContainer.swift
//  NotBad
//
//  实时扫描容器视图
//

import SwiftUI

// MARK: - LiveTextScannerContainer

/// 实时扫描容器视图
///
/// 封装 `LiveTextScannerView` 并提供控制栏 UI。
///
/// ## 功能特性
///
/// - 扫描状态指示
/// - 完成/取消按钮
/// - 错误提示
///
/// ## 使用示例
///
/// ```swift
/// LiveTextScannerContainer(
///     onResult: { text, imageData in
///         print("识别结果: \(text)")
///     },
///     onCancel: {
///         print("用户取消")
///     }
/// )
/// ```
struct LiveTextScannerContainer: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Callbacks

    /// 扫描结果回调（文本 + 图片数据）
    let onResult: (String, Data?) -> Void

    /// 取消回调
    let onCancel: () -> Void

    // MARK: - State

    @State private var isSessionStarted = false
    @State private var errorMessage: String?
    @State private var recognizedCount = 0

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            scannerView
            controlBar
        }
        .alert(
            "scanner_error_title",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("common_confirm") { dismiss() }
        } message: {
            Text(errorMessage ?? "")
        }
        .onReceive(NotificationCenter.default.publisher(for: .liveScannerFinishResponse)) { notification in
            if let result = notification.object as? ScannerResult {
                onResult(result.text, result.imageData)
                dismiss()
            }
        }
    }

    // MARK: - Scanner View

    @ViewBuilder
    private var scannerView: some View {
        LiveTextScannerView(
            onFinish: { _, _ in
                // 结果通过 liveScannerFinishResponse 通知返回，这里不需要处理
            },
            onCancel: {
                onCancel()
                dismiss()
            }
        )
        .ignoresSafeArea()
        .onAppear(perform: startSessionIfPossible)
    }

    // MARK: - Control Bar

    @ViewBuilder
    private var controlBar: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // 错误提示
            if let errorMessage {
                errorBanner(errorMessage)
            }

            // 识别状态
            statusIndicator

            // 操作按钮
            actionButtons
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom)
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color.brand.error.opacity(0.8), in: Capsule())
    }

    private var statusIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "text.viewfinder")
                .symbolEffect(.pulse)
            Text("scanner_aim_prompt")
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(.black.opacity(0.5), in: Capsule())
    }

    private var actionButtons: some View {
        // 完成按钮（取消按钮已移至导航栏）
        Button {
            requestFinish()
        } label: {
            Label("scanner_finish", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.md + 2)
                .background(Color.brand.primary.gradient, in: Capsule())
                .foregroundStyle(.white)
        }
    }

    // MARK: - Actions

    private func startSessionIfPossible() {
        guard !isSessionStarted else { return }
        isSessionStarted = true

        Task { @MainActor in
            guard LiveTextScannerView.isSupported else {
                errorMessage = LiveTextScannerView.unsupportedReason ?? String(localized: "scanner_unsupported_device")
                return
            }
        }
    }

    private func requestFinish() {
        // 发送完成请求，coordinator 会使用自己保存的 scanner 引用截图
        NotificationCenter.default.post(name: .liveScannerFinishRequest, object: nil)
    }
}

// MARK: - Preview

#Preview("扫描器容器") {
    if LiveTextScannerView.isSupported {
        LiveTextScannerContainer(
            onResult: { _, _ in
                // Handle scan result
            },
            onCancel: {
                // Handle cancel
            }
        )
    } else {
        ContentUnavailableView(
            "设备不支持",
            systemImage: "text.viewfinder",
            description: Text(LiveTextScannerView.unsupportedReason ?? "未知原因")
        )
    }
}
