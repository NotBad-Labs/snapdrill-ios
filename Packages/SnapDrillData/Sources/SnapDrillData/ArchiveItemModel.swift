//
//  ArchiveItemModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ArchiveItem 的 SwiftData 模型定义。
//

import Foundation
import SwiftData

/// SwiftData 数据模型
///
/// 直接作领域对象使用，通过 `toExportSnapshot()` 提供导出用只读视图。
@Model
public final class ArchiveItemModel {

    // 索引：提升高频查询性能
    #Index<ArchiveItemModel>(
        [\.createdAt],         // 资料库列表默认排序
        [\.nextReviewAt]       // 待复习查询
        // L3：旧裸字符串索引删除——分类改走 categoryValues 关系，关系不能进 #Index
    )

    // MARK: - Properties

    /// 唯一主键
    public var id: UUID = UUID()
    
    /// 资料内容（可选）
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

    /// 动态维度值集合（L3：跨所有维度的扁平多对多，按 value.dimension 反查归属）。
    /// 单值维度同维度下应只关联 0..1 个值（约束由 Repository/编辑逻辑保证，非 schema）。
    /// inverse 声明在本侧，指向 `CategoryValueModel.items`（对端裸关系，照搬 tags↔items 分工）。
    @Relationship(deleteRule: .nullify, inverse: \CategoryValueModel.items)
    public var categoryValues: [CategoryValueModel]? = []
    
    // MARK: - Answer
    /// 答案文本（可选）
    public var answerText: String?
    
    /// 答案图片路径
    public var answerImagePath: String?

    // MARK: - SM-2 Algorithm Fields
    /// 难度因子，初始 2.5，最小 1.3
    public var easeFactor: Double = 2.5
    /// 当前复习间隔 (天数)
    public var interval: Int = 0
    /// 连续正确复习次数
    public var repetitions: Int = 0
    
    // MARK: - Initialization
    
    /// 创建归档资料项
/// - Parameters:
    ///   - id: 资料项唯一 ID，默认自动生成
    ///   - content: 资料项文字内容
    ///   - imagePath: 资料项图片相对路径
    ///   - createdAt: 创建时间
    ///   - lastReviewedAt: 上次复习时间
    ///   - nextReviewAt: 下次计划复习时间
    ///   - answerText: 答案文本
    ///   - answerImagePath: 答案图片路径
    ///   - easeFactor: SM-2 难度因子
    ///   - interval: SM-2 当前间隔天数
    ///   - repetitions: SM-2 连续正确次数
    /// - Note: 分类（分类/来源/级别/标签 + 自定义）经 `categoryValues` 动态维度，构造后赋值。
    public init(
        id: UUID = UUID(),
        content: String? = nil,
        imagePath: String? = nil,
        createdAt: Date = Date(),
        lastReviewedAt: Date = .distantPast,
        nextReviewAt: Date = .distantPast,
        answerText: String? = nil,
        answerImagePath: String? = nil,
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

        self.answerText = answerText
        self.answerImagePath = answerImagePath

        // SM-2
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
    }

    // MARK: - Public API

    /// 是否已安排下次复习（false 表示从未复习或重置后的初始状态）
    ///
    /// 封装哨兵值语义，避免调用方直接比较 `Date.distantPast`。
    /// SwiftData 不存储计算属性，无需 `@Transient` 标注。
    public var isScheduled: Bool {
        nextReviewAt != .distantPast
    }

    /// 转为导出快照（仅含导出所需字段）。分类经动态维度值聚合（A2 动态列）。
    public func toExportSnapshot() -> ArchiveExportSnapshot {
        var dimensionValues: [String: [String]] = [:]
        for entry in categoryValuesByDimension {
            dimensionValues[entry.dimension.name] = entry.values.map { $0.name }
        }
        return ArchiveExportSnapshot(
            id: id,
            content: content,
            imagePath: imagePath,
            category: primaryCategoryName ?? "",
            answerText: answerText,
            createdAt: createdAt,
            lastReviewedAt: lastReviewedAt == .distantPast ? nil : lastReviewedAt,
            nextReviewAt: nextReviewAt == .distantPast ? nil : nextReviewAt,
            dimensionValues: dimensionValues
        )
    }
}
