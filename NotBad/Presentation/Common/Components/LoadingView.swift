//
//  LoadingView.swift
//  NotBad
//
//  通用加载视图组件
//

import SwiftUI

/// 全屏加载遮罩
struct LoadingOverlay: View {
    let message: String
    
    init(_ message: String = "加载中...") {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

/// 内联加载指示器
struct InlineLoader: View {
    let message: String
    
    init(_ message: String = "加载中") {
        self.message = message
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

/// 带动画的加载点
struct AnimatedDots: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

#Preview("Loading Overlay") {
    ZStack {
        Color.blue
        LoadingOverlay("正在保存...")
    }
}

#Preview("Inline Loader") {
    InlineLoader("正在加载题目")
}

#Preview("Animated Dots") {
    AnimatedDots()
}
