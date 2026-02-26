//
//  ReviewItemModel.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  ReviewItem 的 SwiftData 模型定义。
//

import Foundation
import SwiftData
import SnapDrillCore

/// SwiftData 数据模型
///
/// 对应 `SnapDrillCore` 中的 ``ReviewItem`` 实体，用于本地持久化存储。
/// 它将 Domain 层的逻辑实体映射为数据库表结构。
///
/// ## 架构设计
/// 这个模型通过 `toEntity()` 方法将自身转换为纯 Swift 结构体，供业务逻辑层使用。
/// 这种设计隔离了数据库实现细节（SwiftData）和核心业务逻辑（Core）。
///
/// - SeeAlso: `ReviewItem`
@Model
public final class ReviewItemModel {
    
    // MARK: - Properties
    
    /// 唯一主键
    public var id: UUID = UUID()
    
    /// 题目内容
    public var content: String = ""
    
    /// 图片相对路径
    /// - Note: 仅保存文件名或相对路径，根目录由 `ImageStorage` 管理
    public var imagePath: String?
    
    /// 创建时间
    public var createdAt: Date = Date()
    
    /// 上次复习时间
    public var lastReviewedAt: Date?
    
    /// 下次计划复习时间
    public var nextReviewAt: Date?
    
    // 存储枚举的原始值
    /// 学科 (String)
    public var subjectRawValue: String = "其他"
    /// 来源 (String)
    public var sourceRawValue: String = "其他"
    
    /// 标签集合 (Many-to-Many Relationship)
    @Relationship(deleteRule: .nullify, inverse: \TagModel.items)
    public var tags: [TagModel]? = []
    
    // MARK: - Schema V2 Fields
    /// 答案文本
    public var answerText: String = ""
    
    /// 答案图片路径
    public var answerImagePath: String?
    
    /// 难度等级 (1-5)
    public var difficulty: Int = 0
    
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
        content: String,
        imagePath: String? = nil,
        createdAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date? = nil,
        subject: String = "其他",
        source: String = "其他",
        tags: [TagModel]? = [],
        answerText: String = "",
        answerImagePath: String? = nil,
        difficulty: Int = 0,
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
    
    // 转换为 Core 实体
    public func toEntity() -> ReviewItem {
        ReviewItem(
            id: id,
            content: content,
            imagePath: imagePath,
            createdAt: createdAt,
            lastReviewedAt: lastReviewedAt,
            nextReviewAt: nextReviewAt,
            subject: subject,
            source: source,
            tags: (tags ?? []).map { $0.name },
            answerText: answerText,
            answerImagePath: answerImagePath,
            difficulty: difficulty,
            grade: grade,
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions
        )
    }
}
