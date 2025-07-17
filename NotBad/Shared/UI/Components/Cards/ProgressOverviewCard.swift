//
//  ProgressOverviewCard.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

struct ProgressOverviewCard: View {
    @Environment(HomeViewModel.self) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今日进度")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(viewModel.todayProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: viewModel.todayProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 0.8)
                
                HStack {
                    Text("今日完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("继续努力!")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // 快速统计
            HStack(spacing: 16) {
                ProgressStatItem(
                    title: "总题数",
                    value: "\(viewModel.quickStats.totalQuestions)",
                    color: .blue
                )
                
                ProgressStatItem(
                    title: "今日复习",
                    value: "\(viewModel.quickStats.reviewedToday)",
                    color: .green
                )
                
                ProgressStatItem(
                    title: "连续天数",
                    value: "\(viewModel.quickStats.streakDays)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProgressStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProgressOverviewCard()
        .environment(HomeViewModel())
        .padding()
}