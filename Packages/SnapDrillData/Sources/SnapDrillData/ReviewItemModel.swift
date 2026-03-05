//
//  ReviewItemModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ReviewItem 的 SwiftData 模型定义。
//

import Foundation
import SwiftData
import SnapDrillCore

/// SwiftData 数据模型
///
/// 直接作领域对象使用，通过 `toExportSnapshot()` 提供导出用只读视图。
@Model
public final class ReviewItemModel {
    
    // MARK: - Properties
    
    /// 唯一主键
    public var id: UUID = UUID()
    
    /// 题目内容（可选）
    /// - Note: 与 imagePath 至少有一个非空
    public var content: String?
    
    /// 图片相对路径
    /// - Note: 仅保存文件名或相对路径，根目录由 `ImageStorage` 管理
    public var imagePath: String?
    
    /// 创建时间
    public var createdAt: Date = Date()
    
    /// 上次复习时间（distantPast 表示从未复习）
    public var lastReviewedAt: Date = Date.distantPast

    /// 下次计划复习时间（distantPast 表示尚未安排，立即到期）
    public var nextReviewAt: Date = Date.distantPast
    
    // 存储枚举的原始值
    /// 学科 (String)
    public var subjectRawValue: String = "其他"
    /// 来源 (String)
    public var sourceRawValue: String = "其他"
    
    /// 标签集合 (Many-to-Many Relationship)
    @Relationship(deleteRule: .nullify, inverse: \TagModel.items)
    public var tags: [TagModel]? = []
    
    // MARK: - Schema V2 Fields
    /// 答案文本（可选）
    public var answerText: String?
    
    /// 答案图片路径
    public var answerImagePath: String?
    
    /// 难度等级原始值 (1-5)，通过 `difficultyValue` 访问枚举类型
    public var difficulty: Int = 1

    /// 难度枚举访问器（rawValue 桥接）
    public var difficultyValue: Difficulty {
        get { Difficulty(rawValue: difficulty) ?? .one }
        set { difficulty = newValue.rawValue }
    }
    
    /// 适用年级
    public var grade: String = ""
    
    // MARK: - SM-2 Algorithm Fields
    /// 难度因子，初始 2.5，最小 1.3
    public var easeFactor: Double = 2.5
    /// 当前复习间隔 (天数)
    public var interval: Int = 0
    /// 连续正确复习次数
    public var repetitions: Int = 0
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        content: String? = nil,
        imagePath: String? = nil,
        createdAt: Date = Date(),
        lastReviewedAt: Date = .distantPast,
        nextReviewAt: Date = .distantPast,
        subject: String = "其他",
        source: String = "其他",
        tags: [TagModel]? = [],
        answerText: String? = nil,
        answerImagePath: String? = nil,
        difficulty: Int = 1,
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
        self.subjectRawValue = subject
        self.sourceRawValue = source
        self.tags = tags
        
        // V2
        self.answerText = answerText
        self.answerImagePath = answerImagePath
        self.difficulty = difficulty
        self.grade = grade
        
        // SM-2
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
    }
    
    // MARK: - Public API
    
    // 兼容旧代码的计算属性 (现在直接返回 String)
    public var subject: String {
        get { subjectRawValue }
        set { subjectRawValue = newValue }
    }
    
    public var source: String {
        get { sourceRawValue }
        set { sourceRawValue = newValue }
    }
    
    /// 转为导出快照（仅含导出所需字段）
    public func toExportSnapshot() -> ReviewExportSnapshot {
        ReviewExportSnapshot(
            id: id,
            content: content,
            imagePath: imagePath,
            subject: subject,
            source: source,
            createdAt: createdAt
        )
    }
}
