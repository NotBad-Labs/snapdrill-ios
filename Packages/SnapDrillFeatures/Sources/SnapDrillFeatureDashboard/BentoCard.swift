//
//  BentoCard.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通用的 Bento 风格卡片容器。
//

import SwiftUI
import SnapDrillUI

/// Bento 风格的功能卡片，用于展示快捷操作链接或纯数据展示
struct BentoCard: View {

    // MARK: - Properties

    /// 卡片标题
    let title: String
    /// 卡片副标题或描述
    let subtitle: String
    /// SF Symbols 图标名称
    let icon: String
    /// 图标的渐变色背景
    let gradient: LinearGradient
    /// 点击回调，nil 时卡片为纯展示模式（不可交互）
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String,
        icon: String,
        gradient: LinearGradient,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        if let action {
            Button(action: action) { cardContent }
                .accessibleButton(label: title, hint: subtitle)
        } else {
            cardContent
        }
    }

    // MARK: - Private Helpers

    private var cardContent: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(gradient)
                    .padding(8)
                    .background(.ultraThickMaterial)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                Spacer()
            }

            Spacer()

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(height: 120)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        BentoCard(
            title: "快速采集",
            subtitle: "添加资料",
            icon: "camera.viewfinder",
            gradient: LinearGradient(
                colors: [Color.blue.opacity(0.82), Color.cyan.opacity(0.58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            action: {}
        )
        BentoCard(
            title: "资料库",
            subtitle: "浏览与整理",
            icon: "books.vertical.fill",
            gradient: LinearGradient(
                colors: [Color.indigo.opacity(0.72), Color.blue.opacity(0.58)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            action: {}
        )
    }
    .padding()
}
