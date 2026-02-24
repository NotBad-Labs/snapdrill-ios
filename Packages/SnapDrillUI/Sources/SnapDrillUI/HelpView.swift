//
//  HelpView.swift
//  SnapDrillUI
//
//  Created by SnapDrill Labs on 2026/01/03.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  帮助和常见问题视图
//

import SwiftUI

/// 帮助主题
public struct HelpTopic: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let icon: String
    public let questions: [HelpQuestion]
    
    public init(title: String, icon: String, questions: [HelpQuestion]) {
        self.title = title
        self.icon = icon
        self.questions = questions
    }
}

/// 帮助问题
public struct HelpQuestion: Identifiable, Sendable {
    public let id = UUID()
    public let question: String
    public let answer: String
    
    public init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
}

/// 帮助视图
public struct HelpView: View {
    @State private var searchText = ""
    @State private var selectedTopic: HelpTopic?
    
    let topics: [HelpTopic]
    
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
            .searchable(text: $searchText, prompt: "搜索帮助...")
            .navigationTitle("帮助中心")
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
            title: "开始使用",
            icon: "play.circle.fill",
            questions: [
                HelpQuestion(
                    question: "如何添加第一道错题？",
                    answer: "点击主界面的「+」按钮，选择「拍摄」或「从相册选择」，系统会自动识别题目内容。您也可以手动输入题目和答案。"
                ),
                HelpQuestion(
                    question: "如何开始复习？",
                    answer: "在仪表板中点击「开始复习」按钮，系统会根据艾宾浩斯遗忘曲线为您安排今日需要复习的题目。"
                ),
                HelpQuestion(
                    question: "如何设置学科和来源？",
                    answer: "在添加或编辑错题时，可以选择学科（如数学、语文等）和来源（如期中考试、作业等），方便后续分类查看。"
                )
            ]
        ),
        HelpTopic(
            title: "智能拍摄",
            icon: "camera.fill",
            questions: [
                HelpQuestion(
                    question: "如何获得最佳拍摄效果？",
                    answer: "确保光线充足，将题目放在平整的表面上，保持相机稳定。系统会自动检测题目区域并提示您拍摄。"
                ),
                HelpQuestion(
                    question: "文字识别不准确怎么办？",
                    answer: "您可以在识别后手动编辑题目内容。建议拍摄时保持题目清晰、光线充足，避免反光和阴影。"
                ),
                HelpQuestion(
                    question: "可以裁剪图片吗？",
                    answer: "可以。拍摄后会进入裁剪界面，您可以调整裁剪区域，确保只保留题目部分。"
                )
            ]
        ),
        HelpTopic(
            title: "复习系统",
            icon: "calendar.badge.clock",
            questions: [
                HelpQuestion(
                    question: "复习计划是如何安排的？",
                    answer: "系统基于艾宾浩斯遗忘曲线，在最佳时间点提醒您复习。首次复习在 1 天后，之后间隔逐渐延长（3天、7天、15天、30天）。"
                ),
                HelpQuestion(
                    question: "如何标记题目难度？",
                    answer: "在复习时，您可以为每道题目标记难度（1-5星）。系统会根据难度调整复习频率，难题会更频繁地出现。"
                ),
                HelpQuestion(
                    question: "可以自定义复习计划吗？",
                    answer: "目前系统使用科学的复习算法自动安排。您可以在设置中调整每日复习目标数量。"
                )
            ]
        ),
        HelpTopic(
            title: "数据管理",
            icon: "icloud.fill",
            questions: [
                HelpQuestion(
                    question: "如何启用 iCloud 同步？",
                    answer: "进入「设置」-「数据与云同步」，开启「启用 iCloud 同步」。确保您已登录 iCloud 账号。"
                ),
                HelpQuestion(
                    question: "如何导出数据？",
                    answer: "进入「设置」-「隐私与安全」-「导出数据」，选择导出格式（PDF、CSV、JSON），系统会生成文件供您分享或备份。"
                ),
                HelpQuestion(
                    question: "数据会丢失吗？",
                    answer: "启用 iCloud 同步后，数据会自动备份到云端。即使更换设备，登录相同的 iCloud 账号即可恢复数据。"
                )
            ]
        ),
        HelpTopic(
            title: "隐私与安全",
            icon: "lock.shield.fill",
            questions: [
                HelpQuestion(
                    question: "我的数据安全吗？",
                    answer: "所有数据都存储在您的设备和 iCloud 账号中，我们不会收集或上传您的个人数据。崩溃报告和分析数据都是匿名的。"
                ),
                HelpQuestion(
                    question: "如何关闭数据分析？",
                    answer: "进入「设置」-「隐私与安全」，关闭「数据分析」开关。这不会影响应用的核心功能。"
                ),
                HelpQuestion(
                    question: "相机和相册权限用于什么？",
                    answer: "相机权限用于拍摄错题，相册权限用于从相册选择图片。我们只在您使用相关功能时请求权限，不会访问其他照片。"
                )
            ]
        ),
        HelpTopic(
            title: "常见问题",
            icon: "questionmark.circle.fill",
            questions: [
                HelpQuestion(
                    question: "应用崩溃或卡顿怎么办？",
                    answer: "请尝试重启应用。如果问题持续，可以在设置中清除缓存。我们会自动收集崩溃报告（如果您已启用）并尽快修复。"
                ),
                HelpQuestion(
                    question: "如何联系技术支持？",
                    answer: "您可以通过「设置」-「关于」-「反馈与支持」联系我们，或发送邮件到 support@snapdrill.app。"
                ),
                HelpQuestion(
                    question: "应用是免费的吗？",
                    answer: "是的，SnapDrill 完全免费，没有内购或订阅。我们致力于为所有学生提供优质的学习工具。"
                )
            ]
        )
    ]
}

// MARK: - Preview

#Preview {
    HelpView()
}
