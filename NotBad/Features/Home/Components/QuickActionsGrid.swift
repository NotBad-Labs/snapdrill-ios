//
//  QuickActionsGrid.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

struct QuickActionsGrid: View {
    @Environment(HomeViewModel.self) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷操作")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "错题本",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    action: {
                        // 跳转到错题本
                    }
                )
                
                QuickActionButton(
                    title: "标签练习",
                    icon: "tag.fill",
                    color: .orange,
                    action: {
                        // 跳转到标签练习
                    }
                )
                
                QuickActionButton(
                    title: "随机练习",
                    icon: "shuffle",
                    color: .purple,
                    action: {
                        // 跳转到随机练习
                    }
                )
                
                QuickActionButton(
                    title: "统计分析",
                    icon: "chart.bar.fill",
                    color: .blue,
                    action: {
                        // 跳转到统计分析
                    }
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    QuickActionsGrid()
        .environment(HomeViewModel())
        .padding()
}