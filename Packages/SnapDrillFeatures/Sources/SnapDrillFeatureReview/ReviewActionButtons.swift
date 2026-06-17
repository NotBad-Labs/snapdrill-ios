//
//  ReviewActionButtons.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  回顾界面的底部操作按钮组。
//  保留滑动联动，但使用文字 + 图标降低误操作和颜色依赖。
//

import SwiftUI
import SnapDrillCore

struct ReviewActionButtons: View {
    
    // MARK: - Properties
    
    let swipeOffset: CGFloat
    let onRate: (ReviewRating) -> Void
    
    // 次要操作
    let onUndo: () -> Void
    let onToggleAnswer: () -> Void
    let isUndoEnabled: Bool
    let isAnswerShown: Bool
    
    // 配置
    private let baseHeight: CGFloat = 58
    private let maxScale: CGFloat = 1.12
    private let threshold: CGFloat = 120 // 触发最大缩放的阈值

    // 触觉反馈触发器（递增计数器确保每次都能触发变化）
    @State private var primaryFeedbackTrigger = 0   // 评分按钮：medium impact
    @State private var secondaryFeedbackTrigger = 0 // 次要按钮：light impact
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 14) {
            actionButton(
                title: L10n.Review.stampForgot,
                icon: "arrow.uturn.left.circle.fill",
                tint: .orange,
                rating: .again,
                scale: calculateScale(for: .again)
            )
            .accessibilityHint(L10n.Accessibility.forgotHint)

            Spacer()

            HStack(spacing: 10) {
                Button(
                    action: {
                        secondaryFeedbackTrigger += 1
                        onUndo()
                    },
                    label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isUndoEnabled ? Color.primary : Color.secondary.opacity(0.35))
                            .frame(width: 46, height: 46)
                            .background(controlFill, in: Circle())
                    }
                )
                .buttonStyle(.plain)
                .disabled(!isUndoEnabled)
                .accessibilityLabel(L10n.Accessibility.undo)
                .accessibilityHint(L10n.Accessibility.undoHint)

                Button(
                    action: {
                        onToggleAnswer()
                    },
                    label: {
                        Image(systemName: isAnswerShown ? "eye.slash" : "eye")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isAnswerShown ? Color.secondary : Color.blue)
                            .frame(width: 46, height: 46)
                            .background(controlFill, in: Circle())
                    }
                )
                .buttonStyle(.plain)
                .accessibilityLabel(isAnswerShown ? L10n.Accessibility.hideAnswer : L10n.Accessibility.showAnswer)
            }

            Spacer()

            actionButton(
                title: L10n.Review.stampRemember,
                icon: "checkmark.circle.fill",
                tint: .blue,
                rating: .good,
                scale: calculateScale(for: .good)
            )
            .accessibilityHint(L10n.Accessibility.rememberHint)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .sensoryFeedback(.impact(weight: .medium), trigger: primaryFeedbackTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: secondaryFeedbackTrigger)
    }
    
    // MARK: - Private Helpers
    
    private var controlFill: some ShapeStyle {
        Color(UIColor.secondarySystemGroupedBackground)
    }

    private func actionButton(
        title: String,
        icon: String,
        tint: Color,
        rating: ReviewRating,
        scale: CGFloat
    ) -> some View {
        Button(action: {
            primaryFeedbackTrigger += 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onRate(rating)
            }
        }, label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(tint)
            .frame(minWidth: 104)
            .frame(height: baseHeight)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(tint.opacity(0.18), lineWidth: 1)
            )
            .scaleEffect(scale)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.7), value: scale)
        })
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
    
    // 根据滑动偏移量计算动态缩放比例
    private func calculateScale(for type: ReviewRating) -> CGFloat {
        var progress: CGFloat = 0
        
        switch type {
        case .again: // 左滑（< 0）
            if swipeOffset < 0 {
                progress = min(abs(swipeOffset) / threshold, 1.0)
            }
        case .good: // 右滑（> 0）
            if swipeOffset > 0 {
                progress = min(abs(swipeOffset) / threshold, 1.0)
            }
        default: break
        }
        
        // 基础缩放 1.0 -> 最大缩放 1.4
        return 1.0 + (progress * (maxScale - 1.0))
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        VStack {
            Spacer()
            ReviewActionButtons(
                swipeOffset: 120,
                onRate: { _ in },
                onUndo: {},
                onToggleAnswer: {},
                isUndoEnabled: true,
                isAnswerShown: false
            )
        }
    }
}
