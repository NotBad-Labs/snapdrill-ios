//
//  LocalizationHelper.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  本地化工具函数（与 L10n 命名空间解耦）。
//

import Foundation

/// 本地化辅助工具
nonisolated public enum LocalizationHelper {
    /// 获取当前语言代码
    public static var currentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "zh"
    }

    /// 是否为中文环境
    public static var isChineseLocale: Bool {
        currentLanguageCode.hasPrefix("zh")
    }

    /// 是否为英文环境
    public static var isEnglishLocale: Bool {
        currentLanguageCode.hasPrefix("en")
    }

    /// 格式化数字（带本地化）
    public static func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// 格式化日期（带本地化）
    public static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// 格式化时间（带本地化）
    public static func formatTime(_ date: Date, style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = style
        return formatter.string(from: date)
    }

    /// 格式化日期时间（带本地化）
    public static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
