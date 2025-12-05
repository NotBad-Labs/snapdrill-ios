//
//  ReviewView.swift
//  NotBad
//
//  复习视图 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData
import TipKit

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
/// - **键盘快捷键支持** (iPad/Mac)
///
/// ## 键盘快捷键
///
/// | 按键 | 功能 |
/// |------|------|
/// | Space | 显示/隐藏答案 |
/// | 1 | 标记为"不会" |
/// | 2 | 标记为"模糊" |
/// | 3 | 标记为"掌握" |
/// | ← | 上一题 |
/// | → | 下一题 |
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

    /// 所有错题数据（持久化模型）
    @Query(sort: \ReviewItemModel.createdAt, order: .reverse)
    private var allModels: [ReviewItemModel]
    
    /// 将持久化模型转换为领域实体
    private var allItems: [ReviewItem] {
        allModels.map { ReviewItemMapper.toEntity(from: $0) }
    }

    /// 数据上下文
    @Environment(\.modelContext) private var modelContext

    /// 视图模型
    @State private var viewModel = ReviewViewModel()
    
    /// 答案显示状态（提升到此处以支持键盘控制）
    @State private var showAnswer = false
    
    /// 键盘快捷键提示是否已显示
    @State private var hasShownKeyboardTip = false

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
                    VStack(spacing: 0) {
                        // 首次复习提示
                        TipView(ReviewGestureTip(), arrowEdge: .bottom)
                            .tipBackground(Color(.secondarySystemBackground))
                            .padding(.horizontal)
                        
                        ReviewContent(
                            items: reviewItems,
                            currentIndex: $bindableViewModel.currentIndex,
                            showAnswer: $showAnswer,
                            onMasteryUpdate: handleMastery
                        )
                    }
                }
            }
            .navigationTitle("review_title")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .onChange(of: viewModel.currentIndex) { _, _ in
                // 切换卡片时重置答案显示状态
                showAnswer = false
            }
            .alert("review_complete_title", isPresented: $bindableViewModel.showCompletionAlert) {
                Button("review_complete_button") {
                    viewModel.reset()
                }
            } message: {
                Text("review_complete_message \(viewModel.reviewedCount)")
            }
            // MARK: - Keyboard Shortcuts (iPad/Mac)
            .focusable()
            .focusEffectDisabled()
            .onKeyPress(.space) {
                withAnimation(DesignTokens.Animation.spring) {
                    showAnswer.toggle()
                }
                return .handled
            }
            .onKeyPress(keys: [.init("1"), .init("2"), .init("3")]) { press in
                handleKeyboardMastery(key: press.characters)
                return .handled
            }
            .onKeyPress(.leftArrow) {
                withAnimation {
                    viewModel.moveToPrevious()
                }
                return .handled
            }
            .onKeyPress(.rightArrow) {
                withAnimation {
                    viewModel.moveToNext(totalCount: reviewItems.count)
                }
                return .handled
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
    
    /// 处理键盘掌握度快捷键
    private func handleKeyboardMastery(key: String) {
        guard viewModel.currentIndex < reviewItems.count else { return }
        
        let level: MasteryLevel
        switch key {
        case "1":
            level = .none  // 不会
        case "2":
            level = .glimpse  // 模糊
        case "3":
            level = .mastered  // 掌握
        default:
            return
        }
        
        handleMastery(index: viewModel.currentIndex, level: level)
    }
}

// MARK: - Preview

#Preview("Review View") {
    ReviewView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
