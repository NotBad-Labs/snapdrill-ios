//
//  KnowledgePoints.swift
//  NotBad
//
//  知识点值对象 - 不可变集合设计
//

import Foundation

/// 知识点集合
///
/// 表示一道错题涉及的知识点列表，如 ["函数", "导数", "极限"]
/// 遵循值对象原则：不可变，所有操作返回新实例
struct KnowledgePoints: Equatable, Codable, Hashable {
    private var items: [String]
    
    /// 空知识点集合
    static let empty = KnowledgePoints([])
    
    // MARK: - Initialization
    
    init(_ items: [String] = []) {
        // 去重、去空、去首尾空格
        self.items = items
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .uniqued()
    }
    
    /// 从逗号分隔的字符串创建
    init(from string: String) {
        let components = string.components(separatedBy: ",")
        self.init(components)
    }
    
    // MARK: - Properties
    
    /// 知识点数组
    var array: [String] { items }
    
    /// 知识点数量
    var count: Int { items.count }
    
    /// 是否为空
    var isEmpty: Bool { items.isEmpty }
    
    /// 是否非空
    var isNotEmpty: Bool { !items.isEmpty }
    
    /// 第一个知识点
    var first: String? { items.first }
    
    /// 最后一个知识点
    var last: String? { items.last }
    
    /// 转换为逗号分隔的字符串（用于存储）
    var rawValue: String {
        items.joined(separator: ", ")
    }
    
    // MARK: - Operations
    
    /// 添加单个知识点
    func adding(_ point: String) -> KnowledgePoints {
        let trimmed = point.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !items.contains(trimmed) else { return self }
        return KnowledgePoints(items + [trimmed])
    }
    
    /// 批量添加知识点
    func adding(_ points: [String]) -> KnowledgePoints {
        var newItems = items
        for point in points {
            let trimmed = point.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !newItems.contains(trimmed) {
                newItems.append(trimmed)
            }
        }
        return KnowledgePoints(newItems)
    }
    
    /// 移除单个知识点
    func removing(_ point: String) -> KnowledgePoints {
        KnowledgePoints(items.filter { $0 != point })
    }
    
    /// 批量移除知识点
    func removing(_ points: [String]) -> KnowledgePoints {
        let pointsSet = Set(points)
        return KnowledgePoints(items.filter { !pointsSet.contains($0) })
    }
    
    /// 合并知识点集合
    func merging(with other: KnowledgePoints) -> KnowledgePoints {
        KnowledgePoints(items + other.items)
    }
    
    /// 取交集
    func intersection(with other: KnowledgePoints) -> KnowledgePoints {
        let otherSet = Set(other.items)
        return KnowledgePoints(items.filter { otherSet.contains($0) })
    }
    
    /// 是否包含知识点
    func contains(_ point: String) -> Bool {
        items.contains(point)
    }
    
    /// 是否包含任意一个知识点
    func containsAny(of points: [String]) -> Bool {
        let pointsSet = Set(points)
        return items.contains { pointsSet.contains($0) }
    }
    
    /// 是否包含所有知识点
    func containsAll(of points: [String]) -> Bool {
        let itemsSet = Set(items)
        return points.allSatisfy { itemsSet.contains($0) }
    }
    
    /// 搜索匹配（模糊搜索）
    func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowercasedQuery = query.lowercased()
        return items.contains { $0.lowercased().contains(lowercasedQuery) }
    }
    
    /// 过滤包含关键词的知识点
    func filter(containing keyword: String) -> KnowledgePoints {
        guard !keyword.isEmpty else { return self }
        let lowercasedKeyword = keyword.lowercased()
        return KnowledgePoints(items.filter { $0.lowercased().contains(lowercasedKeyword) })
    }
    
    /// 排序后的知识点
    func sorted() -> KnowledgePoints {
        KnowledgePoints(items.sorted())
    }
    
    /// 下标访问
    subscript(index: Int) -> String? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }
}

// MARK: - Sequence

extension KnowledgePoints: Sequence {
    func makeIterator() -> IndexingIterator<[String]> {
        items.makeIterator()
    }
}

// MARK: - Collection

extension KnowledgePoints: Collection {
    var startIndex: Int { items.startIndex }
    var endIndex: Int { items.endIndex }
    
    func index(after i: Int) -> Int {
        items.index(after: i)
    }
    
    subscript(position: Int) -> String {
        items[position]
    }
}

// MARK: - ExpressibleByArrayLiteral

extension KnowledgePoints: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: String...) {
        self.init(elements)
    }
}

// MARK: - CustomStringConvertible

extension KnowledgePoints: CustomStringConvertible {
    var description: String { rawValue }
}

// MARK: - 常用知识点预设

extension KnowledgePoints {
    /// 数学常用知识点
    enum Math {
        static let algebra = "代数"
        static let geometry = "几何"
        static let function = "函数"
        static let equation = "方程"
        static let inequality = "不等式"
        static let sequence = "数列"
        static let probability = "概率"
        static let statistics = "统计"
        static let derivative = "导数"
        static let integral = "积分"
        static let vector = "向量"
        static let trigonometry = "三角函数"
        static let solidGeometry = "立体几何"
        static let analyticGeometry = "解析几何"
        
        static var all: [String] {
            [algebra, geometry, function, equation, inequality, sequence, 
             probability, statistics, derivative, integral, vector, 
             trigonometry, solidGeometry, analyticGeometry]
        }
    }
    
    /// 物理常用知识点
    enum Physics {
        static let mechanics = "力学"
        static let kinematics = "运动学"
        static let dynamics = "动力学"
        static let energy = "能量"
        static let electricity = "电学"
        static let magnetism = "磁学"
        static let optics = "光学"
        static let thermodynamics = "热学"
        static let waves = "波动"
        static let modern = "近代物理"
        
        static var all: [String] {
            [mechanics, kinematics, dynamics, energy, electricity, 
             magnetism, optics, thermodynamics, waves, modern]
        }
    }
    
    /// 化学常用知识点
    enum Chemistry {
        static let organic = "有机化学"
        static let inorganic = "无机化学"
        static let reaction = "化学反应"
        static let equilibrium = "化学平衡"
        static let electrochemistry = "电化学"
        static let structure = "物质结构"
        static let element = "元素化学"
        
        static var all: [String] {
            [organic, inorganic, reaction, equilibrium, electrochemistry, structure, element]
        }
    }
    
    /// 英语常用知识点
    enum English {
        static let grammar = "语法"
        static let vocabulary = "词汇"
        static let reading = "阅读"
        static let writing = "写作"
        static let listening = "听力"
        static let tense = "时态"
        static let clause = "从句"
        
        static var all: [String] {
            [grammar, vocabulary, reading, writing, listening, tense, clause]
        }
    }
    
    /// 根据学科获取推荐知识点
    static func suggestions(for subject: Subject) -> [String] {
        switch subject {
        case .math: return Math.all
        case .physics: return Physics.all
        case .chemistry: return Chemistry.all
        case .english: return English.all
        default: return []
        }
    }
}

// MARK: - Helper

private extension Array where Element: Hashable {
    /// 去重并保持顺序
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
