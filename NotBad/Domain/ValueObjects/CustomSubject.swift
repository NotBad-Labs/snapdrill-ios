//
//  CustomSubject.swift
//  NotBad
//
//  用户自定义学科
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - CustomSubject

/// 用户自定义学科
///
/// 允许用户创建预设学科列表之外的学科，如艺术、音乐、体育等。
/// 自定义学科不参与本地化，用户输入什么就显示什么。
///
/// ## 使用示例
/// ```swift
/// let art = CustomSubject(name: "美术", icon: "paintpalette", colorHex: "#FF6B6B")
/// print(art.displayName)  // "美术"
/// ```
struct CustomSubject: Identifiable, Codable, Hashable, Sendable {
    
    // MARK: - Properties
    
    /// 唯一标识符
    let id: UUID
    
    /// 学科名称（用户输入）
    var name: String
    
    /// SF Symbol 图标名称
    var icon: String
    
    /// 颜色（十六进制）
    var colorHex: String
    
    /// 学科分类
    var category: SubjectCategory
    
    /// 适用的学段
    var applicableStages: Set<GradeStage>
    
    /// 创建时间
    let createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 排序顺序
    var sortOrder: Int
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "book.closed",
        colorHex: String = "#6B7280",
        category: SubjectCategory = .other,
        applicableStages: Set<GradeStage> = Set(GradeStage.allCases),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
        self.applicableStages = applicableStages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }
    
    // MARK: - Display Properties
    
    /// 显示名称（直接返回用户输入的名称）
    var displayName: String { name }
    
    /// 简短标签（取名称的第一个字符）
    var shortLabel: String {
        String(name.prefix(1))
    }
    
    /// 颜色
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
    
    /// 是否适用于指定学段
    func isApplicable(for stage: GradeStage) -> Bool {
        applicableStages.contains(stage)
    }
    
    /// 是否适用于指定年级
    func isApplicable(for grade: Grade) -> Bool {
        applicableStages.contains(grade.stage)
    }
    
    /// 获取适用的年级列表
    var applicableGrades: [Grade] {
        Grade.allCases.filter { grade in
            grade != .kindergarten && applicableStages.contains(grade.stage)
        }
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
