//
//  SelectedImageCard.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import UIKit

// MARK: - SelectedImageCard

/// 已选图片展示卡片
///
/// 仅在选择图片后显示，提供：
/// - 图片预览
/// - 取消选择
/// - OCR 文字识别
/// - 重新选择（通过 Menu）
struct SelectedImageCard: View {

    // MARK: - Properties

    let selectedImage: Image
    let isRecognizingText: Bool
    let showLiveScannerSupport: Bool

    // MARK: - Actions

    let onCameraPressed: () -> Void
    let onLiveScanPressed: () -> Void
    let onRecognizeText: () -> Void
    let onClearImage: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // 图片
            selectedImage
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))

            // 底部操作栏
            imageActionBar
        }
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .strokeBorder(Color.semantic.separator, lineWidth: 1)
        )
        .accessibilityIdentifier("selected_image_card")
    }

    // MARK: - Image Action Bar

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
                        Label("capture_scan", systemImage: "doc.text.viewfinder")
                    }
                }
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

// MARK: - Preview

#Preview {
    SelectedImageCard(
        selectedImage: Image(systemName: "photo.fill"),
        isRecognizingText: false,
        showLiveScannerSupport: true,
        onCameraPressed: {},
        onLiveScanPressed: {},
        onRecognizeText: {},
        onClearImage: {}
    )
    .padding()
}
