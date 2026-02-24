//
//  BentoCard.swift
//  NotBadFeatureDashboard
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通用的 Bento 风格卡片容器。
//

import SwiftUI

/// Bento 风格的功能卡片，用于展示快捷操作链接
struct BentoCard: View {
    /// 卡片标题
    let title: String
    /// 卡片副标题或描述
    let subtitle: String
    /// SF Symbols 图标名称
    let icon: String
    /// 图标的渐变色背景
    let gradient: LinearGradient
    /// 点击卡片时的操作回调
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(gradient) // Gradient Text/Icon
                        .padding(8)
                        .background(.ultraThickMaterial) // Contrast
                        .clipShape(Circle())
                    Spacer()
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary) // Auto adapting
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(height: 120)
            .background(.regularMaterial) // Glass Effect
            .clipShape(RoundedRectangle(cornerRadius: 24)) // More rounded for "iOS 26"
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.2), lineWidth: 1) // Glass Border
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5) // Softer shadow
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        BentoCard(
            title: "智能扫描",
            subtitle: "录入新题",
            icon: "camera.viewfinder",
            gradient: LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
            action: {}
        )
        BentoCard(
            title: "题库浏览",
            subtitle: "管理知识",
            icon: "books.vertical.fill",
            gradient: LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
            action: {}
        )
    }
    .padding()
}
