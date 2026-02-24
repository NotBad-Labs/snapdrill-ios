//
//  ReviewView.swift
//  NotBadFeatureReview
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
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
    // State Machine
    enum ReviewPhase {
        case loading
        case idle        // Dashboard
        case reviewing   // Card Stack
        case finished    // Summary
    }
    
    @State private var phase: ReviewPhase = .loading
    
    // Data
    @Query private var allItems: [ReviewItemModel]
    @Environment(\.modelContext) private var modelContext
    
    // Session State
    @State private var reviewQueue: [ReviewItemModel] = [] // Full queue for today
    @State private var workingItems: [ReviewItemModel] = [] // Current working stack
    @State private var finishedItems: Int = 0
    @State private var undoStack: [ReviewItemModel] = []
    @State private var isAnswerShown = false
    @State private var swipeTrigger: Int?
    @State private var showPauseAlert = false
    @State private var reviewedTodayCount = 0 // Track for Dashboard Stats
    @State private var sessionStartReviewedCount = 0
    @State private var isProcessingSwipe = false
    @State private var lastInteractionTime: Date = .distantPast
    
    // UI State
    @State private var currentSwipeOffset: CGFloat = 0 // Interactive Linkage
    
    private let minInteractionInterval: TimeInterval = 0.55 // Slightly longer than card animation (0.5s)
    
    public init(router: ReviewRouter) {
        self.router = router
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                ReviewBackground()
                
                switch phase {
                case .loading:
                    ProgressView()
                        .onAppear(perform: loadData)
                        
                case .idle:
                    ReviewDashboardView(
                        pendingCount: reviewQueue.count,
                        reviewedCount: reviewedTodayCount,
                        totalItemsCount: allItems.count,
                        onStart: startSession,
                        onEnter: { router.onNavigateToCapture?() }
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    
                case .reviewing:
                    reviewSessionView
                        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
                    
                case .finished:
                    ReviewEmptyStateView(
                        icon: "checkmark.seal.fill",
                        title: "今日复习完成",
                        subtitle: "太棒了！休息一下，明天继续。",
                        actionTitle: "好的",
                        action: { 
                            // Must reload to reflect the "done" status in dashboard
                            loadData()
                            withAnimation { phase = .idle } 
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            // Immersive Mode
            .toolbar(phase == .reviewing ? .hidden : .visible, for: .navigationBar)
            .toolbar(phase == .reviewing ? .hidden : .visible, for: .tabBar)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: phase)
            .alert("确认暂停复习？", isPresented: $showPauseAlert) {
                Button("继续", role: .cancel) { }
                Button("暂停", role: .destructive) {
                    quitSession()
                }
            } message: {
                Text("当前进度将保存，您可以稍后继续。")
            }
            .onAppear {
                loadData()
            }
            .onChange(of: allItems) { _, _ in
                loadData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var reviewSessionView: some View {
        VStack(spacing: 20) {
            // Header
            // Header (Immersive)
            ReviewProgressHeader(
                current: sessionStartReviewedCount + finishedItems + 1,
                total: sessionStartReviewedCount + finishedItems + workingItems.count,
                onPause: { showPauseAlert = true }
            )
            
            Spacer() // Top Spacer (Push down slightly)
            
            // Card Stack - Maximized
            ZStack {
               // show max 3 cards
               ForEach(Array(workingItems.prefix(3).reversed()), id: \.id) { item in
                  // Calculate Index for visual stacking
                   let index = workingItems.firstIndex(of: item) ?? 0
                   let isTop = index == 0
                   
                   SwipeCard(
                       content: {
                           FlipView(
                               isFlipped: isTop && isAnswerShown,
                               front: { 
                                   ReviewCardFactory.makeFront(for: item)
                                       .padding(.horizontal)
                                       .padding(.vertical, 32) // Reduced internal padding
                               },
                               back: { 
                                   ReviewCardFactory.makeBack(for: item)
                                       .padding(.horizontal)
                                       .padding(.vertical, 32)
                               }
                           )
                           // Tap to flip
                           .onTapGesture {
                               if isTop {
                                   withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                       isAnswerShown.toggle()
                                   }
                               }
                           }
                       },
                       onRemove: { direction in
                           currentSwipeOffset = 0 // Reset on removal
                           handleSwipeCompletion(direction: direction)
                       },
                       externalSwipe: isTop ? $swipeTrigger : .constant(nil),
                       onSwipeProgress: isTop ? { offset in
                           currentSwipeOffset = offset
                       } : nil
                   )
                   .allowsHitTesting(isTop) // Only top card interactive
                   .scaleEffect(scale(for: index))
                   .offset(y: offset(for: index))
                   .rotationEffect(.degrees(rotation(for: index))) // Base stack rotation
                   .zIndex(Double(workingItems.count - index))
                   // Action Stamps Overlay
                   .overlay(
                       GeometryReader { geometry in
                           let dragOffset = isTop ?
                               (geometry.frame(in: .global).origin.x 
                                - UIScreen.main.bounds.width / 2 
                                + geometry.size.width / 2) :
                               0
                           
                           // Action Stamps
                           if isTop {
                               if dragOffset < -50 {
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
                                       .opacity(Double(abs(dragOffset) / 200))
                               } else if dragOffset > 50 {
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
                                       .opacity(Double(abs(dragOffset) / 200))
                               }
                           }
                       }
                   )
               }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Flex fill
            .padding(.horizontal, 12) // Minimal margins
            
            // Removed bottom Spacer to push buttons down less or let card expand more
            
            bottomControl
                .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private var bottomControl: some View {
        ReviewActionButtons(
            swipeOffset: currentSwipeOffset,
            onRate: { rating in
                let now = Date()
                guard now.timeIntervalSince(lastInteractionTime) >= minInteractionInterval else { return }
                guard !isProcessingSwipe else { return }
                
                lastInteractionTime = now
                isProcessingSwipe = true
                
                let direction = (rating == .good) ? 1 : -1
                swipeTrigger = direction
            },
            onUndo: undoLastSwipe,
            onToggleAnswer: { withAnimation { isAnswerShown.toggle() } },
            isUndoEnabled: !undoStack.isEmpty,
            isAnswerShown: isAnswerShown
        )
        .frame(height: 100)
    }
    
    // MARK: - Helpers
    
    private func loadData() {
        let now = Date()
        let due = allItems.filter { item in
            guard let next = item.nextReviewAt else { return true }
            return next <= now
        }.sorted { ($0.nextReviewAt ?? Date.distantPast) < ($1.nextReviewAt ?? Date.distantPast) }
        
        reviewQueue = due
        
        // Only switch to idle if we are loading or finished, 
        // don't interrupt an active session unless logic requires it.
        // For simple sync, if we are in .reviewing, we might want to update queue silently?
        // But for now, if data changes, let's just refresh. 
        // If user is reviewing, replacing queue might be jarring. 
        // Ideally we only refresh if phase is .idle or .loading or .finished.
        if phase != .reviewing {
            phase = .idle
        }
        
        // Calculate Reviewed Today (Any item reviewed today)
        let today = Calendar.current.startOfDay(for: now)
        reviewedTodayCount = allItems.filter { item in
            guard let date = item.lastReviewedAt else { return false }
            return date >= today
        }.count
    }
    
    private func startSession() {
        workingItems = reviewQueue
        finishedItems = 0
        undoStack.removeAll()
        isAnswerShown = false
        
        // Calculate how many were already done today (for persistent progress bar)
        let today = Calendar.current.startOfDay(for: Date())
        sessionStartReviewedCount = allItems.filter { item in
            guard let date = item.lastReviewedAt else { return false }
            return date >= today
        }.count
        
        withAnimation {
            phase = .reviewing
        }
    }
    
    private func quitSession() {
        // Just quit and refresh stats
        loadData()
        withAnimation {
            phase = .idle
        }
    }
    
    private func resetSession() {
        phase = .loading
        undoStack.removeAll()
        loadData()
    }
    
    private func handleSwipeCompletion(direction: Int) {
        swipeTrigger = nil
        isProcessingSwipe = false // Unlock for next interaction
        
        guard let item = workingItems.first else { return }
        
        withAnimation(.spring(duration: 0.35)) {
            let removed = workingItems.removeFirst()
            undoStack.append(removed)
            finishedItems += 1
            isAnswerShown = false
            
            // Check if finished
            if workingItems.isEmpty {
                 phase = .finished
            }
        }
        
        // Update Scheduler logic
        let rating: ReviewRating = direction > 0 ? .good : .again
        let scheduler = ReviewScheduler()
        let updated = scheduler.scheduleNextReview(for: item.toEntity(), rating: rating)
        
        // Sync all SM-2 fields back to the model
        item.lastReviewedAt = updated.lastReviewedAt
        item.nextReviewAt = updated.nextReviewAt
        item.easeFactor = updated.easeFactor
        item.interval = updated.interval
        item.repetitions = updated.repetitions
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save review result: \(error)")
        }
    }
    
    private func undoLastSwipe() {
        guard !undoStack.isEmpty else { return }
        
        withAnimation(.spring(duration: 0.35)) {
            let item = undoStack.removeLast()
            workingItems.insert(item, at: 0)
            finishedItems -= 1
            isAnswerShown = false 
            
            // If we undid from finished state? (Though UI hides undo in finished, safe to check)
            if phase == .finished {
                phase = .reviewing
            }
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

#Preview {
    ReviewView(router: ReviewRouter())
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
