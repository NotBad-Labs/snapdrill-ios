//
//  HomeView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 首页视图
/// 显示学习概况、最近复习等
struct HomeView: View {
    /// 首页内容类型
    enum Content {
        case main
    }

    /// 协调器引用
    @ObservedObject var coordinator: HomeCoordinator

    init(coordinator: HomeCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            HomeContentView(coordinator: coordinator)
                .navigationTitle("首页")
        }
    }
}

/// 首页内容视图
struct HomeContentView: View {
    let coordinator: HomeCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HomeWelcomeView()
                HomeStatsView()
                HomeRecentActivityView()
            }
        }
    }
}

/// 欢迎区域
struct HomeWelcomeView: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("👋 欢迎使用 NotBad")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("开始你的学习之旅")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

/// 统计区域
struct HomeStatsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学习统计")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 15) {
                StatCard(title: "总题数", value: "0", color: .blue)
                StatCard(title: "已掌握", value: "0", color: .green)
                StatCard(title: "需复习", value: "0", color: .orange)
            }
            .padding(.horizontal)
        }
    }
}

/// 最近活动区域
struct HomeRecentActivityView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最近活动")
                .font(.headline)
                .padding(.horizontal)

            VStack {
                Text("暂无最近活动")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

/// 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    HomeView(coordinator: HomeCoordinator())
}
