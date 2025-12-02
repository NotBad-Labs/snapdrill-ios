//
//  ImageSelectionCard.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - ImageSelectionCard

/// 图片选择卡片组件
///
/// 符合 Apple HIG 的图片选择区域，支持：
/// - 拍照
/// - 实时扫描
/// - 相册选择
/// - 图片预览与重选
/// - 取消/清除已选图片
struct ImageSelectionCard: View {

    // MARK: - Bindings

    @Binding var selectedItem: PhotosPickerItem?

    // MARK: - Properties

    let selectedImage: Image?
    let isRecognizingText: Bool
    let showLiveScannerSupport: Bool

    // MARK: - Actions

    let onCameraPressed: () -> Void
    let onLiveScanPressed: () -> Void
    let onRecognizeText: () -> Void
    let onClearImage: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if let image = selectedImage {
                selectedImageView(image)
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .strokeBorder(Color.semantic.separator, lineWidth: 1)
        )
        .accessibilityIdentifier("image_selection_card")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // 更精致的图标动画
            ZStack {
                // 背景光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.brand.primary.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                // 虚线圆圈
                Circle()
                    .strokeBorder(
                        Color.brand.primary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                    )
                    .frame(width: 90, height: 90)

                // 图标
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.brand.primary)
            }
            .accessibilityHidden(true)

            // 提示文字 - 只保留主标题
            Text("capture_add_image_prompt")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 操作按钮组
            actionButtonsRow
                .padding(.top, DesignTokens.Spacing.xs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignTokens.Spacing.lg)
    }

    private var actionButtonsRow: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            // 拍照
            CaptureMethodButton(
                icon: "camera",
                title: String(localized: "capture_camera"),
                subtitle: String(localized: "capture_camera_hint")
            ) {
                onCameraPressed()
            }

            // 实时扫描
            if showLiveScannerSupport {
                CaptureMethodButton(
                    icon: "doc.text.viewfinder",
                    title: String(localized: "capture_scan"),
                    subtitle: String(localized: "capture_scan_hint")
                ) {
                    onLiveScanPressed()
                }
            }

            // 相册
            PhotosPicker(selection: $selectedItem, matching: .images) {
                CaptureMethodContent(
                    icon: "photo.stack",
                    title: String(localized: "capture_album"),
                    subtitle: String(localized: "capture_album_hint")
                )
            }
        }
    }

    // MARK: - Selected Image View

    private func selectedImageView(_ image: Image) -> some View {
        ZStack(alignment: .bottom) {
            // 图片
            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))

            // 底部操作栏
            imageActionBar
        }
    }

    private var imageActionBar: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 取消按钮
            Button {
                onClearImage()
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "xmark")
                    Text("common_cancel")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(Color.brand.error.opacity(0.8), in: Capsule())
            }

            Spacer()

            // OCR 识别按钮
            Button {
                onRecognizeText()
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    if isRecognizingText {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "text.viewfinder")
                    }
                    Text(isRecognizingText ? "capture_recognizing" : "capture_ocr")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(Color.brand.warning, in: Capsule())
            }
            .disabled(isRecognizingText)

            // 重选按钮
            Menu {
                Button {
                    onCameraPressed()
                } label: {
                    Label("capture_camera", systemImage: "camera")
                }

                if showLiveScannerSupport {
                    Button {
                        onLiveScanPressed()
                    } label: {
                        Label("capture_scan", systemImage: "text.viewfinder")
                    }
                }

                // 相册选择通过 PhotosPicker 实现
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("capture_reselect_short")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - CaptureMethodButton

/// Apple 风格的录入方式按钮
private struct CaptureMethodButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button {
            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        } label: {
            CaptureMethodContent(icon: icon, title: title, subtitle: subtitle)
        }
        .buttonStyle(CaptureButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

/// 录入方式按钮内容（用于 PhotosPicker）
struct CaptureMethodContent: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // 图标 - Apple 风格的圆形背景
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
            }

            // 标题
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            
            // 副标题
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(minWidth: 80)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .padding(.horizontal, DesignTokens.Spacing.xs)
    }
}

/// 录入按钮的点击动画样式
private struct CaptureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 空状态
        ImageSelectionCard(
            selectedItem: .constant(nil),
            selectedImage: nil,
            isRecognizingText: false,
            showLiveScannerSupport: true,
            onCameraPressed: {},
            onLiveScanPressed: {},
            onRecognizeText: {},
            onClearImage: {}
        )

        // 有图片
        ImageSelectionCard(
            selectedItem: .constant(nil),
            selectedImage: Image(systemName: "photo"),
            isRecognizingText: false,
            showLiveScannerSupport: true,
            onCameraPressed: {},
            onLiveScanPressed: {},
            onRecognizeText: {},
            onClearImage: {}
        )
    }
    .padding()
}
