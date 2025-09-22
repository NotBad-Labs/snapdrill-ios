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
                .navigationDestination(for: LibraryCoordinator.LibraryRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        LibraryDetailView(itemId: id, coordinator: coordinator)
                    case .practice:
                        PracticeModeView(coordinator: coordinator)
                    }
                }
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

// MARK: - 题目详情视图（真实实现）
struct LibraryDetailView: View {
    @Environment(\.appEnvironment) private var appEnvironment
    @StateObject private var viewModel: LibraryDetailViewModel

    init(itemId: String, coordinator: LibraryCoordinator) {
        // 通过 ServiceContainer 构建 ViewModel（与列表同源）
        let vm = LibraryDetailViewModel(
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
                            WrapTagsView(tags: Array(item.tags))
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
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            Task { await viewModel.deleteCurrentItem() }
                        } label: {
                            Image(systemName: "trash")
                        }

                        Button {
                            viewModel.startPractice()
                        } label: {
                            Image(systemName: "play.circle")
                        }
                    }
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
private struct LibraryDetailPreviewContainer: View {
    @State private var itemId: String? = nil
    private let coordinator = LibraryCoordinator()

    var body: some View {
        Group {
            if let id = itemId {
                LibraryDetailView(itemId: id, coordinator: coordinator)
                    .withAppEnvironment()
            } else {
                ProgressView("准备预览数据…")
                    .task {
                        let service = ServiceContainer.shared.reviewItemService
                        do {
                            let createdId = try await service.createReviewItem(
                                question: "预览：勾股定理是什么？",
                                answer: "a² + b² = c²",
                                subject: ReviewItem.Subject.math.rawValue,
                                difficulty: ReviewItem.Difficulty.easy.rawValue,
                                tags: ["几何", "公式"],
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

#Preview("Library Detail (Mock)") {
    LibraryDetailPreviewContainer()
}
#endif

private struct WrapTagsView: View {
    let tags: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标签")
                .font(.headline)
            FlowLayout(alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
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
}

// 一个简单的流式布局（标签换行）
private struct FlowLayout<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        // 简化：交给 SwiftUI 自动换行（iOS 17+ 可用的 VStack+Wrap，这里采用最简方案）
        // 对于演示目的，直接使用多行文本不需要复杂布局
        HStack { content() }
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 占位视图：练习模式
struct PracticeModeView: View {
    let coordinator: LibraryCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("练习模式")
                .font(.title2)
                .fontWeight(.semibold)
            Text("这里将展示练习模式的内容（占位）")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("练习")
    }
}
