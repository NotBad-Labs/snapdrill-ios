//
//  ImageSelectionCard.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import PhotosUI

// MARK: - ImageSelectionCard

/// 图片选择卡片组件
///
/// 符合 Apple HIG 的图片选择区域，支持：
/// - 拍照
/// - 实时扫描
/// - 相册选择
/// - 图片预览与重选
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
        HStack(spacing: DesignTokens.Spacing.lg) {
            // 拍照
            ActionChip(
                icon: "camera.fill",
                title: String(localized: "capture_camera"),
                color: Color.brand.primary
            ) {
                onCameraPressed()
            }
            
            // 实时扫描
            if showLiveScannerSupport {
                ActionChip(
                    icon: "text.viewfinder",
                    title: String(localized: "capture_scan"),
                    color: Color.brand.secondary
                ) {
                    onLiveScanPressed()
                }
            }
            
            // 相册
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ActionChipContent(
                    icon: "photo.on.rectangle",
                    title: String(localized: "capture_album"),
                    color: Color.brand.success
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
            
            Spacer()
            
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

// MARK: - ActionChip

/// 小型操作按钮
private struct ActionChip: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        } label: {
            ActionChipContent(icon: icon, title: title, color: color)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier(title)
    }
}

/// 操作按钮内容（用于 PhotosPicker）
struct ActionChipContent: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .frame(width: 80, height: 80)
        .background(Color.semantic.tertiaryBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .strokeBorder(Color.semantic.separator.opacity(0.5), lineWidth: 1)
        )
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
            onRecognizeText: {}
        )
        
        // 有图片
        ImageSelectionCard(
            selectedItem: .constant(nil),
            selectedImage: Image(systemName: "photo"),
            isRecognizingText: false,
            showLiveScannerSupport: true,
            onCameraPressed: {},
            onLiveScanPressed: {},
            onRecognizeText: {}
        )
    }
    .padding()
}
