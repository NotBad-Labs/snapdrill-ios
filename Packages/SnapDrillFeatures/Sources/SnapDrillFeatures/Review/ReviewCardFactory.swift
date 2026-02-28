//
//  ReviewCardFactory.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  工厂类，用于根据 ReviewItemModel 的类型生成对应的卡片视图。
//  遵循工厂方法模式 (Factory Method Pattern) 以支持扩展性（如未来支持图片题、选择题等）。
//

import SwiftUI
import SnapDrillDomain

/// 复习卡片工厂
///
/// 负责根据题目数据生成对应的 Front (问题) 和 Back (答案) 视图。
/// 目前默认生成文本类型的卡片。
public enum ReviewCardFactory {
    
    // MARK: - Public API
    
    /// 生成卡片正面视图
    /// - Parameter item: 复习数据模型 (Domain)
    /// - Returns: 针对该数据的正面视图
    @MainActor
    @ViewBuilder
    public static func makeFront(for item: ReviewItem) -> some View {
        ReviewCardFront(item: item)
    }
    
    /// 生成卡片背面视图
    /// - Parameter item: 复习数据模型 (Domain)
    /// - Returns: 针对该数据的背面视图
    @MainActor
    @ViewBuilder
    public static func makeBack(for item: ReviewItem) -> some View {
        ReviewCardBack(item: item)
    }
}
