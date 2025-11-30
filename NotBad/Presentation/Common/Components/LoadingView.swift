//
//  LoadingView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - LoadingOverlay

/// 全屏加载遮罩
///
/// 用于在执行耗时操作时阻止用户交互。
///
/// ## 使用示例
///
/// ```swift
/// ZStack {
///     ContentView()
///     if isLoading {
///         LoadingOverlay("保存中...")
///     }
/// }
/// ```
struct LoadingOverlay: View {

    // MARK: - Properties

    /// 加载提示文字
    let message: String

    /// 背景透明度
    var backgroundOpacity: Double = 0.3

    /// 是否显示取消按钮
    var showCancel: Bool = false

    /// 取消回调
    var onCancel: (() -> Void)?

    // MARK: - Initialization

    init(
        _ message: String = "加载中...",
        backgroundOpacity: Double = 0.3,
        showCancel: Bool = false,
        onCancel: (() -> Void)? = nil
    ) {
        self.message = message
        self.backgroundOpacity = backgroundOpacity
        self.showCancel = showCancel
        self.onCancel = onCancel
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)

                if showCancel, let onCancel {
                    Button("取消", action: onCancel)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, DesignTokens.Spacing.sm)
                }
            }
            .padding(DesignTokens.Spacing.xxl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        }
    }
}

// MARK: - InlineLoader

/// 内联加载指示器
///
/// 用于在列表或内容中显示加载状态。
///
/// ## 使用示例
///
/// ```swift
/// if isLoading {
///     InlineLoader("正在加载更多...")
/// }
/// ```
struct InlineLoader: View {

    // MARK: - Properties

    /// 加载提示文字
    let message: String

    /// 指示器大小
    var scale: CGFloat = 1.0

    // MARK: - Initialization

    init(_ message: String = "加载中", scale: CGFloat = 1.0) {
        self.message = message
        self.scale = scale
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(scale)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(DesignTokens.Spacing.lg)
    }
}

// MARK: - AnimatedDots

/// 带动画的加载点
///
/// 显示三个循环动画的点，表示加载状态。
struct AnimatedDots: View {

    // MARK: - Properties

    /// 点的颜色
    var color: Color = .accentColor

    /// 点的大小
    var size: CGFloat = 8

    /// 动画持续时间
    var duration: Double = 0.6

    // MARK: - State

    @State private var animating = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: size / 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: duration)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - SkeletonLoader

/// 骨架屏加载器
///
/// 显示内容占位符动画，提供更好的加载体验。
struct SkeletonLoader: View {

    // MARK: - Properties

    /// 宽度
    var width: CGFloat?

    /// 高度
    var height: CGFloat = 20

    /// 圆角半径
    var cornerRadius: CGFloat = 4

    // MARK: - State

    @State private var isAnimating = false

    // MARK: - Body

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - LoadingState

/// 加载状态枚举
enum LoadingState: Equatable, Sendable {
    /// 空闲
    case idle

    /// 加载中
    case loading(String?)

    /// 已加载
    case loaded

    /// 错误
    case error(String)

    /// 是否正在加载
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// 获取加载消息
    var loadingMessage: String? {
        if case .loading(let message) = self { return message }
        return nil
    }

    /// 获取错误消息
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}

// MARK: - Preview

#Preview("Loading Overlay") {
    ZStack {
        Color.blue
        LoadingOverlay("正在保存...")
    }
}

#Preview("Loading Overlay with Cancel") {
    ZStack {
        Color.blue
        LoadingOverlay("正在上传...", showCancel: true) {
            print("取消")
        }
    }
}

#Preview("Inline Loader") {
    InlineLoader("正在加载题目")
}

#Preview("Animated Dots") {
    AnimatedDots()
}

#Preview("Skeleton Loader") {
    VStack(spacing: 12) {
        SkeletonLoader(height: 24)
        SkeletonLoader(width: 200, height: 16)
        SkeletonLoader(height: 100, cornerRadius: 12)
    }
    .padding()
}
