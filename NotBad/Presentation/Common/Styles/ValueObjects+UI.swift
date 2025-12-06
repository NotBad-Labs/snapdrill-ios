//
//  ValueObjects+UI.swift
//  NotBad
//
//  值对象的 UI 扩展（精简版）
//
//  仅保留必要的颜色定义：
//  - MasteryLevel: 红→绿渐变表示掌握程度（有语义含义）
//  - Subject: 用于图表和标签的区分色
//  - CustomSubject: 用户自定义颜色
//
//  其他值对象通过 icon + displayName 传达信息，符合无障碍设计原则。
//

import SwiftUI
import ReviewKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - MasteryLevel + UI

extension MasteryLevel {
    /// 掌握度颜色
    ///
    /// 从红（未掌握）到绿（已掌握）的渐进色系
    /// 注意：颜色仅作为辅助，主要信息通过 stars、displayName 传达
    var color: Color {
        switch self {
        case .none: Color.brand.error
        case .glimpse: Color.brand.warning
        case .partial: .yellow
        case .good: .mint
        case .mastered: Color.brand.success
        }
    }
}

// MARK: - Subject + UI

extension Subject {
    /// 学科颜色（用于图表区分）
    var color: Color {
        switch self {
        case .chinese: .red
        case .english: .purple
        case .math: .blue
        case .physics: .orange
        case .chemistry: .green
        case .biology: .mint
        case .science: .cyan
        case .history: .brown
        case .geography: .teal
        case .politics: .indigo
        case .ethics: .pink
        case .informationTech: .purple
        case .generalTech: .gray
        case .other: .secondary
        }
    }
}

// MARK: - CustomSubject + UI

extension CustomSubject {
    /// 用户自定义颜色（从 colorHex 转换）
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}

// MARK: - Color Extension

extension Color {
    /// 从十六进制字符串创建颜色
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        switch length {
        case 6:
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        case 8:
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        default:
            return nil
        }
    }
    
    /// 转换为十六进制字符串
    func toHex() -> String? {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = components.count >= 1 ? components[0] : 0
        let g = components.count >= 2 ? components[1] : 0
        let b = components.count >= 3 ? components[2] : 0
        
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        #else
        return nil
        #endif
    }
}
