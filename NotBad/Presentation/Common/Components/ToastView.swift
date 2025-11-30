//
//  ToastView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - ToastType

/// Toast 消息类型
enum ToastType: Sendable {
    /// 成功
    case success

    /// 错误
    case error

    /// 警告
    case warning

    /// 信息
    case info

    /// 图标名称
    var icon: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .error: "xmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }

    /// 颜色
    var color: Color {
        switch self {
        case .success: Color.brand.success
        case .error: Color.brand.error
        case .warning: Color.brand.warning
        case .info: Color.brand.primary
        }
    }

    /// 默认显示时长
    var defaultDuration: Double {
        switch self {
        case .success: 2.0
        case .error: 3.0
        case .warning: 2.5
        case .info: 2.0
        }
    }
}

// MARK: - Toast

/// Toast 数据模型
///
/// ## 使用示例
///
/// ```swift
/// @State private var toast: Toast?
///
/// var body: some View {
///     ContentView()
///         .toast($toast)
///         .onTapGesture {
///             toast = .success("保存成功！")
///         }
/// }
/// ```
struct Toast: Equatable, Sendable {

    // MARK: - Properties

    /// 消息类型
    let type: ToastType

    /// 消息内容
    let message: String

    /// 显示时长（秒）
    var duration: Double

    /// 创建时间戳（用于唯一标识）
    let id: UUID

    // MARK: - Initialization

    init(type: ToastType, message: String, duration: Double? = nil) {
        self.type = type
        self.message = message
        self.duration = duration ?? type.defaultDuration
        self.id = UUID()
    }

    // MARK: - Equatable

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Convenience Initializers

extension Toast {

    /// 成功 Toast
    static func success(_ message: String, duration: Double? = nil) -> Toast {
        Toast(type: .success, message: message, duration: duration)
    }

    /// 错误 Toast
    static func error(_ message: String, duration: Double? = nil) -> Toast {
        Toast(type: .error, message: message, duration: duration)
    }

    /// 警告 Toast
    static func warning(_ message: String, duration: Double? = nil) -> Toast {
        Toast(type: .warning, message: message, duration: duration)
    }

    /// 信息 Toast
    static func info(_ message: String, duration: Double? = nil) -> Toast {
        Toast(type: .info, message: message, duration: duration)
    }
}

// MARK: - ToastView

/// Toast 视图
///
/// 显示单个 Toast 消息的视图组件。
struct ToastView: View {

    // MARK: - Properties

    let toast: Toast

    /// 点击关闭回调
    var onDismiss: (() -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: toast.type.icon)
                .font(.title3)
                .foregroundStyle(toast.type.color)
                .accessibilityHidden(true)

            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)

            Spacer()

            if onDismiss != nil {
                Button {
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("关闭提示")
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        .shadow(DesignTokens.Shadow.medium)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isStaticText)
    }

    private var accessibilityDescription: String {
        let typeDescription: String
        switch toast.type {
        case .success: typeDescription = "成功"
        case .error: typeDescription = "错误"
        case .warning: typeDescription = "警告"
        case .info: typeDescription = "提示"
        }
        return "\(typeDescription)：\(toast.message)"
    }
}

// MARK: - ToastModifier

/// Toast 视图修饰器
private struct ToastModifier: ViewModifier {

    @Binding var toast: Toast?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(toast: toast) {
                        withAnimation {
                            self.toast = nil
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        scheduleAutoDismiss(for: toast)
                        // VoiceOver 公告
                        announceForAccessibility(toast)
                    }
                    .padding(.top, 50)
                }
            }
            .animation(DesignTokens.Animation.spring, value: toast)
    }

    private func scheduleAutoDismiss(for toast: Toast) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(toast.duration))
            // 确保当前 Toast 未被手动关闭
            if self.toast?.id == toast.id {
                withAnimation {
                    self.toast = nil
                }
            }
        }
    }

    private func announceForAccessibility(_ toast: Toast) {
        let typeDescription: String
        switch toast.type {
        case .success: typeDescription = "成功"
        case .error: typeDescription = "错误"
        case .warning: typeDescription = "警告"
        case .info: typeDescription = "提示"
        }
        AccessibilityAnnouncement.announce("\(typeDescription)：\(toast.message)")
    }
}

// MARK: - View Extension

extension View {

    /// 添加 Toast 支持
    ///
    /// - Parameter toast: Toast 状态绑定
    /// - Returns: 修改后的视图
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

// MARK: - Preview

#Preview("Toast Types") {
    VStack {
        Text("主内容")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay(alignment: .top) {
        VStack(spacing: 16) {
            ToastView(toast: .success("保存成功！"))
            ToastView(toast: .error("保存失败，请重试"))
            ToastView(toast: .warning("网络不稳定"))
            ToastView(toast: .info("提示：双击可快速复习"))
        }
        .padding(.top, 60)
    }
}

#Preview("Interactive Toast") {
    struct PreviewWrapper: View {
        @State private var toast: Toast?

        var body: some View {
            VStack(spacing: 20) {
                Button("显示成功") {
                    toast = .success("操作成功")
                }
                Button("显示错误") {
                    toast = .error("操作失败")
                }
            }
            .toast($toast)
        }
    }
    return PreviewWrapper()
}
