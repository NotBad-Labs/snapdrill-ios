//
//  ReviewHeroCard.swift
//  SnapDrillFeatureDashboard
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  首页核心卡片，根据复习数据动态展示状态。
//

import SwiftUI
import SwiftData
import SnapDrillData

/// 仪表盘核心卡片：根据当前的复习数量动态展示不同的 UI 状态
///
/// 包括：
/// - 新用户引导状态（无数据）
/// - 待复习任务状态
/// - 任务已完成状态
struct ReviewHeroCard: View {
    /// 点击“立即开始”复习时的回调
    let onStartReview: () -> Void
    /// 点击“录入题目”时的回调
    let onStartCapture: () -> Void
    
    // Internal Query for Reactivity
    @Query private var allItems: [ReviewItemModel]
    
    // Computed Properties
    private var totalCount: Int { allItems.count }
    private var dueCount: Int {
        let now = Date()
        return allItems.filter { ($0.nextReviewAt ?? .distantPast) <= now }.count
    }
    
    init(onStartReview: @escaping () -> Void, onStartCapture: @escaping () -> Void) {
        self.onStartReview = onStartReview
        self.onStartCapture = onStartCapture
    }
    
    var body: some View {
        VStack {
            if totalCount == 0 {
                // Scenario 1: New User (Zero Data)
                // Guide them to add first item
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("欢迎使用")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        
                        Text("添加第一道错题，开启复习之旅")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Button(action: onStartCapture) {
                            Label("录入题目", systemImage: "plus.circle.fill")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .foregroundStyle(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(24)
                .background(
                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            } else if dueCount > 0 {
                // Scenario 2: Has Tasks (Due > 0)
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日待复习")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Text("\(dueCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Button(action: onStartReview) {
                            Text("立即开始")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .foregroundStyle(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                    // Dynamic Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: 0.7) // Mock progress
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 80, height: 80)
                }
                .padding(24)
                .background(
                    LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            } else {
                // Scenario 3: All Caught Up (Total > 0, Due == 0)
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("太棒了！")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        
                        Text("今日复习任务已清空")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.green.gradient)
                        .symbolEffect(.bounce, value: true)
                }
                .padding(24)
                .background(.regularMaterial) // Use material for cards
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview("Hero Card") {
    ReviewHeroCard(onStartReview: {}, onStartCapture: {})
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
