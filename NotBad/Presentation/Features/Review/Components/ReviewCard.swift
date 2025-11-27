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
    
    /// 卡片出现动画
    @State private var isAppeared = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
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
        .background(Color.semantic.background)
        .opacity(isAppeared ? 1 : 0)
        .offset(y: isAppeared ? 0 : 20)
        .accessibilityIdentifier("review_card")
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAppeared = true
            }
        }
    }
}

// MARK: - ReviewCard Subviews

extension ReviewCard {
    
    /// 头部区域
    var headerSection: some View {
        HStack {
            // Subject badge with enhanced styling
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: item.subject.icon)
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5), value: isAppeared)
                Text(item.subject.displayName)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(item.subject.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .strokeBorder(item.subject.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundStyle(item.subject.color)
            
            Spacer()
            
            // Grade badge with subtle styling
            Text(item.grade.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.semantic.secondaryBackground)
                .clipShape(Capsule())
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
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
    
    /// 标题区域
    var titleSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("review_question_label")
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(item.title)
                .font(.title3)
                .fontWeight(.semibold)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 答案区域
    @ViewBuilder
    var answerSection: some View {
        if !item.note.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                answerToggleButton
                
                if showAnswer {
                    Text(item.note)
                        .font(.body)
                        .padding(DesignTokens.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.semantic.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    /// 答案显示/隐藏按钮
    var answerToggleButton: some View {
        Button {
            withAnimation(DesignTokens.Animation.spring) {
                showAnswer.toggle()
            }
        } label: {
            HStack {
                Image(systemName: showAnswer ? "eye.slash.fill" : "eye.fill")
                    .symbolEffect(.bounce, value: showAnswer)
                Text(showAnswer ? "隐藏答案" : "查看答案")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .rotationEffect(.degrees(showAnswer ? 180 : 0))
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .fill(Color.brand.warning.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                            .strokeBorder(Color.brand.warning.opacity(0.25), lineWidth: 1)
                    )
            )
            .foregroundStyle(Color.brand.warning)
        }
        .buttonStyle(AnswerToggleButtonStyle())
        .accessibilityLabel(showAnswer ? "隐藏答案" : "查看答案")
    }
    
    /// 答案切换按钮样式
    private struct AnswerToggleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
    
    /// 元数据区域
    var metadataSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
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
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("review_mastery_prompt")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: DesignTokens.Spacing.md) {
                MasteryButton(
                    icon: "xmark.circle.fill",
                    title: String(localized: "review_mastery_failed"),
                    color: Color.brand.error,
                    action: onFailed
                )
                
                MasteryButton(
                    icon: "questionmark.circle.fill",
                    title: String(localized: "review_mastery_unclear"),
                    color: Color.brand.warning,
                    action: onUnclear
                )
                
                MasteryButton(
                    icon: "checkmark.seal.fill",
                    title: String(localized: "review_mastery_mastered"),
                    color: Color.brand.success,
                    action: onMastered
                )
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(Color.semantic.secondaryBackground)
    }
}

// MARK: - MasteryButton

/// 单个评估按钮
struct MasteryButton: View {
    
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Icon with circle background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .symbolEffect(.bounce, value: isPressed)
                        .accessibilityHidden(true)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .strokeBorder(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundStyle(color)
        }
        .buttonStyle(MasteryButtonStyle(isPressed: $isPressed))
        .sensoryFeedback(.impact(weight: .medium), trigger: title)
        .accessibilityIdentifier(title)
        .accessibleButton(title, hint: "点击标记为\(title)")
    }
}

/// Mastery Button 按压样式
private struct MasteryButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
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
