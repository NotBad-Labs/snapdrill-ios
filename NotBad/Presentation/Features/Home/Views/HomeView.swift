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
                .navigationDestination(for: HomeCoordinator.HomeRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        HomeDetailView(itemId: id, coordinator: coordinator)
                    }
                }
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

// MARK: - 首页详情视图（真实实现）
struct HomeDetailView: View {
    @Environment(\.appEnvironment) private var appEnvironment
    @StateObject private var viewModel: HomeDetailViewModel

    init(itemId: String, coordinator: HomeCoordinator) {
        let vm = HomeDetailViewModel(
            reviewItemService: ServiceContainer.shared.reviewItemServicing,
            itemId: itemId,
            coordinator: coordinator
        )
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let item = viewModel.item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(item.question)
                            .font(.title3)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("答案")
                                .font(.headline)
                            Text(item.answer)
                                .font(.body)
                                .foregroundColor(.primary)
                        }

                        Divider()

                        HStack(spacing: 12) {
                            Label(item.subject.rawValue, systemImage: "book")
                            Label(item.difficulty.rawValue, systemImage: "trophy")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        if !item.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("标签")
                                    .font(.headline)
                                // 简单标签渲染（避免依赖其他文件的私有视图）
                                let tagsArray = Array(item.tags)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 8)], spacing: 8) {
                                    ForEach(tagsArray, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        if let notes = item.notes {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("备注")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("未找到该题目或ID无效")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("详情")
        .task { @MainActor in
            viewModel.configure(errorHandler: appEnvironment.errorHandler)
            await viewModel.load()
        }
    }
}

// MARK: - 预览（使用共享 ServiceContainer 注入假数据）
#if DEBUG
@MainActor
private struct HomeDetailPreviewContainer: View {
    @State private var itemId: String? = nil
    private let coordinator = HomeCoordinator()

    var body: some View {
        Group {
            if let id = itemId {
                HomeDetailView(itemId: id, coordinator: coordinator)
                    .withAppEnvironment()
            } else {
                ProgressView("准备预览数据…")
                    .task {
                        let service = ServiceContainer.shared.reviewItemService
                        do {
                            let createdId = try await service.createReviewItem(
                                question: "预览：牛顿第二定律是什么？",
                                answer: "F = m·a",
                                subject: ReviewItem.Subject.physics.rawValue,
                                difficulty: ReviewItem.Difficulty.medium.rawValue,
                                tags: ["力学", "基础"],
                                notes: "用于 SwiftUI 预览"
                            )
                            self.itemId = createdId.value.uuidString
                        } catch {
                            print("Preview seed error: \(error)")
                        }
                    }
            }
        }
    }
}

#Preview("Home Detail (Mock)") {
    HomeDetailPreviewContainer()
}
#endif
