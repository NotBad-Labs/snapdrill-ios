//
//  ReviewView.swift
//  NotBadFeatureReview
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  复习会话界面，进行题目间隔重复复习
//

import SwiftUI
import Observation
import NotBadCore
import NotBadUI
import NotBadData
import SwiftData

/// 复习会话界面
///
/// 这是应用的核心学习界面，实现了基于间隔重复算法（Spaced Repetition）的 Flashcard 复习流。
///
/// ## 核心逻辑

public struct ReviewView: View {
    @Bindable private var router: ReviewRouter
    
    // Data
    @Query private var allItems: [ReviewItemModel]
    @Environment(\.modelContext) private var modelContext
    
    // State
    @State private var workingItems: [ReviewItemModel] = [] // The mutable stack
    @State private var finishedItems: Int = 0
    @State private var undoStack: [ReviewItemModel] = [] // History for Undo
    @State private var initialLoadComplete = false
    @State private var isAnswerShown = false
    
    public init(router: ReviewRouter) {
        self.router = router
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                ReviewBackground()
                
                VStack {
                    if !initialLoadComplete {
                        ProgressView()
                    } else if workingItems.isEmpty && finishedItems == 0 {
                        // Truly empty (No data)
                        ReviewEmptyStateView(
                            icon: "flag.checkered",
                            title: "开启复习之旅",
                            subtitle: "添加第一道错题，系统将为你安排科学的复习计划。",
                            actionTitle: "去录入"
                        ) {
                            NotificationCenter.default.post(name: NSNotification.Name("SwitchToCaptureTab"), object: nil)
                        }
                    } else if workingItems.isEmpty {
                        // Finished all
                        ReviewEmptyStateView(
                            icon: "checkmark.seal.fill",
                            title: "今日复习完成",
                            subtitle: "太棒了！休息一下，明天继续。",
                            actionTitle: "重新开始",
                            action: resetSession
                        )
                    } else {
                        // Content
                        VStack(spacing: 20) {
                            // Header
                            ReviewProgressHeader(current: finishedItems + 1, total: finishedItems + workingItems.count)
                            
                            Spacer()
                            
                            // Card Stack
                            ZStack {
                                // show max 3 cards
                                ForEach(Array(workingItems.prefix(3).reversed()), id: \.id) { item in
                                   // Calculate Index for visual stacking
                                    let index = workingItems.firstIndex(of: item) ?? 0
                                    let isTop = index == 0
                                    
                                    SwipeCard(
                                        content: {
                                            ReviewCardContent(item: item, isAnswerShown: isTop && isAnswerShown)
                                        },
                                        onRemove: { direction in
                                            handleSwipe(direction: direction)
                                        }
                                    )
                                    .allowsHitTesting(isTop) // Only top card interactive
                                    .scaleEffect(scale(for: index))
                                    .offset(y: offset(for: index))
                                    .rotationEffect(.degrees(rotation(for: index)))
                                    .zIndex(Double(workingItems.count - index))
                                    // Action Stamps (Overlay)
                                    .overlay(
                                        GeometryReader { geometry in
                                            let dragOffset = isTop ?
                                                (geometry.frame(in: .global).origin.x 
                                                 - UIScreen.main.bounds.width / 2 
                                                 + geometry.size.width / 2) :
                                                0
                                            
                                            if isTop {
                                                if dragOffset < -50 {
                                                    // Swipe Left (Next/Forget)
                                                    Text("忘记")
                                                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                                                        .foregroundColor(.red)
                                                        .padding()
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(.red, lineWidth: 4)
                                                        )
                                                        .rotationEffect(.degrees(15))
                                                        .offset(x: 80, y: -100)
                                                        .opacity(Double(abs(dragOffset) / 150))
                                                } else if dragOffset > 50 {
                                                    // Swipe Right (Prev/Remember)
                                                    Text("记得")
                                                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                                                        .foregroundColor(.green)
                                                        .padding()
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(.green, lineWidth: 4)
                                                        )
                                                        .rotationEffect(.degrees(-15))
                                                        .offset(x: -80, y: -100)
                                                        .opacity(Double(abs(dragOffset) / 150))
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 500)
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            // Bottom Action (Flip)
                            bottomControl
                                .padding(.bottom, 40)
                                .opacity(workingItems.isEmpty ? 0 : 1)
                        }
                    }
                }
            }
            .navigationTitle("复习")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadData)
        }
    }
    
