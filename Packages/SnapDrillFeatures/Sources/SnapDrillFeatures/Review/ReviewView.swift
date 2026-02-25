//
//  ReviewView.swift
//  SnapDrillFeatureReview
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  复习会话界面（纯渲染层）— 业务逻辑已迁移至 ReviewViewModel
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillData

/// 复习会话界面
///
/// 纯渲染层，通过 `ReviewViewModel` 驱动所有状态变化。
/// 实现基于间隔重复算法（SM-2）的 Flashcard 复习流。
public struct ReviewView: View {

    // MARK: - Dependencies

    @Bindable private var router: ReviewRouter
    @Environment(\.repositories) private var repos
    @State private var viewModel: ReviewViewModel?

    // MARK: - Initialization

    public init(router: ReviewRouter) {
        self.router = router
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                ReviewBackground()

                if let vm = viewModel {
                    reviewContent(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .task {
                if viewModel == nil {
                    // 使用已注入的 repositories 容器
                    let manager = ReviewSessionManager(repository: repos.review)
                    let vm = ReviewViewModel(sessionManager: manager)
                    await vm.loadDataAsync()
                    viewModel = vm
                } else {
                    await viewModel?.loadDataAsync()
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func reviewContent(vm: ReviewViewModel) -> some View {
        ZStack {
            switch vm.phase {
            case .loading:
                ProgressView()

            case .idle:
                ReviewDashboardView(
                    pendingCount: vm.reviewQueue.count,
                    reviewedCount: vm.reviewedTodayCount,
                    totalItemsCount: vm.totalItemsCount,
                    onStart: { withAnimation { vm.startSession() } },
                    onEnter: { router.onNavigateToCapture?() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))

            case .reviewing:
                reviewSessionView(vm: vm)
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))

            case .finished:
                ReviewEmptyStateView(
                    icon: "checkmark.seal.fill",
                    title: "今日复习完成",
                    subtitle: "太棒了！休息一下，明天继续。",
                    actionTitle: "好的",
                    action: {
                        vm.loadData()
                        withAnimation { vm.phase = .idle }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .toolbar(vm.phase == .reviewing ? .hidden : .visible, for: .navigationBar)
        .toolbar(vm.phase == .reviewing ? .hidden : .visible, for: .tabBar)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: vm.phase)
        .alert("确认暂停复习？", isPresented: Binding(get: { vm.showPauseAlert }, set: { vm.showPauseAlert = $0 })) {
            Button("继续", role: .cancel) { }
            Button("暂停", role: .destructive) {
                Task {
                    await vm.quitSession()
                }
            }
        } message: {
            Text("当前进度将保存，您可以稍后继续。")
        }
    }

    // MARK: - Review Session View

    @ViewBuilder
    private func reviewSessionView(vm: ReviewViewModel) -> some View {
        VStack(spacing: 20) {
            ReviewProgressHeader(
                current: vm.sessionStartReviewedCount + vm.finishedItems + 1,
                total: vm.sessionStartReviewedCount + vm.finishedItems + vm.workingItems.count,
                onPause: { vm.showPauseAlert = true }
            )

            Spacer()

            // Card Stack（最多渲染 3 张）
            ZStack {
                ForEach(Array(vm.workingItems.prefix(3).reversed()), id: \.id) { item in
                    let index = vm.workingItems.firstIndex(of: item) ?? 0
                    let isTop = index == 0

                    SwipeCard(
                        content: {
                            ReviewCardFactory.makeFront(for: item)
                                .padding(.horizontal)
                                .padding(.vertical, 32)
                                .onTapGesture {
                                    if isTop {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                            vm.toggleAnswer()
                                        }
                                    }
                                }
                        },
                        onRemove: { direction in
                            withAnimation(.spring(duration: 0.35)) {
                                vm.handleSwipeCompletion(direction: direction)
                            }
                        },
                        externalSwipe: isTop
                            ? Binding(get: { vm.swipeTrigger }, set: { vm.swipeTrigger = $0 })
                            : .constant(nil),
                        onSwipeProgress: isTop ? { offset in
                            vm.currentSwipeOffset = offset
                        } : nil
                    )
                    .allowsHitTesting(isTop)
                    .scaleEffect(cardScale(for: index))
                    .offset(y: cardOffset(for: index))
                    .rotationEffect(.degrees(cardRotation(for: item, index: index, vm: vm)))
                    .zIndex(Double(vm.workingItems.count - index))
                    .overlay(actionStampOverlay(isTop: isTop, vm: vm))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 12)

            bottomControl(vm: vm)
                .padding(.bottom, 40)
        }
    }

    // MARK: - Bottom Control

    private func bottomControl(vm: ReviewViewModel) -> some View {
        ReviewActionButtons(
            swipeOffset: vm.currentSwipeOffset,
            onRate: { rating in
                vm.triggerButtonRating(rating == .good ? 1 : -1)
            },
            onUndo: {
                withAnimation(.spring(duration: 0.35)) {
                    vm.undoLastSwipe()
                }
            },
            onToggleAnswer: {
                withAnimation { vm.toggleAnswer() }
            },
            isUndoEnabled: vm.isUndoEnabled,
            isAnswerShown: vm.isAnswerShown
        )
        .frame(height: 100)
    }

    // MARK: - Action Stamp Overlay

    @ViewBuilder
    private func actionStampOverlay(isTop: Bool, vm: ReviewViewModel) -> some View {
        GeometryReader { geometry in
            let globalFrame = geometry.frame(in: .global)
            let dragOffset = isTop
                ? (globalFrame.origin.x - globalFrame.midX + geometry.size.width / 2)
                : 0

            if isTop {
                if dragOffset < -50 {
                    stampLabel("忘记", color: .red, rotation: 15, xOffset: 80)
                        .opacity(Double(abs(dragOffset) / 200))
                } else if dragOffset > 50 {
                    stampLabel("记得", color: .green, rotation: -15, xOffset: -80)
                        .opacity(Double(abs(dragOffset) / 200))
                }
            }
        }
    }

    private func stampLabel(_ text: String, color: Color, rotation: Double, xOffset: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 40, weight: .heavy, design: .rounded))
            .foregroundColor(color)
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 4))
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: -100)
    }

    // MARK: - Visual Math

    private func cardScale(for index: Int) -> CGFloat {
        1.0 - CGFloat(index) * 0.05
    }

    private func cardOffset(for index: Int) -> CGFloat {
        CGFloat(index) * 15
    }

    private func cardRotation(for item: ReviewItemModel, index: Int, vm: ReviewViewModel) -> Double {
        guard index > 0, index < vm.workingItems.count else { return 0 }
        let seed = abs(item.id.hashValue)
        return Double(seed % 7) - 3.0
    }
}

// MARK: - Preview

#Preview {
    ReviewView(router: ReviewRouter())
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
