//
//  TodayRecommendationsCard.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

struct TodayRecommendationsCard: View {
    @Environment(HomeViewModel.self) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今日推荐")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("查看全部") {
                    // 查看全部推荐
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if viewModel.isLoading {
                // 加载状态
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RecommendationPlaceholder()
                    }
                }
            } else {
                // 推荐内容
                VStack(spacing: 12) {
                    RecommendationItem(
                        title: "复习昨天的错题",
                        subtitle: "5道题目等待复习",
                        icon: "arrow.clockwise",
                        color: .orange
                    )
                    
                    RecommendationItem(
                        title: "数学专项练习",
                        subtitle: "基于你的薄弱点推荐",
                        icon: "function",
                        color: .blue
                    )
                    
                    RecommendationItem(
                        title: "每日一题挑战",
                        subtitle: "提升你的解题能力",
                        icon: "star.fill",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct RecommendationItem: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct RecommendationPlaceholder: View {
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TodayRecommendationsCard()
        .environment(HomeViewModel())
        .padding()
}