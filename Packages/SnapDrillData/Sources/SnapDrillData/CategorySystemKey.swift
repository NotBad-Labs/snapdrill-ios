//
//  CategorySystemKey.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  内置维度的稳定语义键。用于代码识别内置维度（分类/来源/级别/标签），
//  不依赖 name（可改/本地化）或 UUID（每次 seed 不同、CloudKit 会撞两份）。
//

import Foundation

/// 内置维度稳定语义键（与 CategoryDimensionRepository.seed 建立的 systemKey 一致）
///
/// 标 `nonisolated`：这些是不可变字符串常量，需被跨隔离引用——@Model（ReviewItemModel
/// 扩展逃逸 defaultIsolation 为 nonisolated）与 MainActor 的 ViewModel 都要用，
/// 否则 nonisolated 上下文引用 MainActor-isolated 静态属性会编译失败。
public enum CategorySystemKey {
    public nonisolated static let subject = "subject"
    public nonisolated static let source = "source"
    public nonisolated static let grade = "grade"
    public nonisolated static let tag = "tag"
}
