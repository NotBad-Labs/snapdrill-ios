//
//  DiscoveryView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 发现视图
/// 展示推荐内容、学习资源等
struct DiscoveryView: View {
    /// 发现内容类型
    enum Content {
        case main
    }

    /// 协调器引用
    @ObservedObject var coordinator: DiscoveryCoordinator

    init(coordinator: DiscoveryCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            DiscoveryContentView(coordinator: coordinator)
                .navigationTitle("发现")
                .navigationDestination(for: DiscoveryCoordinator.DiscoveryRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        DiscoveryDetailView(itemId: id, coordinator: coordinator)
                    }
                }
        }
    }
}

/// 发现页面内容视图
struct DiscoveryContentView: View {
    let coordinator: DiscoveryCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DiscoveryFeaturesSection(coordinator: coordinator)
                DiscoveryResourcesSection(coordinator: coordinator)
            }
        }
    }
}

/// 推荐功能区域
struct DiscoveryFeaturesSection: View {
    let coordinator: DiscoveryCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("推荐功能")
                .font(.headline)
                .padding(.horizontal)

            DiscoveryFeaturesGrid(coordinator: coordinator)
                .padding(.horizontal)
        }
    }
}

/// 推荐功能网格
struct DiscoveryFeaturesGrid: View {
    let coordinator: DiscoveryCoordinator

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            DiscoveryCard(
                icon: "brain.head.profile",
                title: "智能分析",
                subtitle: "分析学习薄弱点",
                color: .purple
            )

            DiscoveryCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "学习统计",
                subtitle: "查看学习进度",
                color: .blue
            )

            DiscoveryCard(
                icon: "timer",
                title: "定时练习",
                subtitle: "设置学习提醒",
                color: .orange
            )

            DiscoveryCard(
                icon: "person.2.fill",
                title: "学习小组",
                subtitle: "与同学一起学习",
                color: .green
            )
        }
    }
}

/// 学习资源区域
struct DiscoveryResourcesSection: View {
    let coordinator: DiscoveryCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学习资源")
                .font(.headline)
                .padding(.horizontal)

            VStack {
                Text("更多资源即将上线")
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

/// 发现卡片
struct DiscoveryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(title)
                .font(.headline)
                .fontWeight(.medium)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(color.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DiscoveryView(coordinator: DiscoveryCoordinator())
}

// MARK: - 占位视图：发现详情
struct DiscoveryDetailView: View {
    let itemId: String
    let coordinator: DiscoveryCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("发现详情")
                .font(.title2)
                .fontWeight(.semibold)
            Text("ID: \(itemId)")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("详情")
    }
}
