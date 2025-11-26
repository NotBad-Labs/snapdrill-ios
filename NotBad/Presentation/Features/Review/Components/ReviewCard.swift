//
//  ReviewCard.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - ReviewCard

/// 复习卡片组件
///
/// 展示单道错题的详细信息，支持显示/隐藏答案，
/// 并提供掌握度自评按钮。
///
/// ## 使用示例
///
/// ```swift
/// ReviewCard(
///     item: reviewItem,
///     onMastered: { /* 完全掌握 */ },
///     onUnclear: { /* 一知半解 */ },
///     onFailed: { /* 不会 */ }
/// )
/// ```
struct ReviewCard: View {
    
    // MARK: - Properties
    
    /// 错题数据
    let item: ReviewItem
    
    /// 掌握回调
    let onMastered: () -> Void
    
    /// 模糊回调
    let onUnclear: () -> Void
    
    /// 不会回调
    let onFailed: () -> Void
    
    // MARK: - State
    
    /// 是否显示答案
    @State private var showAnswer = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    imageSection
                    titleSection
                    answerSection
                    metadataSection
                }
                .padding()
            }
            
            ActionButtons(
                onFailed: onFailed,
                onUnclear: onUnclear,
                onMastered: onMastered
            )
        }
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - ReviewCard Subviews

extension ReviewCard {
    
    /// 头部区域
    var headerSection: some View {
        HStack {
            Label(item.subject.displayName, systemImage: item.subject.icon)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(item.subject.color.opacity(0.1))
                .foregroundStyle(item.subject.color)
                .clipShape(Capsule())
            
            Spacer()
            
            Text(item.grade.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    /// 图片区域
    @ViewBuilder
    var imageSection: some View {
        if let imageData = item.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        }
    }
    
    /// 标题区域
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("题目")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(item.title)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 答案区域
    @ViewBuilder
    var answerSection: some View {
        if !item.note.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                answerToggleButton
                
                if showAnswer {
                    Text(item.note)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    /// 答案显示/隐藏按钮
    var answerToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showAnswer.toggle()
            }
        } label: {
            HStack {
                Image(systemName: showAnswer ? "eye.slash.fill" : "eye.fill")
                Text(showAnswer ? "隐藏答案" : "查看答案")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(showAnswer ? 180 : 0))
            }
            .padding()
            .background(.orange.opacity(0.1))
            .foregroundStyle(.orange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(showAnswer ? "隐藏答案" : "查看答案")
    }
    
    /// 元数据区域
    var metadataSection: some View {
        VStack(spacing: 12) {
            if !item.knowledgePoints.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                    Text(item.knowledgePoints.rawValue)
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("已复习 \(item.reviewCount) 次", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                MasteryBadge(
                    level: MasteryLevel(rawValue: item.masteryLevel) ?? .none,
                    showDetailText: true
                )
            }
        }
    }
}

// MARK: - ActionButtons

/// 评估按钮组件
struct ActionButtons: View {
    
    let onFailed: () -> Void
    let onUnclear: () -> Void
    let onMastered: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("这道题你掌握了吗？")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                MasteryButton(
                    icon: "xmark.circle.fill",
                    title: "不会",
                    color: .red,
                    action: onFailed
                )
                
                MasteryButton(
                    icon: "questionmark.circle.fill",
                    title: "模糊",
                    color: .orange,
                    action: onUnclear
                )
                
                MasteryButton(
                    icon: "checkmark.seal.fill",
                    title: "掌握",
                    color: .green,
                    action: onMastered
                )
            }
        }
        .padding()
        .background(.background.secondary)
    }
}

// MARK: - MasteryButton

/// 单个评估按钮
struct MasteryButton: View {
    
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityLabel(title)
        .accessibilityHint("点击标记为\(title)")
    }
}

#Preview("Review Card") {
    ReviewCard(
        item: ReviewItem(
            imageData: nil,
            title: "测试错题",
            note: "这是答案和解题思路",
            subject: .math,
            grade: .grade10,
            knowledgePoints: ["函数"]
        ),
        onMastered: {},
        onUnclear: {},
        onFailed: {}
    )
}
