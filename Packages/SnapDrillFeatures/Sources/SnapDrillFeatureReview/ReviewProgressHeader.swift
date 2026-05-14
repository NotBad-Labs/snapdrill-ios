//
//  ReviewProgressHeader.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习进度条，展示当前复习的进度和剩余数量。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 复习界面顶部进度指示器
struct ReviewProgressHeader: View {
    
    // MARK: - Properties
    
    /// 当前题目索引
    let current: Int
    /// 题目总数
    let total: Int
    /// 暂停回调
    let onPause: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // 暂停按钮
            Button(action: onPause) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Accessibility.pauseReview)

            // Progress Bar + Counter（合并为一个无障碍元素）
            HStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)

                        Capsule()
                            .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * CGFloat(total > 0 ? Double(current) / Double(total) : 0), height: 8)
                            .animation(.spring(duration: 0.5), value: current)
                    }
                }
                .frame(height: 8)

                Text("\(current)/\(total)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AccessibilityHelper.progressDescription(current: current, total: total))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        ReviewProgressHeader(current: 5, total: 20, onPause: {})
    }
}
