//
//  CustomSubject.swift
//  NotBad
//
//  用户自定义学科
//

import Foundation

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
struct CustomSubject: Sendable, Codable, Hashable, Identifiable {
    
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
