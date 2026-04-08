//
//  SnapDrillTips.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/04/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Tip 分级治理：
//  - 设备级 Tip → TipKit（全局 datastore，Apple 原生模型）
//  - Profile 级 Tip → ProfileTipState（per-profile UserDefaults 隔离）
//
//  当前 ReviewSwipeTip 和 FieldConfigTip 均为 Profile 级，
//  已迁移到 ProfileTipState 管理。TipKit 保留给未来设备级 Tip。
//

import SwiftUI
import TipKit

// MARK: - 设备级 Tip（TipKit，暂无，保留基础设施）

/// 复习滑动手势提示（保留 TipKit 定义供参考，实际展示由 ProfileTipState 控制）
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

/// 字段配置引导提示（保留 TipKit 定义供参考，实际展示由 ProfileTipState 控制）
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

// MARK: - Profile 级 Tip 状态管理

/// 管理 per-profile 的 Tip 展示状态
///
/// 通过 UserDefaults 的 per-profile 隔离机制（ProfileManager 在切换时同步偏好），
/// 实现每个 Profile 独立的 Tip 状态。
@Observable
public final class ProfileTipState {

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

    /// 从 UserDefaults 重新加载状态（Profile 切换后调用）
    public func reload() {
        let defaults = UserDefaults.standard
        showReviewSwipeTip = !defaults.bool(forKey: UDKey.tipReviewSwipeSeen)
        showFieldConfigTip = !defaults.bool(forKey: UDKey.tipFieldConfigSeen)
    }

    /// 重置所有 Profile 级 Tip 状态（当前 Profile）
    public func resetAll() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: UDKey.tipReviewSwipeSeen)
        defaults.removeObject(forKey: UDKey.tipFieldConfigSeen)
        showReviewSwipeTip = true
        showFieldConfigTip = true
    }
}
