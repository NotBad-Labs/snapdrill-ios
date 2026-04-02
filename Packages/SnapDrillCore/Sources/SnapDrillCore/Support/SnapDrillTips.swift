//
//  SnapDrillTips.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/04/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  TipKit 提示定义。替代自定义 FeatureTooltip + OnboardingManager 的提示功能。
//

import TipKit

/// 复习滑动手势提示：首次进入复习时显示
public struct ReviewSwipeTip: Tip {
    public var title: Text {
        Text(L10n.Review.tooltipTitle)
    }

    public var message: Text? {
        Text(L10n.Review.tooltipMessage)
    }

    public var image: Image? {
        Image(systemName: "hand.draw")
    }

    public init() {}
}

/// 字段配置引导提示：首次保存题目后显示
public struct FieldConfigTip: Tip {
    public var title: Text {
        Text(L10n.Onboarding.fieldConfigTitle)
    }

    public var message: Text? {
        Text(L10n.Onboarding.fieldConfigDescription)
    }

    public var image: Image? {
        Image(systemName: "slider.horizontal.3")
    }

    public init() {}
}
