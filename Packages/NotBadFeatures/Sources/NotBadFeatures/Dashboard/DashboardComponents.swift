//
//  DashboardComponents.swift
//  NotBadFeatureDashboard
//
//  Created by NotBad Agent on 2025/12/31.
//

import SwiftUI

// MARK: - Modern Components

struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.footnote)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                Text("NotBad 学习助手")
                    .font(.largeTitle.bold())
            }
            Spacer()
            // Avatar / Profile
            Image(systemName: "person.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

/// 核心卡片：根据复习数量动态展示 UI
struct ReviewHeroCard: View {
    let totalCount: Int
    let dueCount: Int
    let onStartReview: () -> Void
    let onStartCapture: () -> Void
    
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
                    LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
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

struct BentoCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(gradient) // Gradient Text/Icon
                        .padding(8)
                        .background(.ultraThickMaterial) // Contrast
                        .clipShape(Circle())
                    Spacer()
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary) // Auto adapting
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(height: 120)
            .background(.regularMaterial) // Glass Effect
            .clipShape(RoundedRectangle(cornerRadius: 24)) // More rounded for "iOS 26"
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.2), lineWidth: 1) // Glass Border
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5) // Softer shadow
        }
    }
}
