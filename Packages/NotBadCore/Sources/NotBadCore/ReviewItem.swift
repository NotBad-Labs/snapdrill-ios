//
//  ReviewItem.swift
//  NotBadCore
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  复习条目核心数据模型，定义题目实体和学科类型
//

import Foundation

/// 复习条目实体
///
/// `ReviewItem` 是整个应用的核心数据模型，代表一个独立的学习单元或题目。
/// 它包含了题目的内容、元数据（学科、来源、标签）以及用于间隔重复算法的调度信息。
///
/// ## Topics
///
/// ### 核心内容
/// - ``content``
/// - ``imagePath``
///
/// ### 元数据
/// - ``subject``
/// - ``source``
/// - ``tags``
///
/// ### 调度信息
/// - ``createdAt``
/// - ``lastReviewedAt``
/// - ``nextReviewAt``
public struct ReviewItem: Sendable, Identifiable, Codable {
    /// 唯一标识符
    ///
    /// 用于在数据库和应用逻辑中唯一区分每个条目。
    public let id: UUID
    
    /// 题目内容文本
    ///
    /// 存储题目的文字描述、问题或笔记内容。
    public var content: String
    
    /// 关联图片路径（可选）
    ///
    /// 存储原始图片在本地文件系统中的相对路径。
    /// - Note: 实际图片数据由 `ImageStorage` 服务管理，此处仅保存引用。
    public var imagePath: String?
    
    /// 创建时间
    ///
    /// 条目首次被添加到题库的时间。
    public var createdAt: Date
    
    /// 上次复习时间（可选）
    ///
    /// 最近一次完成复习的时间点。如果从未复习过，则为 `nil`。
    public var lastReviewedAt: Date?
    
    /// 下次复习时间（可选）
    ///
    /// 由复习调度算法计算出的下一次建议复习时间。
    /// - Important: 此字段用于生成“今日待复习”列表。
    public var nextReviewAt: Date?
    
    /// 学科
    ///
    /// 题目所属的学科分类，如语文、数学等。支持自定义。
    public var subject: String
    
    /// 来源
    ///
    /// 题目的来源渠道，如试卷、错题本等。支持自定义。
    public var source: String
    
    /// 标签
    ///
    /// 用户自定义的标签集合，用于灵活分类和检索。
    public var tags: [String]
    
    // MARK: - V2 Fields
    /// 答案文本
    public var answerText: String
    /// 答案图片路径
    public var answerImagePath: String?
    /// 难度 (1-5)
    public var difficulty: Int
    /// 年级/掌握程度
    public var grade: String
    
    /// 初始化复习条目
    public init(
        id: UUID = UUID(),
        content: String,
        imagePath: String? = nil,
        createdAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date? = nil,
        subject: String = "其他",
        source: String = "其他",
        tags: [String] = [],
        answerText: String = "",
        answerImagePath: String? = nil,
        difficulty: Int = 0,
        grade: String = ""
    ) {
        self.id = id
        self.content = content
        self.imagePath = imagePath
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
        self.subject = subject
        self.source = source
        self.tags = tags
        
        self.answerText = answerText
        self.answerImagePath = answerImagePath
        self.difficulty = difficulty
        self.grade = grade
    }
}

/// 学科预设
public enum SubjectPreset: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case chinese = "语文"
    case mathematics = "数学"
    case english = "英语"
    case physics = "物理"
    case chemistry = "化学"
    case biology = "生物"
    case history = "历史"
    case geography = "地理"
    case politics = "政治"
    case other = "其他"
}

/// 来源预设
public enum ReviewSourcePreset: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    case exam = "试卷"
    case homework = "作业"
    case textbook = "教材"
    case wrongBook = "错题本"
    case other = "其他"
}
