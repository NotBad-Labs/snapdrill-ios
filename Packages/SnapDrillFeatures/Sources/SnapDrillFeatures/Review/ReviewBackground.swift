//
//  ReviewBackground.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习页面的背景视图，提供沉浸式模糊效果。
//

import SwiftUI

/// 复习界面的艺术化渐变背景
/// 复习界面的艺术化渐变背景 (Dynamic Mesh)
struct ReviewBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base layer
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()
            
            // Animated Blobs
            GeometryReader { proxy in
                ZStack {
                    // Blob 1: Blue/Purple
                    Circle()
                        .fill(
                            AngularGradient(gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)]), center: .center)
                        )
                        .frame(width: proxy.size.width * 0.8)
                        .blur(radius: 60)
                        .offset(x: animate ? -30 : 30, y: animate ? -30 : 30)
                    
                    // Blob 2: Cyan/Mint
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: proxy.size.width * 0.6)
                        .blur(radius: 50)
                        .offset(x: animate ? proxy.size.width * 0.5 : proxy.size.width * 0.2, y: animate ? 50 : -50)
                    
                    // Blob 3: Pink/Orange
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: proxy.size.width * 0.7)
                        .blur(radius: 70)
                        .offset(x: animate ? -50 : 50, y: animate ? proxy.size.height * 0.6 : proxy.size.height * 0.4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
        }
    }
}

#Preview {
    ReviewBackground()
}
