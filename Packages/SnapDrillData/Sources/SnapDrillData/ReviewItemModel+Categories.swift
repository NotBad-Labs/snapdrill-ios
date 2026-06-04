//
//  ReviewItemModel+Categories.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ReviewItemModel 的动态分类值（categoryValues）展示辅助（L3）。
//  消费链（库列表/详情/分享卡/统计）经这些 helper 读分类，取代旧 subject/source/grade/tags 字段。
//

import Foundation

extension ReviewItemModel {

    /// 某维度（按 systemKey）下该题的值名（按值 sortOrder）
    public func categoryValueNames(forSystemKey systemKey: String) -> [String] {
        (categoryValues ?? [])
            .filter { $0.dimension?.systemKey == systemKey }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { $0.name }
    }

    /// 学科维度的首个值名（列表行/分享卡主标签用；无则 nil）
    public var subjectCategoryName: String? {
        categoryValueNames(forSystemKey: CategorySystemKey.subject).first
    }

    /// 标签维度（多值）的所有值名（分享卡/批量场景用）
    public var tagCategoryNames: [String] {
        categoryValueNames(forSystemKey: CategorySystemKey.tag)
    }

    /// 分类值按维度分组（详情页动态展示用），维度按 sortOrder、维度内值按 sortOrder
    public var categoryValuesByDimension: [(dimension: CategoryDimensionModel, values: [CategoryValueModel])] {
        Dictionary(grouping: categoryValues ?? []) { $0.dimension }
            .compactMap { key, values -> (CategoryDimensionModel, [CategoryValueModel])? in
                guard let dimension = key else { return nil }
                return (dimension, values.sorted { $0.sortOrder < $1.sortOrder })
            }
            .sorted { $0.0.sortOrder < $1.0.sortOrder }
    }
}
