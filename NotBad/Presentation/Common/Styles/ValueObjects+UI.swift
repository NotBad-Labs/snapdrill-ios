//
//  ValueObjects+UI.swift
//  NotBad
//
//  值对象的 UI 扩展
//
//  将值对象的 UI 相关属性（Color、Image 等）从 Domain 层分离到 Presentation 层，
//  确保 Domain 层不依赖 SwiftUI 框架。
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Difficulty + UI

// Note: Difficulty 不再提供 color 属性
// 难度信息通过 displayName、shortLabel、icon、stars 传达
// 这符合无障碍设计原则：不仅依赖颜色传达信息

// MARK: - MasteryLevel + UI

extension MasteryLevel {
    /// 主题颜色
    ///
    /// 从红（未掌握）到绿（已掌握）的渐进色系
    var uiColor: Color {
        switch self {
        case .none: Color.brand.error
        case .glimpse: Color.brand.warning
        case .partial: .yellow
        case .good: .mint
        case .mastered: Color.brand.success
        }
    }
}

// MARK: - SubjectCategory + UI

extension SubjectCategory {
    /// 主题颜色
    var uiColor: Color {
        switch self {
        case .language: .red
        case .science: .blue
        case .humanities: .orange
        case .technology: .purple
        case .other: .gray
        }
    }
}

// MARK: - Subject + UI

extension Subject {
    /// 主题颜色
    var uiColor: Color {
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

// MARK: - Grade + UI

extension Grade {
    /// 主题颜色（同学段渐变）
    var uiColor: Color {
        switch self {
        // 幼儿园：粉色系
        case .kindergarten: .pink
        // 小学：绿色系
        case .grade1: .mint
        case .grade2: .green
        case .grade3: .teal
        case .grade4: .cyan
        case .grade5: .blue
        case .grade6: .indigo
        // 初中：暖色系
        case .grade7: .yellow
        case .grade8: .orange
        case .grade9: .red
        // 高中：紫色系
        case .grade10: .pink
        case .grade11: .purple
        case .grade12: Color(red: 0.5, green: 0, blue: 0.5)
        }
    }
}

// MARK: - GradeStage + UI

extension GradeStage {
    /// 主题颜色
    var uiColor: Color {
        switch self {
        case .primary: .green
        case .junior: .orange
        case .senior: .purple
        }
    }
}

// MARK: - ErrorType + UI

extension ErrorType {
    /// 主题颜色
    var uiColor: Color {
        switch self {
        case .concept: .purple
        case .forgotten: .indigo
        case .method: .red
        case .wrongDirection: .pink
        case .calculation: .blue
        case .careless: .yellow
        case .misread: .orange
        case .incomplete: .mint
        case .timeLimit: .gray
        case .other: .secondary
        }
    }
}

// MARK: - ErrorCategory + UI

extension ErrorCategory {
    /// 主题颜色
    var uiColor: Color {
        switch self {
        case .knowledge: .purple
        case .method: .red
        case .habit: .orange
        case .objective: .gray
        case .other: .secondary
        }
    }
}

// MARK: - Source + UI

extension Source {
    /// 主题颜色
    var uiColor: Color {
        switch self {
        case .textbook: .blue
        case .pastExam: .red
        case .exam: .red
        case .mock: .orange
        case .homework: .green
        case .workbook: .cyan
        case .tutor: .purple
        case .competition: .yellow
        case .online: .indigo
        case .selfTest: .mint
        case .other: .gray
        }
    }
}

// MARK: - SourceCategory + UI

extension SourceCategory {
    /// 主题颜色
    var uiColor: Color {
        switch self {
        case .official: .red
        case .school: .blue
        case .extra: .orange
        case .other: .gray
        }
    }
}

// MARK: - ReviewItemType + UI

extension ReviewItemType {
    /// 主题颜色
    var uiColor: Color {
        switch self {
        case .choice: .blue
        case .multiChoice: .indigo
        case .judgment: .cyan
        case .fillBlank: .green
        case .matching: .teal
        case .shortAnswer: .orange
        case .calculation: .red
        case .proof: .purple
        case .drawing: .pink
        case .experiment: .mint
        case .analysis: .brown
        case .reading: .yellow
        case .writing: .red
        case .cloze: .indigo
        case .other: .gray
        }
    }
}

// MARK: - ReviewItemCategory + UI

extension ReviewItemCategory {
    /// 主题颜色
    var uiColor: Color {
        switch self {
        case .objective: .blue
        case .subjective: .orange
        case .comprehensive: .purple
        case .other: .gray
        }
    }
}

// MARK: - CustomSubject + UI

extension CustomSubject {
    /// 颜色（从 colorHex 转换）
    var uiColor: Color {
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

// MARK: - Deprecated Color Accessors

// 为了向后兼容，提供与原 `color` 属性同名的计算属性
// 这些会在编译时产生警告，提示开发者迁移到 `uiColor`

// Difficulty.color 已删除 - 使用 displayName/icon/stars 替代

extension MasteryLevel {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension SubjectCategory {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension Subject {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension Grade {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension GradeStage {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension ErrorType {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension ErrorCategory {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension Source {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension SourceCategory {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension ReviewItemType {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension ReviewItemCategory {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}

extension CustomSubject {
    @available(*, deprecated, renamed: "uiColor", message: "Use uiColor instead. color has been moved to Presentation layer.")
    var color: Color { uiColor }
}
