//
//  ReviewItem+Display.swift
//  NotBad
//
//  显示属性扩展（纯 Domain 层，无 UI 依赖）
//
//  Note: UI 相关的显示属性已移至 Presentation/Common/Extensions/ReviewItem+UI.swift
//

import Foundation

// MARK: - ReviewItem Display Properties

extension ReviewItem {

    /// 显示标题
    ///
    /// 处理标题的显示逻辑，使用统一的 `normalizeTitle` 方法：
    /// - 去除首尾空白字符
    /// - 如果结果为空，返回本地化的默认标题
    ///
    /// - Note: 与初始化时的默认标题逻辑完全一致
    var displayTitle: String {
        Self.normalizeTitle(title)
    }
}

// MARK: - ReviewItem CustomStringConvertible

extension ReviewItem: CustomStringConvertible {

    /// 调试描述
    nonisolated var description: String {
        "ReviewItem(\(displayTitle), \(subjectRaw), \(gradeRaw), \(masteryLevel))"
    }
}
