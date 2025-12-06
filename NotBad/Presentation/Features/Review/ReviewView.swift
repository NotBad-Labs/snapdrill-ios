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
/// ## 架构设计
///
/// 使用 ViewModel + Use Cases 获取数据，不直接访问 SwiftData
struct ReviewView: View {

    // MARK: - Properties

    /// 依赖工厂
    @Environment(\.dependencyFactory) private var dependencyFactory

    /// 视图模型
    @State private var viewModel: ReviewViewModel?
    
    /// 答案显示状态（提升到此处以支持键盘控制）
    @State private var showAnswer = false
    
    /// 键盘快捷键提示是否已显示
    @State private var hasShownKeyboardTip = false

    // MARK: - Computed Properties

    /// 需要复习的错题
    private var reviewItems: [ReviewItem] {
        guard let viewModel else { return [] }
        return viewModel.generateReviewQueue(from: viewModel.items)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    reviewContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("review_title")
            .navigationBarTitleDisplayMode(.large)
            .task {
                // 初始化 ViewModel 并加载数据
                if viewModel == nil, let factory = dependencyFactory {
                    viewModel = factory.makeReviewViewModel()
                }
                await viewModel?.loadItems()
            }
        }
    }
    
    // MARK: - Review Content
    
    @ViewBuilder
    private func reviewContent(viewModel: ReviewViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel
        
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
                        onMasteryUpdate: { index, level in
                            handleMastery(index: index, level: level, viewModel: viewModel)
                        }
                    )
                }
            }
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
            handleKeyboardMastery(key: press.characters, viewModel: viewModel)
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

    // MARK: - Actions

    /// 处理掌握度评估
    private func handleMastery(index: Int, level: MasteryLevel, viewModel: ReviewViewModel) {
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
    private func handleKeyboardMastery(key: String, viewModel: ReviewViewModel) {
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
        
        handleMastery(index: viewModel.currentIndex, level: level, viewModel: viewModel)
    }
}

// MARK: - Preview

#Preview("Review View") {
    ReviewView()
}
