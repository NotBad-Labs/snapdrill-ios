//
//  ReviewView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
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
public struct ReviewView: View {

    // MARK: - Properties
    
    @Bindable private var router: ReviewRouter
    @Environment(\.repositories) private var repositories
    @State private var viewModel: ReviewViewModel?

    // MARK: - Initialization

    /// 创建复习会话视图
    /// - Parameter router: 注入的路由器
    public init(router: ReviewRouter) {
        self.router = router
    }

    // MARK: - Body

    /// 复习会话界面的视图层次
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                Color(UIColor.secondarySystemBackground)
                    .ignoresSafeArea()

                if let vm = viewModel {
                    reviewContent(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .task {
                // 先确保 ViewModel 存在（注册通知订阅），再加载数据
                if viewModel == nil {
                    viewModel = ReviewViewModel(repository: repositories.review)
                }
                viewModel?.startObservingDataChanges()
                await viewModel?.loadDataAsync()
            }
            .onDisappear {
                viewModel?.cancelObserving()
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
                ReviewSessionSummaryView(
                    goodCount: vm.sessionGoodCount,
                    againCount: vm.sessionAgainCount,
                    onDismiss: {
                        Task {
                            await vm.loadDataAsync()
                            withAnimation { vm.phase = .idle }
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .toolbar(vm.phase == .reviewing ? .hidden : .visible, for: .navigationBar)
        .toolbar(vm.phase == .reviewing ? .hidden : .visible, for: .tabBar)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: vm.phase)
        // HIG：完成整组复习是正向结果，用 success 反馈强化成就感
        .sensoryFeedback(.success, trigger: vm.phase) { _, newPhase in
            newPhase == .finished
        }
        .alert(L10n.Review.pauseAlertTitle, isPresented: Binding(get: { vm.showPauseAlert }, set: { vm.showPauseAlert = $0 })) {
            Button(L10n.Review.pauseContinue, role: .cancel) { }
            Button(L10n.Review.pauseConfirm, role: .destructive) {
                Task {
                    await vm.quitSession()
                }
            }
        } message: {
            Text(L10n.Review.pauseMessage)
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

            // Card Stack
            ZStack {
                ForEach(Array(vm.workingItems.prefix(3).reversed())) { item in
                    let index = vm.workingItems.firstIndex(where: { $0.id == item.id }) ?? 0
                    let isTop = index == 0

                    SwipeCard(
                        content: {
                            ZStack {
                                ReviewCardFactory.makeFront(for: item)
                                    .opacity(vm.isAnswerShown && isTop ? 0 : 1)
                                    .rotation3DEffect(.degrees(vm.isAnswerShown && isTop ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                                
                                ReviewCardFactory.makeBack(for: item)
                                    .opacity(vm.isAnswerShown && isTop ? 1 : 0)
                                    .rotation3DEffect(.degrees(vm.isAnswerShown && isTop ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                            }
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
            // HIG：卡片翻转用 light，符合翻动物理感知
            .sensoryFeedback(.impact(weight: .light), trigger: vm.isAnswerShown)

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
                    stampLabel(L10n.Review.stampForgot, color: .red, rotation: 15, xOffset: 80)
                        .opacity(Double(abs(dragOffset) / 200))
                } else if dragOffset > 50 {
                    stampLabel(L10n.Review.stampRemember, color: .green, rotation: -15, xOffset: -80)
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
}
