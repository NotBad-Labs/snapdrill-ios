//
//  Tags.swift
//  NotBad
//
//  知识点标签值对象 - 不可变集合设计
//

import Foundation

/// 知识点标签集合
struct Tags: Equatable, Codable, Hashable {
    private var items: [String]
    
    /// 空标签
    static let empty = Tags([])
    
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
    
    /// 标签数组
    var array: [String] { items }
    
    /// 标签数量
    var count: Int { items.count }
    
    /// 是否为空
    var isEmpty: Bool { items.isEmpty }
    
    /// 是否非空
    var isNotEmpty: Bool { !items.isEmpty }
    
    /// 第一个标签
    var first: String? { items.first }
    
    /// 最后一个标签
    var last: String? { items.last }
    
    /// 转换为逗号分隔的字符串（用于存储）
    var rawValue: String {
        items.joined(separator: ", ")
    }
    
    // MARK: - Operations
    
    /// 添加单个标签
    func adding(_ tag: String) -> Tags {
        let trimmed = tag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !items.contains(trimmed) else { return self }
        return Tags(items + [trimmed])
    }
    
    /// 批量添加标签
    func adding(_ tags: [String]) -> Tags {
        var newItems = items
        for tag in tags {
            let trimmed = tag.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !newItems.contains(trimmed) {
                newItems.append(trimmed)
            }
        }
        return Tags(newItems)
    }
    
    /// 移除单个标签
    func removing(_ tag: String) -> Tags {
        Tags(items.filter { $0 != tag })
    }
    
    /// 批量移除标签
    func removing(_ tags: [String]) -> Tags {
        let tagsSet = Set(tags)
        return Tags(items.filter { !tagsSet.contains($0) })
    }
    
    /// 合并标签集合
    func merging(with other: Tags) -> Tags {
        Tags(items + other.items)
    }
    
    /// 取交集
    func intersection(with other: Tags) -> Tags {
        let otherSet = Set(other.items)
        return Tags(items.filter { otherSet.contains($0) })
    }
    
    /// 是否包含标签
    func contains(_ tag: String) -> Bool {
        items.contains(tag)
    }
    
    /// 是否包含任意一个标签
    func containsAny(of tags: [String]) -> Bool {
        let tagsSet = Set(tags)
        return items.contains { tagsSet.contains($0) }
    }
    
    /// 是否包含所有标签
    func containsAll(of tags: [String]) -> Bool {
        let itemsSet = Set(items)
        return tags.allSatisfy { itemsSet.contains($0) }
    }
    
    /// 搜索匹配（模糊搜索）
    func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowercasedQuery = query.lowercased()
        return items.contains { $0.lowercased().contains(lowercasedQuery) }
    }
    
    /// 过滤包含关键词的标签
    func filter(containing keyword: String) -> Tags {
        guard !keyword.isEmpty else { return self }
        let lowercasedKeyword = keyword.lowercased()
        return Tags(items.filter { $0.lowercased().contains(lowercasedKeyword) })
    }
    
    /// 排序后的标签
    func sorted() -> Tags {
        Tags(items.sorted())
    }
    
    /// 下标访问
    subscript(index: Int) -> String? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }
}

// MARK: - Sequence

extension Tags: Sequence {
    func makeIterator() -> IndexingIterator<[String]> {
        items.makeIterator()
    }
}

// MARK: - Collection

extension Tags: Collection {
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

extension Tags: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: String...) {
        self.init(elements)
    }
}

// MARK: - CustomStringConvertible

extension Tags: CustomStringConvertible {
    var description: String { rawValue }
}

// MARK: - 常用知识点标签预设

extension Tags {
    /// 数学常用标签
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
    
    /// 物理常用标签
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
    
    /// 化学常用标签
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
    
    /// 英语常用标签
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
    
    /// 根据学科获取推荐标签
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
