//
//  QuestionCard.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

struct QuestionCard: View {
    let question: Question
    let searchTerm: String
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var hasAppeared = false
    
    var body: some View {
        BaseCard(padding: DeviceInfo.cardPadding) {
            VStack(alignment: .leading, spacing: adaptiveSpacing) {
                // 题目内容
                HighlightedText(
                    text: question.content,
                    searchTerm: searchTerm,
                    font: adaptiveTitleFont,
                    highlightColor: .yellow
                )
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                
                // 答案
                HighlightedText(
                    text: "答案：\(question.answer)",
                    searchTerm: searchTerm,
                    font: adaptiveBodyFont,
                    highlightColor: .yellow
                )
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                
                // 标签和状态
                adaptiveTagsAndStatus
                
                // 创建时间
                HStack {
                    Spacer()
                    Text(question.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.cardAppear, value: hasAppeared)
        .animation(.buttonPress, value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            isPressed = pressing
        } perform: {}
        .onAppear {
            hasAppeared = true
        }
    }
    
    // MARK: - Adaptive Properties
    private var adaptiveSpacing: CGFloat {
        DeviceInfo.isCompact ? .spacingXS : .spacingS
    }
    
    private var adaptiveTitleFont: Font {
        DeviceInfo.isCompact ? .bodyLarge : .headingSmall
    }
    
    private var adaptiveBodyFont: Font {
        DeviceInfo.isCompact ? .bodySmall : .bodyMedium
    }
    
    // MARK: - Adaptive Tags Layout
    @ViewBuilder
    private var adaptiveTagsAndStatus: some View {
        if DeviceInfo.isCompact {
            // 紧凑布局：垂直排列
            VStack(alignment: .leading, spacing: .spacingXS) {
                HStack {
                    DifficultyBadge(difficulty: question.difficulty)
                    Spacer()
                    if question.isReviewed {
                        reviewedStatus
                    }
                }
                
                if !question.tags.isEmpty {
                    tagsView
                }
            }
        } else {
            // 常规布局：水平排列
            HStack {
                DifficultyBadge(difficulty: question.difficulty)
                tagsView
                Spacer()
                if question.isReviewed {
                    reviewedStatus
                }
            }
        }
    }
    
    @ViewBuilder
    private var tagsView: some View {
        let maxTags = DeviceInfo.isCompact ? 2 : 3
        ForEach(question.tags.prefix(maxTags), id: \.self) { tag in
            TagChip(tag: tag, searchTerm: searchTerm)
        }
    }
    
    @ViewBuilder
    private var reviewedStatus: some View {
        Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.statusReviewed)
            .font(.labelMedium)
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .animation(.springy.delay(0.1), value: hasAppeared)
    }
}
