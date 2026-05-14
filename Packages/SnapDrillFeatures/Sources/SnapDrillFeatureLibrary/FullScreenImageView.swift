//
//  FullScreenImageView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  全屏图片预览组件，支持缩放和滑动关闭。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 全屏图片预览视图
///
/// 提供沉浸式图片查看体验，支持双指缩放和下滑关闭。
struct FullScreenImageView: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(y: offset.height + dragOffset.height)
                .accessibleImage(label: L10n.Accessibility.fullScreenQuestionImage)
                .gesture(
                    // 捏合缩放
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(1.0, min(value, 4.0))
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                if scale < 1.0 { scale = 1.0 }
                            }
                        }
                )
                .gesture(
                    // 拖拽关闭
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            if scale == 1.0 {
                                state = value.translation
                            }
                        }
                        .onEnded { value in
                            if abs(value.translation.height) > 100 && scale == 1.0 {
                                onDismiss()
                            } else {
                                withAnimation(.spring()) {
                                    offset = .zero
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        scale = scale > 1.0 ? 1.0 : 2.0
                    }
                }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .accessibleButton(label: L10n.Accessibility.closeFullScreenImage)
            .padding()
        }
    }
}

#Preview {
    FullScreenImageView(image: UIImage(systemName: "photo") ?? UIImage()) {
        SnapDrillLogger.generic.info("Dismissed")
    }
}
