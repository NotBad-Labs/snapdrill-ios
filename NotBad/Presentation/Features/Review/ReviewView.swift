//
//  ReviewView.swift
//  NotBad
//
//  复习视图 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData

// MARK: - ReviewView

/// 复习视图
///
/// 提供卡片式复习界面，用户可以通过滑动浏览需要复习的错题，
/// 并根据掌握程度进行自我评估。
///
/// ## 功能特性
///
/// - 卡片式错题浏览
/// - 自我评估（不会/模糊/掌握）
/// - 复习进度追踪
/// - 复习完成统计
///
/// ## 使用示例
///
/// ```swift
/// ReviewView()
///     .modelContainer(for: ReviewItem.self)
/// ```
///
/// ## 复习算法
///
/// 根据用户的自我评估更新掌握度：
/// - 不会：掌握度重置为"未掌握"
/// - 模糊：掌握度设为"一知半解"
/// - 掌握：掌握度提升到"完全掌握"
struct ReviewView: View {

    // MARK: - Properties

    /// 所有错题数据
    @Query(sort: \ReviewItem.createdAt, order: .reverse)
    private var allItems: [ReviewItem]

    /// 数据上下文
    @Environment(\.modelContext) private var modelContext

    /// 视图模型
    @State private var viewModel = ReviewViewModel()

    // MARK: - Computed Properties

    /// 需要复习的错题
    private var reviewItems: [ReviewItem] {
        viewModel.generateReviewQueue(from: allItems)
    }

    // MARK: - Body

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        NavigationStack {
            ZStack {
                if reviewItems.isEmpty {
                    EmptyReviewState()
                } else {
                    ReviewContent(
                        items: reviewItems,
                        currentIndex: $bindableViewModel.currentIndex,
                        onMasteryUpdate: handleMastery
                    )
                }
            }
            .navigationTitle("review_title")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .alert("review_complete_title", isPresented: $bindableViewModel.showCompletionAlert) {
                Button("review_complete_button") {
                    viewModel.reset()
                }
            } message: {
                Text("review_complete_message \(viewModel.reviewedCount)")
            }
        }
    }

    // MARK: - Actions

    /// 处理掌握度评估
    private func handleMastery(index: Int, level: MasteryLevel) {
        guard index < reviewItems.count else { return }

        // 触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation {
            viewModel.handleMasteryUpdate(for: reviewItems[index], level: level)
            viewModel.moveToNext(totalCount: reviewItems.count)
        }
    }
}

// MARK: - Preview

#Preview("Review View") {
    ReviewView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
