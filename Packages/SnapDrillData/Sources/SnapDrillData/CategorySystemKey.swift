//
//  CategorySystemKey.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  内置维度的稳定语义键。用于代码识别内置维度（学科/来源/年级/标签），
//  不依赖 name（可改/本地化）或 UUID（每次 seed 不同、CloudKit 会撞两份）。
//

import Foundation

/// 内置维度稳定语义键（与 CategoryDimensionRepository.seed 建立的 systemKey 一致）
public enum CategorySystemKey {
    public static let subject = "subject"
    public static let source = "source"
    public static let grade = "grade"
    public static let tag = "tag"
}
