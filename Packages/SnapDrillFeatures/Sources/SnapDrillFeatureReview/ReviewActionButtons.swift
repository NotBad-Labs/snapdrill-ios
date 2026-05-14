//
//  ReviewActionButtons.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  复习界面的底部操作按钮组。
//  采用 iOS 电话界面的大圆形设计 (Big Circle Style)。
//  支持与卡片滑动的联动动画 (Interactive Linkage)。
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
    private let baseSize: CGFloat = 80
    private let maxScale: CGFloat = 1.4
    private let threshold: CGFloat = 100 // 触发最大缩放的阈值

    // 触觉反馈触发器（递增计数器确保每次都能触发变化）
    @State private var primaryFeedbackTrigger = 0   // 评分按钮：medium impact
    @State private var secondaryFeedbackTrigger = 0 // 次要按钮：light impact
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // [忘了] - 红色叉号
            // 左滑（负偏移）时放大
            actionButton(
                icon: "xmark",
                color: .red,
                rating: .again,
                scale: calculateScale(for: .again)
            )
            .accessibilityLabel(L10n.Review.stampForgot)
            .accessibilityHint(L10n.Accessibility.forgotHint)
            
            Spacer()
            
            // 中间控件（集成式）
            HStack(spacing: 24) {
                // 撤销
                Button(
                    action: {
                        secondaryFeedbackTrigger += 1
                        onUndo()
                    },
                    label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isUndoEnabled ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                )
                .disabled(!isUndoEnabled)
                .accessibilityLabel(L10n.Accessibility.undo)
                .accessibilityHint(L10n.Accessibility.undoHint)

                // 切换答案显示
                Button(
                    action: {
                        // 触觉反馈由 ReviewView.sensoryFeedback(trigger: vm.isAnswerShown) 统一处理
                        onToggleAnswer()
                    },
                    label: {
                        Image(systemName: isAnswerShown ? "eye.slash" : "eye")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isAnswerShown ? Color.secondary : Color.blue)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                )
                .accessibilityLabel(isAnswerShown ? L10n.Accessibility.hideAnswer : L10n.Accessibility.showAnswer)
            }
            
            Spacer()
            
            // [记得] - 绿色对勾
            // 右滑（正偏移）时放大
            actionButton(
                icon: "checkmark",
                color: .green,
                rating: .good,
                scale: calculateScale(for: .good)
            )
            .accessibilityLabel(L10n.Review.stampRemember)
            .accessibilityHint(L10n.Accessibility.rememberHint)
        }
        .padding(.horizontal, 48) // 加大外边距防止按钮贴边
        .padding(.bottom, 10)
        // HIG：评分按钮用 medium（决定性操作），撤销用 light
        .sensoryFeedback(.impact(weight: .medium), trigger: primaryFeedbackTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: secondaryFeedbackTrigger)
    }
    
    // MARK: - Private Helpers
    
    private func actionButton(icon: String, color: Color, rating: ReviewRating, scale: CGFloat) -> some View {
        Button(action: {
            primaryFeedbackTrigger += 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onRate(rating)
            }
        }, label: {
            ZStack {
                Circle()
                    .fill(color)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .bold)) // 粗体图标
                    .foregroundStyle(.white)
            }
            .frame(width: baseSize, height: baseSize)
            .shadow(color: color.opacity(0.4), radius: 15, x: 0, y: 8) // 光晕效果
            .scaleEffect(scale) // 与滑动联动
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.7), value: scale)
        })
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
