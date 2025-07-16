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
    
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: .spacingS) {
                // 题目内容
                HighlightedText(
                    text: question.content,
                    searchTerm: searchTerm,
                    font: .headingSmall,
                    highlightColor: .yellow
                )
                .foregroundColor(.textPrimary)
                
                // 答案
                HighlightedText(
                    text: "答案：\(question.answer)",
                    searchTerm: searchTerm,
                    font: .bodyMedium,
                    highlightColor: .yellow
                )
                .foregroundColor(.textSecondary)
                
                // 标签和状态
                HStack {
                    // 难度标签
                    DifficultyBadge(difficulty: question.difficulty)
                    
                    // 标签
                    ForEach(question.tags.prefix(3), id: \.self) { tag in
                        TagChip(tag: tag, searchTerm: searchTerm)
                    }
                    
                    Spacer()
                    
                    // 复习状态
                    if question.isReviewed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.statusReviewed)
                            .font(.labelMedium)
                    }
                }
                
                // 创建时间
                HStack {
                    Spacer()
                    Text(question.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote)
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    QuestionCard(
        question: Question(
            content: "计算：3 + 5 × 2 = ?",
            answer: "13",
            tags: ["数学", "运算", "易错"],
            difficulty: 2
        ),
        searchTerm: "计算",
        onTap: {}
    )
    .padding()
}