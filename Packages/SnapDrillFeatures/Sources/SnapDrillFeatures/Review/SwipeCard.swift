//
//  SwipeCard.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  可滑动的卡片容器，支持左滑/右滑手势交互。
//

import SwiftUI
import SnapDrillCore

/// 支持左右轻扫的手势卡片包装器
///
/// 提供了物理引擎仿真效果，包括旋转和位移。
/// - Parameters:
///   - content: 卡片内显示的内容
///   - onRemove: 当卡片被移出屏幕时的回调，返回方向（-1 为左，1 为右）
///   - externalSwipe: 外部触发滑动的绑定变量
struct SwipeCard<Content: View>: View {
    
    // MARK: - Properties
    
    let content: Content
    let onRemove: (Int) -> Void // -1 for Left (Next), 1 for Right (Prev/Forget)
    let onSwipeProgress: ((CGFloat) -> Void)? // Callback for drag offset
    @Binding var externalSwipe: Int? // Triggers swipe when set
    
    @State private var translation: CGSize = .zero
    @State private var hasFired = false // Ensure onRemove is called exactly once
    
    // Config
    private let threshold: CGFloat = 100
    private let rotationDegrees: Double = 15
    
    // MARK: - Initialization
    
    init(
        @ViewBuilder content: () -> Content,
        onRemove: @escaping (Int) -> Void,
        externalSwipe: Binding<Int?> = .constant(nil),
        onSwipeProgress: ((CGFloat) -> Void)? = nil
    ) {
        self.content = content()
        self.onRemove = onRemove
        self._externalSwipe = externalSwipe
        self.onSwipeProgress = onSwipeProgress
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: translation.width, y: translation.height)
                .rotationEffect(.degrees(geometry.size.width > 0 ? Double(translation.width / geometry.size.width) * rotationDegrees : 0))
                .simultaneousGesture( // Use simultaneous to coexist with ScrollView
                    DragGesture()
                        .onChanged { gesture in
                            // Directional Lock:
                            // If user is scrolling vertically (dy > dx), let ScrollView handle it.
                            // We only move the card if the gesture is primarily horizontal.
                            if abs(gesture.translation.height) > abs(gesture.translation.width) {
                                // If we are already moving significantly, maybe allow it?
                                // But for stability, let's prioritize scrolling.
                                // Don't update translation (effectively locking card).
                                return
                            }
                            
                            translation = gesture.translation
                            onSwipeProgress?(gesture.translation.width)
                        }
                        .onEnded { gesture in
                            let width = geometry.size.width
                            let velocity = gesture.predictedEndLocation.x - gesture.startLocation.x
                            
                            // Check if the card was actually moved (filter out vertical scroll endings)
                            if translation == .zero { return }
                            
                            if gesture.translation.width < -threshold || velocity < -500 {
                                // Swipe Left
                                snapAway(direction: -1, width: width)
                            } else if gesture.translation.width > threshold || velocity > 500 {
                                // Swipe Right
                                snapAway(direction: 1, width: width)
                            } else {
                                // Reset
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    translation = .zero
                                    onSwipeProgress?(0) // Reset progress
                                }
                            }
                        }
                )
                .onChange(of: externalSwipe) { _, newValue in
                    if let direction = newValue {
                        snapAway(direction: direction, width: geometry.size.width)
                        // Immediate reset to prevent state leakage to next card
                        DispatchQueue.main.async {
                            externalSwipe = nil
                        }
                    }
                }
        }
    }
    
    // MARK: - Private Helpers
    
    private func snapAway(direction: Int, width: CGFloat) {
        guard !hasFired else { return }
        hasFired = true
        
        let targetX = CGFloat(direction) * width * 2
        let targetY = translation.height + 50 // Slight drop
        
        // Slower duration for a more observable "fly away"
        withAnimation(.easeOut(duration: 0.5)) {
            translation = CGSize(width: targetX, height: targetY)
        }
        
        // Notify removal slightly before animation ends to keep flow continuous but safe
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onRemove(direction)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        SwipeCard(
            content: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(width: 300, height: 400)
                    .shadow(radius: 5)
                    .overlay(Text("Swipe Me"))
            },
            onRemove: { _ in SnapDrillLogger.generic.info("Removed") }
        )
    }
}
