//
//  FlowLayout.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - FlowLayout

/// 流式布局容器
///
/// 自动换行的标签布局，适用于展示知识点、标签等。
///
/// ## 使用示例
///
/// ```swift
/// FlowLayout(spacing: 8) {
///     ForEach(tags, id: \.self) { tag in
///         TagView(tag)
///     }
/// }
/// ```
struct FlowLayout: Layout {

    /// 元素间距
    var spacing: CGFloat = DesignTokens.Spacing.sm

    /// 行间距
    var lineSpacing: CGFloat = DesignTokens.Spacing.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing,
            lineSpacing: lineSpacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing,
            lineSpacing: lineSpacing
        )

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
}

// MARK: - FlowResult

private struct FlowResult {
    var size: CGSize = .zero
    var positions: [CGPoint] = []

    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat, lineSpacing: CGFloat) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let viewSize = subview.sizeThatFits(.unspecified)

            if x + viewSize.width > maxWidth, x > 0 {
                // 换行
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            lineHeight = max(lineHeight, viewSize.height)
            x += viewSize.width + spacing
            maxWidth = max(maxWidth, x - spacing)
        }

        size = CGSize(width: maxWidth, height: y + lineHeight)
    }
}

// MARK: - Preview

#Preview {
    FlowLayout(spacing: 8) {
        ForEach(["函数", "导数", "积分", "微分方程", "线性代数"], id: \.self) { tag in
            Text(tag)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.brand.primary.opacity(0.1))
                .foregroundStyle(Color.brand.primary)
                .clipShape(Capsule())
        }
    }
    .padding()
}
