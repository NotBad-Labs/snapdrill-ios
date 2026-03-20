//
//  SwipeCard.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  可滑动的卡片容器，支持左滑/右滑手势交互。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

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
    let onRemove: (Int) -> Void // -1 表示左滑（下一张），1 表示右滑（上一张/忘了）
    let onSwipeProgress: ((CGFloat) -> Void)? // 拖动偏移量回调
    @Binding var externalSwipe: Int? // 设置后触发滑动
    
    @State private var translation: CGSize = .zero
    @State private var hasFired = false // 确保 onRemove 只被调用一次
    
    // 配置
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
                .simultaneousGesture( // 使用 simultaneous 与 ScrollView 共存
                    DragGesture()
                        .onChanged { gesture in
                            // 方向锁定：
                            // 如果用户在纵向滚动（dy > dx），交给 ScrollView 处理。
                            // 仅当手势以水平方向为主时才移动卡片。
                            if abs(gesture.translation.height) > abs(gesture.translation.width) {
                                // 为了稳定性优先让 ScrollView 滚动。
                                // 不更新 translation（等效于锁定卡片）。
                                return
                            }
                            
                            translation = gesture.translation
                            onSwipeProgress?(gesture.translation.width)
                        }
                        .onEnded { gesture in
                            let width = geometry.size.width
                            let velocity = gesture.predictedEndLocation.x - gesture.startLocation.x
                            
                            // 检查卡片是否实际移动（过滤纵向滚动结束事件）
                            if translation == .zero { return }
                            
                            if gesture.translation.width < -threshold || velocity < -500 {
                                // 左滑
                                snapAway(direction: -1, width: width)
                            } else if gesture.translation.width > threshold || velocity > 500 {
                                // 右滑
                                snapAway(direction: 1, width: width)
                            } else {
                                // 复位
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    translation = .zero
                                    onSwipeProgress?(0) // 重置进度
                                }
                            }
                        }
                )
                .onChange(of: externalSwipe) { _, newValue in
                    if let direction = newValue {
                        snapAway(direction: direction, width: geometry.size.width)
                        // 立即重置，防止状态泄漏到下一张卡片
                        DispatchQueue.main.async {
                            externalSwipe = nil
                        }
                    }
                }
                // VoiceOver 替代方案：通过 Actions 菜单完成滑动操作
                .accessibilityAction(named: L10n.Review.stampRemember) {
                    snapAway(direction: 1, width: geometry.size.width)
                }
                .accessibilityAction(named: L10n.Review.stampForgot) {
                    snapAway(direction: -1, width: geometry.size.width)
                }
        }
    }
    
    // MARK: - Private Helpers
    
    private func snapAway(direction: Int, width: CGFloat) {
        guard !hasFired else { return }
        hasFired = true
        
        let targetX = CGFloat(direction) * width * 2
        let targetY = translation.height + 50 // 轻微下坠
        
        // 较慢的动画时长，让"飞出"效果更明显
        withAnimation(.easeOut(duration: 0.5)) {
            translation = CGSize(width: targetX, height: targetY)
        }
        
        // 在动画结束前稍早通知移除，保持流程连续且安全
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
