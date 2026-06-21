//
//  ReviewProgressHeader.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  回顾进度条，展示当前处理进度。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 回顾界面顶部进度指示器
struct ReviewProgressHeader: View {
    
    // MARK: - Properties
    
    /// 当前资料索引
    let current: Int
    /// 资料总数
    let total: Int
    /// 暂停回调
    let onPause: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color(UIColor.systemGroupedBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("review.pause")
            .accessibilityLabel(L10n.Accessibility.pauseReview)

            HStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.secondary.opacity(0.16))

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * progress)
                            .animation(.spring(duration: 0.5), value: current)
                    }
                }
                .frame(height: 7)

                Text("\(current)/\(total)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AccessibilityHelper.progressDescription(current: current, total: total))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(UIColor.separator).opacity(0.14), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return min(max(CGFloat(current) / CGFloat(total), 0), 1)
    }
}

#Preview {
    ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        ReviewProgressHeader(current: 5, total: 20, onPause: {})
    }
}
