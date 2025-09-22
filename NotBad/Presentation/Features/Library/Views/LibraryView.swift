//
//  LibraryView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 题库视图
/// 显示错题集合、分类管理等
struct LibraryView: View {
    /// 题库内容类型
    enum Content {
        case main
    }

    /// 视图模型
    @StateObject var viewModel: LibraryViewModel
    /// 协调器
    @ObservedObject var coordinator: LibraryCoordinator
    /// 应用环境
    @Environment(\.appEnvironment) private var appEnvironment

    init(viewModel: @autoclosure @escaping () -> LibraryViewModel, coordinator: LibraryCoordinator) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            LibraryContentView(viewModel: viewModel)
                .navigationTitle("题库")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(
                            action: {
                                viewModel.navigateToAddItem()
                            },
                            label: {
                                Image(systemName: "plus")
                            }
                        )
                    }
                }
        }
        .onAppear {
            viewModel.onAppear()
            viewModel.configure(errorHandler: appEnvironment.errorHandler)
        }
    }
}

/// 题库内容视图
struct LibraryContentView: View {
    @ObservedObject var viewModel: LibraryViewModel

    var body: some View {
        VStack {
            // 统计信息
            HStack(spacing: 20) {
                LibraryStatCard(title: "总题数", count: viewModel.totalItems, color: .blue)
                LibraryStatCard(title: "已掌握", count: viewModel.reviewedItems, color: .green)
                LibraryStatCard(title: "需复习", count: viewModel.pendingItems, color: .orange)
            }
            .padding()

            // 题目列表
            if viewModel.isLoading {
                ProgressView("加载中...")
                    .padding()
            } else if viewModel.reviewItems.isEmpty {
                Text("暂无题目")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(viewModel.reviewItems, id: \.id) { item in
                            Button(action: {
                                viewModel.navigateToDetail(item)
                            }) {
                                HStack {
                                    Text(item.question)
                                        .font(.body)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
    }
}

/// 题库统计卡片
struct LibraryStatCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack {
            Text("\(count)")
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
    // 预览用假数据
    let coordinator = LibraryCoordinator()
    let mockService = ReviewItemService(repository: InMemoryReviewItemRepository())
    let viewModel = LibraryViewModel(reviewItemService: mockService, coordinator: coordinator)
    return LibraryView(viewModel: viewModel, coordinator: coordinator)
        .withAppEnvironment()
}
