//
//  HomeView.swift
//  NotBad
//
//  Created by Yiming Liao on 10/7/25.
//

import SwiftUI

/// 主页视图
///
/// 职责：
/// - 展示主要功能入口
/// - 快速访问常用功能
/// - 显示统计信息
@MainActor
struct HomeView: View {
    
    // MARK: - Properties
    
    @Environment(AppCoordinator.self) private var coordinator
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 功能入口
                VStack(spacing: 16) {
                    NavigationButton(
                        icon: "camera.fill",
                        title: "拍照识别",
                        subtitle: "快速录入错题",
                        color: .blue
                    ) {
                        coordinator.presentFullScreenCover(.camera)
                    }
                    
                    NavigationButton(
                        icon: "list.bullet.rectangle.fill",
                        title: "错题列表",
                        subtitle: "查看所有错题",
                        color: .green
                    ) {
                        coordinator.push(.questionList)
                    }
                    
                    NavigationButton(
                        icon: "chart.bar.fill",
                        title: "学习统计",
                        subtitle: "分析学习情况",
                        color: .orange
                    ) {
                        // 将来实现
                    }
                }
                .padding()
            }
        }
        .navigationTitle("NotBad 错题本")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    coordinator.presentSheet(.settings)
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

// MARK: - Navigation Button

/// 导航按钮组件
@MainActor
struct NavigationButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
                    .frame(width: 60, height: 60)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppCoordinator())
    }
}
