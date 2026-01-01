//
//  FullScreenImageView.swift
//  NotBadFeatures
//
//  Created by Yiming Liao on 2026/01/01.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  全屏图片预览组件，支持缩放和滑动关闭。
//

import SwiftUI

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
                .gesture(
                    // Pinch to Zoom
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
                    // Drag to Dismiss
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
            .padding()
        }
    }
}

#Preview {
    FullScreenImageView(image: UIImage(systemName: "photo") ?? UIImage()) {
        print("Dismissed")
    }
}