    @ViewBuilder
    private var bottomControl: some View {
        VStack(spacing: 24) {
             // 1. Action Row: Undo + Answer Toggle
            HStack(spacing: 16) {
                // Undo Button
                Button(action: undoLastSwipe) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3.bold())
                        .foregroundStyle(undoStack.isEmpty ? Color.secondary.opacity(0.3) : Color.orange)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(undoStack.isEmpty)
                
                // Answer Toggle
                Button(action: { withAnimation { isAnswerShown.toggle() } }, label: {
                    HStack {
                        Text(isAnswerShown ? "隐藏答案" : "查看答案")
                        if !isAnswerShown {
                             Image(systemName: "eye")
                        } else {
                             Image(systemName: "eye.slash")
                        }
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(isAnswerShown ? Color.secondary : Color.blue)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                })
            }
            
            // 2. Rating Bar (Always available)
            BinaryRatingBar { rating in
                let direction = (rating == .good) ? 1 : -1
                handleSwipe(direction: direction)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func loadData() {
        // Reload if not initially loaded OR if we are empty (to catch new data generated in Settings)
        if !initialLoadComplete || (workingItems.isEmpty && finishedItems == 0) {
            let now = Date()
            let due = allItems.filter { item in
                guard let next = item.nextReviewAt else { return true }
                return next <= now
            }.sorted { ($0.nextReviewAt ?? Date.distantPast) < ($1.nextReviewAt ?? Date.distantPast) }
            
            // Only update if we found something, to avoid unnecessary state thrashing if truly empty
            // But if previously empty and now empty, no harm.
            workingItems = due
            finishedItems = 0
            undoStack.removeAll() // Clear undo stack on new session
            initialLoadComplete = true
            isAnswerShown = false
        }
    }
    
    private func resetSession() {
        // For verify purpose, just reload
        initialLoadComplete = false
        undoStack.removeAll()
        loadData()
    }
    
    private func handleSwipe(direction: Int) {
        // direction: -1 (Left/Forget), 1 (Right/Remember)
        guard let item = workingItems.first else { return }
        
        withAnimation(.spring(duration: 0.35)) {
            let removed = workingItems.removeFirst()
            undoStack.append(removed) // Push to history
            finishedItems += 1
            isAnswerShown = false
        }
        
        // Update Scheduler
        // Left (-1) = Forget/Again
        // Right (1) = Remember/Good
        let rating: ReviewRating = direction > 0 ? .good : .again
        
        let scheduler = ReviewScheduler()
        let updated = scheduler.scheduleNextReview(for: item.toEntity(), rating: rating)
        item.lastReviewedAt = updated.lastReviewedAt
        item.nextReviewAt = updated.nextReviewAt
        
        try? modelContext.save()
    }
    
    private func undoLastSwipe() {
        guard !undoStack.isEmpty else { return }
        
        withAnimation(.spring(duration: 0.35)) {
            let item = undoStack.removeLast()
            workingItems.insert(item, at: 0)
            finishedItems -= 1
            isAnswerShown = false // Reset state for the card coming back
        }
    }
    
    // MARK: - Visual Math
    
    private func scale(for index: Int) -> CGFloat {
        return 1.0 - CGFloat(index) * 0.05
    }
    
    private func offset(for index: Int) -> CGFloat {
        return CGFloat(index) * 15
    }
    
    private func rotation(for index: Int) -> Double {
        // Top card is always straight
        if index == 0 { return 0 }
        
        // Background cards have randomized rotation for organic "messy pile" look
        // We use the item's ID to keep the rotation consistent for that specific card
        // as it moves up the stack.
        // Formula: simple hash mapping to range [-3, 3] degrees
        guard index < workingItems.count else { return 0 }
        let item = workingItems[index]
        let seed = abs(item.id.hashValue)
        let angle = Double(seed % 7) - 3.0 // -3, -2, -1, 0, 1, 2, 3
        
        // Add a slight multiplier based on depth to fan them out more visually?
        // Or keep it simple. Mainstream apps usually fully random.
        return angle
    }
}
