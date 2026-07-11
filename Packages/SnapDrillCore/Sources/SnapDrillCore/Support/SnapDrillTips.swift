//
//  SnapDrillTips.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Tip 分级治理：
//  - 设备级 Tip → TipKit（全局 datastore，Apple 原生模型）
//  - 功能 Tip → FeatureTipState（设备级 UserDefaults）
//
//  当前 ReviewSwipeTip 和 FieldConfigTip 由 FeatureTipState 管理。
//

import SwiftUI
import TipKit

// MARK: - 设备级 Tip（TipKit，暂无，保留基础设施）

/// 回顾滑动手势提示（保留 TipKit 定义供参考，实际展示由 FeatureTipState 控制）
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

/// 字段配置引导提示（保留 TipKit 定义供参考，实际展示由 FeatureTipState 控制）
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

// MARK: - Tip 状态管理

/// 管理设备级 Tip 展示状态。
@Observable
public final class FeatureTipState {

    /// 复习滑动提示是否应该显示
    public var showReviewSwipeTip: Bool

    /// 字段配置提示是否应该显示
    public var showFieldConfigTip: Bool

    public init() {
        let defaults = UserDefaults.standard
        // 未看过（false）→ 应该显示（true）
        self.showReviewSwipeTip = !defaults.bool(forKey: UDKey.tipReviewSwipeSeen)
        self.showFieldConfigTip = !defaults.bool(forKey: UDKey.tipFieldConfigSeen)
    }

    /// 标记复习滑动提示已展示
    public func markReviewSwipeSeen() {
        showReviewSwipeTip = false
        UserDefaults.standard.set(true, forKey: UDKey.tipReviewSwipeSeen)
    }

    /// 标记字段配置提示已展示
    public func markFieldConfigSeen() {
        showFieldConfigTip = false
        UserDefaults.standard.set(true, forKey: UDKey.tipFieldConfigSeen)
    }

    /// 重置所有 Tip 状态
    public func resetAll() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: UDKey.tipReviewSwipeSeen)
        defaults.removeObject(forKey: UDKey.tipFieldConfigSeen)
        showReviewSwipeTip = true
        showFieldConfigTip = true
    }
}
