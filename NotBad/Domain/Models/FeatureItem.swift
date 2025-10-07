//
//  FeatureItem.swift
//  NotBad
//
//  Created by Yiming Liao on 10/7/25.
//

import Foundation

/// 特性项目模型
///
/// 职责：
/// - 表示应用的一个特性
/// - 用于展示特性列表
struct FeatureItem: Identifiable, Sendable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}
