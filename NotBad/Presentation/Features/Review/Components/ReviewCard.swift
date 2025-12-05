//
//  ReviewCard.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - AsyncImageView

/// 异步图片加载视图
///
/// 在后台线程解码图片，避免阻塞主线程。
/// 对于复习页面的滑动性能至关重要。
private struct AsyncImageView: View {
    let imageData: Data
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView()
                    .frame(height: 200)
            }
        }
        .task(id: imageData.hashValue) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        
        // 在后台线程解码图片
        let decoded = await Task.detached(priority: .userInitiated) {
            // 解码图片
            guard let original = UIImage(data: imageData) else { return nil as UIImage? }
            
            // 限制最大尺寸以减少内存占用和渲染压力
            let maxDimension: CGFloat = 800
            let scale = min(maxDimension / original.size.width, maxDimension / original.size.height, 1.0)
            
            if scale < 1.0 {
                let newSize = CGSize(
                    width: original.size.width * scale,
                    height: original.size.height * scale
                )
                let renderer = UIGraphicsImageRenderer(size: newSize)
                return renderer.image { _ in
                    original.draw(in: CGRect(origin: .zero, size: newSize))
                }
            }
            
            return original
        }.value
        
        await MainActor.run {
            self.image = decoded
            self.isLoading = false
        }
    }
}

// MARK: - ReviewCard

/// 复习卡片组件
///
/// 展示单道错题的详细信息，支持显示/隐藏答案，
/// 并提供掌握度自评按钮。
///
/// ## 键盘快捷键支持
///
/// 通过外部绑定 `showAnswer`，支持键盘快捷键控制：
/// - 空格键切换答案显示
///
/// ## 使用示例
///
/// ```swift
/// ReviewCard(
///     item: reviewItem,
///     showAnswer: $showAnswer,
///     onMastered: { /* 完全掌握 */ },
///     onUnclear: { /* 一知半解 */ },
///     onFailed: { /* 不会 */ }
/// )
/// ```
struct ReviewCard: View {

    // MARK: - Properties

    /// 错题数据
    let reviewItem: ReviewItem
    
    /// 是否显示答案（外部绑定，支持键盘快捷键）
    @Binding var showAnswer: Bool

    /// 掌握回调
    let onMastered: () -> Void

    /// 模糊回调
    let onUnclear: () -> Void

    /// 不会回调
    let onFailed: () -> Void

    // MARK: - State

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
                Image(systemName: reviewItem.subject.icon)
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5), value: isAppeared)
                Text(reviewItem.subject.displayName)
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(reviewItem.subject.color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .strokeBorder(reviewItem.subject.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundStyle(reviewItem.subject.color)

            Spacer()

            // Grade badge with subtle styling
            Text(reviewItem.grade.displayName)
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
        if let imageData = reviewItem.imageData {
            AsyncImageView(imageData: imageData)
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
            Text("review_item_label")
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(reviewItem.title)
                .font(.title3)
                .fontWeight(.semibold)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 答案区域
    @ViewBuilder
    var answerSection: some View {
        if !reviewItem.note.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                answerToggleButton

                if showAnswer {
                    Text(reviewItem.note)
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
            if !reviewItem.knowledgePoints.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                    Text(reviewItem.knowledgePoints.rawValue)
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }

            HStack {
                Label("已复习 \(reviewItem.reviewCount) 次", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                MasteryBadge(
                    level: MasteryLevel(rawValue: reviewItem.masteryLevel) ?? .none,
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
                        .frame(width: DesignTokens.IconSize.xl2, height: DesignTokens.IconSize.xl2)

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
    @Previewable @State var showAnswer = false
    
    ReviewCard(
        reviewItem: ReviewItem(
            imageData: nil,
            title: "测试错题",
            note: "这是答案和解题思路",
            subject: .math,
            grade: .grade10,
            knowledgePoints: ["函数"]
        ),
        showAnswer: $showAnswer,
        onMastered: {},
        onUnclear: {},
        onFailed: {}
    )
}
