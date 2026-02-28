//
//  ReviewItem.swift
//  SnapDrillDomain
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  核心职责：定义题目复习条目领域实体（ReviewItem）。
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
public struct ReviewItem: Sendable, Identifiable, Codable, Hashable {
    /// 唯一标识符
    ///
    /// 用于在数据库和应用逻辑中唯一区分每个条目。
    public let id: UUID
    
    /// 题目内容文本（可选）
    ///
    /// 存储题目的文字描述、问题或笔记内容。
    /// - Note: 题目文字和题目图片至少有一个，不能同时为空。
    public var content: String?
    
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
    /// 答案文本（可选）
    public var answerText: String?
    /// 答案图片路径
    public var answerImagePath: String?
    /// 难度（1-5 星）
    public var difficulty: Difficulty
    /// 年级/掌握程度
    public var grade: String
    
    // MARK: - SM-2 Algorithm Fields
    /// 难度因子 (Ease Factor)，初始值 2.5，最小 1.3
    public var easeFactor: Double
    /// 当前复习间隔 (天数)
    public var interval: Int
    /// 连续正确复习次数
    public var repetitions: Int
    
    /// 初始化复习条目
    public init(
        id: UUID = UUID(),
        content: String? = nil,
        imagePath: String? = nil,
        createdAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date? = nil,
        subject: String = "其他",
        source: String = "其他",
        tags: [String] = [],
        answerText: String? = nil,
        answerImagePath: String? = nil,
        difficulty: Difficulty = .one,
        grade: String = "",
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0
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
        
        // SM-2 defaults
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
    }
}

