//
//  HelpView.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  帮助和常见问题视图
//

import SnapDrillCore
import SwiftUI

/// 帮助主题
public struct HelpTopic: Identifiable, Sendable {
    /// 唯一标识
    public let id = UUID()
    /// 主题标题（如"开始使用"、"智能拍摄"）
    public let title: String
    /// 主题图标（SF Symbol 名称）
    public let icon: String
    /// 该主题下的问题列表
    public let questions: [HelpQuestion]
    
    /// 创建帮助主题
    /// - Parameters:
    ///   - title: 主题标题
    ///   - icon: SF Symbol 图标名称
    ///   - questions: 该主题下的问答列表
    public init(title: String, icon: String, questions: [HelpQuestion]) {
        self.title = title
        self.icon = icon
        self.questions = questions
    }
}

/// 帮助问题
public struct HelpQuestion: Identifiable, Sendable {
    /// 唯一标识
    public let id = UUID()
    /// 问题文本
    public let question: String
    /// 答案文本
    public let answer: String
    
    /// 创建帮助问答条目
    /// - Parameters:
    ///   - question: 问题文本
    ///   - answer: 答案文本
    public init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
}

/// 帮助视图
public struct HelpView: View {
    
    // MARK: - Properties
    
    @State private var searchText = ""

    let topics: [HelpTopic]
    
    /// 创建帮助视图
    /// - Parameter topics: 帮助主题列表，默认使用内置预设主题
    public init(topics: [HelpTopic] = HelpTopic.defaultTopics) {
        self.topics = topics
    }
    
    var filteredTopics: [HelpTopic] {
        if searchText.isEmpty {
            return topics
        }
        
        return topics.compactMap { topic in
            let matchingQuestions = topic.questions.filter { question in
                question.question.localizedCaseInsensitiveContains(searchText) ||
                question.answer.localizedCaseInsensitiveContains(searchText)
            }
            
            if matchingQuestions.isEmpty {
                return nil
            }
            
            return HelpTopic(
                title: topic.title,
                icon: topic.icon,
                questions: matchingQuestions
            )
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTopics) { topic in
                    Section {
                        ForEach(topic.questions) { question in
                            DisclosureGroup {
                                Text(question.answer)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 8)
                                    .accessible(label: question.answer)
                            } label: {
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundStyle(.blue)
                                    Text(question.question)
                                        .font(.body)
                                }
                                .accessibleButton(label: question.question)
                            }
                        }
                    } header: {
                        Label(topic.title, systemImage: topic.icon)
                            .accessibleHeader(topic.title)
                    }
                }
            }
            .searchable(text: $searchText, prompt: L10n.Help.searchPrompt)
            .navigationTitle(L10n.Help.title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// 快速帮助卡片
public struct QuickHelpCard: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    /// 创建快速帮助卡片
    /// - Parameters:
    ///   - title: 卡片标题
    ///   - description: 卡片描述文本
    ///   - icon: SF Symbol 图标名称
    ///   - action: 点击卡片时的回调
    public init(title: String, description: String, icon: String, action: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.blue.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibleButton(
            label: title,
            hint: description
        )
    }
}

/// 默认帮助主题
public extension HelpTopic {
    static let defaultTopics: [HelpTopic] = [
        HelpTopic(
            title: L10n.Help.topicGettingStarted,
            icon: "play.circle.fill",
            questions: [
                HelpQuestion(
                    question: L10n.Help.questionAddFirstItem,
                    answer: L10n.Help.answerAddFirstItem
                ),
                HelpQuestion(
                    question: L10n.Help.questionStartReview,
                    answer: L10n.Help.answerStartReview
                ),
                HelpQuestion(
                    question: L10n.Help.questionSetSubjectSource,
                    answer: L10n.Help.answerSetSubjectSource
                )
            ]
        ),
        HelpTopic(
            title: L10n.Help.topicSmartCapture,
            icon: "camera.fill",
            questions: [
                HelpQuestion(
                    question: L10n.Help.questionBestCapture,
                    answer: L10n.Help.answerBestCapture
                ),
                HelpQuestion(
                    question: L10n.Help.questionOcrInaccurate,
                    answer: L10n.Help.answerOcrInaccurate
                ),
                HelpQuestion(
                    question: L10n.Help.questionCropImage,
                    answer: L10n.Help.answerCropImage
                )
            ]
        ),
        HelpTopic(
            title: L10n.Help.topicReviewSystem,
            icon: "calendar.badge.clock",
            questions: [
                HelpQuestion(
                    question: L10n.Help.questionReviewSchedule,
                    answer: L10n.Help.answerReviewSchedule
                ),
                HelpQuestion(
                    question: L10n.Help.questionMarkDifficulty,
                    answer: L10n.Help.answerMarkDifficulty
                ),
                HelpQuestion(
                    question: L10n.Help.questionCustomReview,
                    answer: L10n.Help.answerCustomReview
                )
            ]
        ),
        HelpTopic(
            title: L10n.Help.topicDataManagement,
            icon: "icloud.fill",
            questions: [
                HelpQuestion(
                    question: L10n.Help.questionDataBackup,
                    answer: L10n.Help.answerDataBackup
                ),
                HelpQuestion(
                    question: L10n.Help.questionExportData,
                    answer: L10n.Help.answerExportData
                ),
                HelpQuestion(
                    question: L10n.Help.questionDataLoss,
                    answer: L10n.Help.answerDataLoss
                )
            ]
        ),
        HelpTopic(
            title: L10n.Help.topicPrivacySecurity,
            icon: "lock.shield.fill",
            questions: [
                HelpQuestion(
                    question: L10n.Help.questionDataSafe,
                    answer: L10n.Help.answerDataSafe
                ),
                HelpQuestion(
                    question: L10n.Help.questionDisableAnalytics,
                    answer: L10n.Help.answerDisableAnalytics
                ),
                HelpQuestion(
                    question: L10n.Help.questionPermissions,
                    answer: L10n.Help.answerPermissions
                )
            ]
        ),
        HelpTopic(
            title: L10n.Help.topicFaq,
            icon: "questionmark.circle.fill",
            questions: [
                HelpQuestion(
                    question: L10n.Help.questionCrashOrLag,
                    answer: L10n.Help.answerCrashOrLag
                ),
                HelpQuestion(
                    question: L10n.Help.questionContactSupport,
                    answer: L10n.Help.answerContactSupport
                ),
                HelpQuestion(
                    question: L10n.Help.questionIsFree,
                    answer: L10n.Help.answerIsFree
                )
            ]
        )
    ]
}

// MARK: - Preview

#Preview {
    HelpView()
}
