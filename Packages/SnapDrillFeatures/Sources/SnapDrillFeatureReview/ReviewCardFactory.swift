//
//  ReviewCardFactory.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  工厂类，根据 ReviewItemModel 生成对应的复习卡片视图。
//

import SwiftUI
import SnapDrillData

/// 复习卡片工厂
///
/// 负责根据题目数据生成对应的 Front（问题）和 Back（答案）视图。
enum ReviewCardFactory {

    // MARK: - Internal API

    /// 生成卡片正面视图
    @ViewBuilder
    static func makeFront(for item: ReviewItemModel, showsActions: Bool = true) -> some View {
        ReviewCardFront(item: item, showsActions: showsActions)
    }

    /// 生成卡片背面视图
    @ViewBuilder
    static func makeBack(for item: ReviewItemModel, showsActions: Bool = true) -> some View {
        ReviewCardBack(item: item, showsActions: showsActions)
    }
}
