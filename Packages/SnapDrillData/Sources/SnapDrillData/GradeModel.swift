//
//  GradeModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义年级的 SwiftData 模型，与 Subject/Source 对等。
//

import Foundation
import SwiftData

/// 年级数据模型
@Model
public final class GradeModel {

    // MARK: - Properties

    /// 唯一标识
    public var id: UUID = UUID()

    /// 年级名称 (e.g. "高一", "初二")
    public var name: String = ""

    /// 排序权重（越小越靠前）
    public var sortOrder: Int = 0

    // MARK: - Initialization

    /// 创建年级模型
    /// - Parameters:
    ///   - id: 唯一标识，默认自动生成
    ///   - name: 年级名称，如 "高一"
    ///   - sortOrder: 排序权重，默认 0
    public init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
    }

}
