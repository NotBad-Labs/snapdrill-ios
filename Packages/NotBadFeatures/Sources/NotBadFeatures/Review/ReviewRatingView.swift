//
//  ReviewRatingView.swift
//  NotBadFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  底部评分栏，提供 '忘记', '模糊', '熟悉' 等操作反馈。
//

import SwiftUI
import NotBadCore

struct BinaryRatingBar: View {
    let onRate: (ReviewRating) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Forget / Again
            Button(action: { onRate(.again) }, label: {
                VStack(spacing: 2) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                    Text(L10n.Review.forgot)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.red.opacity(0.1))
                .foregroundStyle(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            })
            
            // Remember / Good
            Button(action: { onRate(.good) }, label: {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                    Text(L10n.Review.remember)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.green.opacity(0.1))
                .foregroundStyle(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
            })
        }
        .padding(.horizontal, 24)
    }
}

struct ReviewActionPill: View {
    let title: String
    let rating: ReviewRating
    let color: Color
    let action: (ReviewRating) -> Void
    
    /// 简化的时间描述（基于评分类型）
    private var timeHint: String {
        switch rating {
        case .again: return "10分钟"
        case .hard: return "1天"
        case .good: return "1-6天"
        case .easy: return "更长"
        }
    }
    
    var body: some View {
        Button(action: { action(rating) }, label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(timeHint)
                    .font(.caption2)
                    .opacity(0.8)
            }
            .frame(width: 80, height: 60)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        })
    }
}

#Preview {
    VStack(spacing: 40) {
        BinaryRatingBar(onRate: { _ in })
        
        HStack {
            ReviewActionPill(title: L10n.Review.forgot, rating: .again, color: .red, action: { _ in })
            ReviewActionPill(title: L10n.Review.hard, rating: .hard, color: .orange, action: { _ in })
            ReviewActionPill(title: L10n.Review.good, rating: .good, color: .green, action: { _ in })
            ReviewActionPill(title: L10n.Review.easy, rating: .easy, color: .blue, action: { _ in })
        }
    }
    .padding()
}
