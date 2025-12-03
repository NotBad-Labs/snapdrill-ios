//
//  TestDataGenerator.swift
//  NotBad
//
//  测试数据生成器 - 用于性能测试
//

import Foundation
import SwiftData

#if DEBUG

// MARK: - TestDataGenerator

/// 测试数据生成器
///
/// 用于生成大量模拟数据，测试应用性能。
/// 仅在 DEBUG 模式下可用。
@MainActor
struct TestDataGenerator {
    
    // MARK: - Sample Data
    
    /// 数学题目标题样本
    private static let mathTitles = [
        "一元二次方程求解", "二次函数图像性质", "三角函数恒等变换",
        "等差数列求和", "等比数列通项公式", "圆的标准方程",
        "椭圆焦点坐标", "双曲线渐近线", "抛物线焦点弦",
        "向量数量积", "空间向量坐标", "立体几何体积",
        "导数求极值", "定积分计算", "概率分布期望",
        "排列组合计数", "二项式定理", "复数运算"
    ]
    
    /// 语文题目标题样本
    private static let chineseTitles = [
        "文言文翻译", "诗词鉴赏", "现代文阅读理解",
        "作文审题立意", "修辞手法分析", "句子成分划分",
        "病句修改", "标点符号使用", "成语运用",
        "名著阅读", "古诗默写", "论述文写作"
    ]
    
    /// 英语题目标题样本
    private static let englishTitles = [
        "完形填空", "阅读理解", "语法填空",
        "短文改错", "书面表达", "听力理解",
        "词汇辨析", "时态语态", "从句用法",
        "非谓语动词", "虚拟语气", "强调句型"
    ]
    
    /// 物理题目标题样本
    private static let physicsTitles = [
        "牛顿运动定律", "曲线运动", "万有引力",
        "机械能守恒", "动量守恒", "简谐运动",
        "电场强度", "电势能计算", "磁场力分析",
        "电磁感应", "交流电路", "光的干涉"
    ]
    
    /// 化学题目标题样本
    private static let chemistryTitles = [
        "氧化还原反应", "离子方程式", "化学平衡",
        "电化学原理", "有机化学反应", "元素周期律",
        "溶液浓度计算", "气体摩尔体积", "热化学方程式"
    ]
    
    /// 知识点样本
    private static let knowledgePointSamples: [Subject: [[String]]] = [
        .math: [
            ["函数", "二次函数"],
            ["方程", "一元二次方程"],
            ["数列", "等差数列", "求和"],
            ["三角函数", "恒等变换"],
            ["解析几何", "圆", "椭圆"],
            ["导数", "极值", "最值"],
            ["概率", "统计", "分布"]
        ],
        .chinese: [
            ["文言文", "翻译"],
            ["诗词", "鉴赏", "意象"],
            ["阅读", "理解", "分析"],
            ["写作", "议论文"]
        ],
        .english: [
            ["语法", "时态"],
            ["阅读", "理解"],
            ["写作", "表达"],
            ["词汇", "辨析"]
        ],
        .physics: [
            ["力学", "牛顿定律"],
            ["电学", "电场"],
            ["磁学", "电磁感应"],
            ["光学", "干涉"]
        ],
        .chemistry: [
            ["有机", "反应类型"],
            ["无机", "元素"],
            ["电化学", "原电池"]
        ]
    ]
    
    /// 笔记样本
    private static let noteSamples = [
        "注意审题，看清条件",
        "这类题目容易忘记讨论特殊情况",
        "公式要记牢，推导过程要熟练",
        "计算要仔细，避免粗心错误",
        "解题思路：先分析，再计算",
        "易错点：符号容易搞错",
        "关键步骤不能省略",
        "画图辅助理解",
        "",
        ""
    ]
    
    // MARK: - Generation
    
    /// 生成测试数据
    /// - Parameters:
    ///   - count: 生成数量
    ///   - context: SwiftData 上下文
    static func generate(count: Int, in context: ModelContext) {
        let subjects: [Subject] = [.math, .chinese, .english, .physics, .chemistry]
        let grades: [Grade] = [.grade7, .grade8, .grade9, .grade10, .grade11, .grade12]
        let difficulties = Difficulty.allCases
        let sources = Source.allCases
        let errorTypes = ErrorType.allCases
        let questionTypes = ReviewItemType.allCases
        let masteryLevels = MasteryLevel.allCases
        
        for i in 0..<count {
            let subject = subjects.randomElement()!
            let grade = grades.randomElement()!
            let difficulty = difficulties.randomElement()!
            let source = sources.randomElement()!
            let errorType = errorTypes.randomElement()!
            let questionType = questionTypes.randomElement()!
            let mastery = masteryLevels.randomElement()!
            
            // 根据学科选择标题
            let title = titleFor(subject: subject, index: i)
            
            // 随机知识点
            let knowledgePoints = knowledgePointsFor(subject: subject)
            
            // 随机笔记
            let note = noteSamples.randomElement()!
            
            // 随机创建时间（过去 180 天内）
            let daysAgo = Int.random(in: 0...180)
            let createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            
            // 随机复习次数
            let reviewCount = Int.random(in: 0...10)
            
            let item = ReviewItem(
                imageData: nil,
                title: title,
                note: note,
                createdAt: createdAt,
                mastery: mastery,
                subject: subject,
                grade: grade,
                knowledgePoints: knowledgePoints,
                difficulty: difficulty,
                errorType: errorType,
                source: source,
                questionType: questionType
            )
            
            // 设置复习次数
            item.reviewCount = reviewCount
            
            // 设置下次复习时间
            let nextReviewDays = Int.random(in: -7...30)
            item.nextReviewDate = Calendar.current.date(byAdding: .day, value: nextReviewDays, to: Date())!
            
            context.insert(item)
            
            // 每 500 条保存一次，避免内存压力
            if i % 500 == 0 && i > 0 {
                try? context.save()
                print("Generated \(i) items...")
            }
        }
        
        try? context.save()
        print("✅ Generated \(count) test items")
    }
    
    /// 根据学科获取标题
    private static func titleFor(subject: Subject, index: Int) -> String {
        let titles: [String]
        switch subject {
        case .math:
            titles = mathTitles
        case .chinese:
            titles = chineseTitles
        case .english:
            titles = englishTitles
        case .physics:
            titles = physicsTitles
        case .chemistry:
            titles = chemistryTitles
        default:
            titles = mathTitles
        }
        
        let baseTitle = titles[index % titles.count]
        let variant = index / titles.count + 1
        return variant > 1 ? "\(baseTitle) (\(variant))" : baseTitle
    }
    
    /// 根据学科获取知识点
    private static func knowledgePointsFor(subject: Subject) -> KnowledgePoints {
        if let samples = knowledgePointSamples[subject] {
            let points = samples.randomElement() ?? []
            return KnowledgePoints(points)
        }
        return .empty
    }
    
    /// 清除所有测试数据
    static func clearAll(in context: ModelContext) {
        do {
            try context.delete(model: ReviewItem.self)
            try context.save()
            print("✅ Cleared all test data")
        } catch {
            print("❌ Failed to clear data: \(error)")
        }
    }
}

#endif
