//
//  HelpCenterView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - HelpCenterView

/// 帮助中心视图
///
/// 提供使用指南和常见问题解答。
struct HelpCenterView: View {
    
    // MARK: - State
    
    @State private var expandedSection: HelpSection?
    @State private var searchText = ""
    
    // MARK: - Body
    
    var body: some View {
        List {
            quickStartSection
            faqSection
            contactSection
        }
        .navigationTitle("帮助中心")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "搜索问题")
    }
    
    // MARK: - Quick Start Section
    
    private var quickStartSection: some View {
        Section("快速入门") {
            ForEach(QuickStartItem.allCases) { item in
                DisclosureGroup {
                    Text(item.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                } label: {
                    Label(item.title, systemImage: item.icon)
                }
            }
        }
    }
    
    // MARK: - FAQ Section
    
    private var faqSection: some View {
        Section("常见问题") {
            ForEach(filteredFAQs) { faq in
                DisclosureGroup {
                    Text(faq.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                } label: {
                    Text(faq.question)
                        .font(.body)
                }
            }
        }
    }
    
    // MARK: - Contact Section
    
    private var contactSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("还有其他问题？")
                    .font(.headline)
                
                Text("如果上面的内容没有解答你的疑问，欢迎通过以下方式联系我们：")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    contactRow(icon: "envelope.fill", text: "feedback@notbad.app", color: Color.brand.primary)
                    contactRow(icon: "globe", text: "notbad.app/help", color: Color.brand.secondary)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }
    
    private func contactRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredFAQs: [FAQ] {
        if searchText.isEmpty {
            return FAQ.allCases
        }
        return FAQ.allCases.filter { faq in
            faq.question.localizedCaseInsensitiveContains(searchText) ||
            faq.answer.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - HelpSection

enum HelpSection: String, CaseIterable, Identifiable {
    case quickStart
    case faq
    
    var id: String { rawValue }
}

// MARK: - QuickStartItem

enum QuickStartItem: String, CaseIterable, Identifiable {
    case addItem
    case review
    case library
    case statistics
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .addItem: return "如何添加错题"
        case .review: return "如何复习错题"
        case .library: return "如何管理错题库"
        case .statistics: return "如何查看学习统计"
        }
    }
    
    var icon: String {
        switch self {
        case .addItem: return "plus.circle.fill"
        case .review: return "book.fill"
        case .library: return "folder.fill"
        case .statistics: return "chart.bar.fill"
        }
    }
    
    var content: String {
        switch self {
        case .addItem:
            return """
            1. 点击底部"添加"标签页
            2. 选择科目和年级
            3. 使用相机拍照或从相册选择错题图片
            4. 也可以使用实时文字扫描快速录入
            5. 填写标题、知识点等信息
            6. 点击保存即可
            """
        case .review:
            return """
            1. 在"首页"查看待复习的错题
            2. 点击"开始复习"进入复习模式
            3. 查看题目并回忆解答
            4. 根据掌握程度标记复习结果
            5. 系统会根据艾宾浩斯曲线安排下次复习
            """
        case .library:
            return """
            1. 点击底部"错题库"标签页
            2. 使用顶部筛选器按科目、难度等分类
            3. 使用搜索功能快速查找
            4. 点击错题查看详情
            5. 长按或进入详情页可编辑、删除
            """
        case .statistics:
            return """
            1. 在"首页"查看核心统计数据
            2. 包括总错题数、待复习、已掌握等
            3. 查看各科目分布图表
            4. 了解掌握程度趋势
            5. 获取个性化学习建议
            """
        }
    }
}

// MARK: - FAQ

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    
    static let allCases: [FAQ] = [
        FAQ(
            question: "复习提醒没有收到？",
            answer: "请检查以下设置：\n1. 系统设置 > 通知 > NotBad 是否开启\n2. 勿扰模式是否开启\n3. 是否设置了复习提醒时间\n4. 手机是否处于静音模式"
        ),
        FAQ(
            question: "如何修改已录入的错题？",
            answer: "在错题库中找到需要修改的错题，点击进入详情页，然后点击右上角的编辑按钮即可修改题目内容、标签等信息。"
        ),
        FAQ(
            question: "错题图片太大怎么办？",
            answer: "应用会自动压缩图片以节省存储空间。如果图片仍然太大，建议在拍照时使用普通质量，或在相册中选择较小的图片。"
        ),
        FAQ(
            question: "如何备份我的错题数据？",
            answer: "进入『我的』>『数据管理』，选择『导出为 JSON』或『导出为 CSV』，可以将数据保存到文件或分享到其他应用。"
        ),
        FAQ(
            question: "复习模式有什么区别？",
            answer: "• 智能模式：根据遗忘曲线优先复习即将遗忘的题目\n• 逾期优先：优先复习已超期的题目\n• 薄弱优先：优先复习掌握程度低的题目\n• 最新添加：按添加时间从新到旧复习"
        ),
        FAQ(
            question: "掌握程度是如何计算的？",
            answer: "掌握程度基于你的复习表现：\n• 每次标记『已掌握』会提升掌握程度\n• 标记『需加强』会降低掌握程度\n• 系统综合考虑复习次数和时间间隔"
        ),
        FAQ(
            question: "数据会同步到其他设备吗？",
            answer: "目前版本数据仅保存在本地设备。未来版本将支持 iCloud 同步，敬请期待！"
        )
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HelpCenterView()
    }
}
