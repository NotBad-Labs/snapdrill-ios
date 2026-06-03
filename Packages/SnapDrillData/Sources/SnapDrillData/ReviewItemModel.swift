//
//  ReviewItemModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
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

    // 索引：提升高频查询性能
    #Index<ReviewItemModel>(
        [\.createdAt],         // 题库列表默认排序
        [\.nextReviewAt]       // 待复习查询
        // L3：subjectRawValue 索引删除——学科改走 categoryValues 关系，关系不能进 #Index
    )

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

    /// 动态维度值集合（L3：跨所有维度的扁平多对多，按 value.dimension 反查归属）。
    /// 单值维度同维度下应只关联 0..1 个值（约束由 Repository/编辑逻辑保证，非 schema）。
    /// inverse 声明在本侧，指向 `CategoryValueModel.items`（对端裸关系，照搬 tags↔items 分工）。
    @Relationship(deleteRule: .nullify, inverse: \CategoryValueModel.items)
    public var categoryValues: [CategoryValueModel]? = []
    
    // MARK: - 答案与难度
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
    
    /// 创建复习题目
    /// - Parameters:
    ///   - id: 题目唯一 ID，默认自动生成
    ///   - content: 题目文字内容
    ///   - imagePath: 题目图片相对路径
    ///   - createdAt: 创建时间
    ///   - lastReviewedAt: 上次复习时间
    ///   - nextReviewAt: 下次计划复习时间
    ///   - subject: 所属学科名称
    ///   - source: 题目来源
    ///   - tags: 关联标签
    ///   - answerText: 答案文本
    ///   - answerImagePath: 答案图片路径
    ///   - difficulty: 难度原始值（1-5）
    ///   - grade: 适用年级
    ///   - easeFactor: SM-2 难度因子
    ///   - interval: SM-2 当前间隔天数
    ///   - repetitions: SM-2 连续正确次数
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
    /// 学科名称（等价于 `subjectRawValue`，保留用于向后兼容）
    public var subject: String {
        get { subjectRawValue }
        set { subjectRawValue = newValue }
    }

    /// 题目来源（等价于 `sourceRawValue`，保留用于向后兼容）
    public var source: String {
        get { sourceRawValue }
        set { sourceRawValue = newValue }
    }
    
    /// 是否已安排下次复习（false 表示从未复习或重置后的初始状态）
    ///
    /// 封装哨兵值语义，避免调用方直接比较 `Date.distantPast`。
    /// SwiftData 不存储计算属性，无需 `@Transient` 标注。
    public var isScheduled: Bool {
        nextReviewAt != .distantPast
    }

    /// 转为导出快照（仅含导出所需字段）
    public func toExportSnapshot() -> ReviewExportSnapshot {
        ReviewExportSnapshot(
            id: id,
            content: content,
            imagePath: imagePath,
            subject: subject,
            source: source,
            difficulty: difficulty,
            answerText: answerText,
            createdAt: createdAt,
            lastReviewedAt: lastReviewedAt == .distantPast ? nil : lastReviewedAt,
            nextReviewAt: nextReviewAt == .distantPast ? nil : nextReviewAt,
            tags: tags?.map(\.name) ?? []
        )
    }
}
