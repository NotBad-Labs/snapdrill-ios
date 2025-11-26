//
//  KnowledgePoints.swift
//  NotBad
//
//  知识点值对象 - 不可变集合设计
//

import Foundation

// MARK: - KnowledgePoints

/// 知识点集合
///
/// 表示一道错题涉及的知识点列表，如 ["函数", "导数", "极限"]。
/// 遵循值对象原则：不可变，所有操作返回新实例。
///
/// ## 核心特性
/// - **不可变设计**：所有修改操作返回新实例
/// - **自动去重**：创建时自动去除重复项
/// - **空值安全**：自动过滤空字符串和空白
///
/// ## 使用示例
/// ```swift
/// // 创建知识点集合
/// let points: KnowledgePoints = ["函数", "导数", "极限"]
///
/// // 添加知识点（返回新实例）
/// let newPoints = points.adding("积分")
///
/// // 从字符串创建
/// let fromString = KnowledgePoints(from: "函数, 导数, 极限")
///
/// // 搜索匹配
/// let matches = points.matches("函")  // true
/// ```
struct KnowledgePoints: Sendable, Equatable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// 内部存储的知识点数组
    let items: [String]
    
    /// 空知识点集合
    static let empty = KnowledgePoints([])
    
    // MARK: - Initialization
    
    /// 从字符串数组创建
    /// - Parameter items: 知识点数组（自动去重、去空、去首尾空格）
    init(_ items: [String] = []) {
        self.items = items
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .uniqued()
    }
    
    /// 从逗号分隔的字符串创建
    /// - Parameter string: 逗号分隔的知识点字符串
    init(from string: String) {
        let components = string.components(separatedBy: ",")
        self.init(components)
    }
}

// MARK: - KnowledgePoints Computed Properties

extension KnowledgePoints {
    /// 知识点数组
    nonisolated var array: [String] { items }
    
    /// 知识点数量
    nonisolated var count: Int { items.count }
    
    /// 是否为空
    nonisolated var isEmpty: Bool { items.isEmpty }
    
    /// 是否非空
    nonisolated var isNotEmpty: Bool { !items.isEmpty }
    
    /// 第一个知识点
    nonisolated var first: String? { items.first }
    
    /// 最后一个知识点
    nonisolated var last: String? { items.last }
    
    /// 转换为逗号分隔的字符串（用于存储）
    nonisolated var rawValue: String {
        items.joined(separator: ", ")
    }
}

// MARK: - KnowledgePoints Operations

extension KnowledgePoints {
    /// 添加单个知识点
    /// - Parameter point: 要添加的知识点
    /// - Returns: 包含新知识点的新实例
    nonisolated func adding(_ point: String) -> KnowledgePoints {
        let trimmed = point.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !items.contains(trimmed) else { return self }
        return KnowledgePoints(items + [trimmed])
    }
    
    /// 批量添加知识点
    /// - Parameter points: 要添加的知识点数组
    /// - Returns: 包含新知识点的新实例
    nonisolated func adding(_ points: [String]) -> KnowledgePoints {
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
    /// - Parameter point: 要移除的知识点
    /// - Returns: 移除后的新实例
    nonisolated func removing(_ point: String) -> KnowledgePoints {
        KnowledgePoints(items.filter { $0 != point })
    }
    
    /// 批量移除知识点
    /// - Parameter points: 要移除的知识点数组
    /// - Returns: 移除后的新实例
    nonisolated func removing(_ points: [String]) -> KnowledgePoints {
        let pointsSet = Set(points)
        return KnowledgePoints(items.filter { !pointsSet.contains($0) })
    }
    
    /// 合并知识点集合
    /// - Parameter other: 要合并的知识点集合
    /// - Returns: 合并后的新实例
    nonisolated func merging(with other: KnowledgePoints) -> KnowledgePoints {
        KnowledgePoints(items + other.items)
    }
    
    /// 取交集
    /// - Parameter other: 另一个知识点集合
    /// - Returns: 交集后的新实例
    nonisolated func intersection(with other: KnowledgePoints) -> KnowledgePoints {
        let otherSet = Set(other.items)
        return KnowledgePoints(items.filter { otherSet.contains($0) })
    }
    
    /// 排序后的知识点
    /// - Returns: 按字母顺序排序的新实例
    nonisolated func sorted() -> KnowledgePoints {
        KnowledgePoints(items.sorted())
    }
}

// MARK: - KnowledgePoints Query Methods

extension KnowledgePoints {
    /// 是否包含知识点
    /// - Parameter point: 要查询的知识点
    /// - Returns: 是否包含
    nonisolated func contains(_ point: String) -> Bool {
        items.contains(point)
    }
    
    /// 是否包含任意一个知识点
    /// - Parameter points: 要查询的知识点数组
    /// - Returns: 是否包含任意一个
    nonisolated func containsAny(of points: [String]) -> Bool {
        let pointsSet = Set(points)
        return items.contains { pointsSet.contains($0) }
    }
    
    /// 是否包含所有知识点
    /// - Parameter points: 要查询的知识点数组
    /// - Returns: 是否全部包含
    nonisolated func containsAll(of points: [String]) -> Bool {
        let itemsSet = Set(items)
        return points.allSatisfy { itemsSet.contains($0) }
    }
    
    /// 搜索匹配（模糊搜索）
    /// - Parameter query: 搜索关键词
    /// - Returns: 是否有匹配
    nonisolated func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowercasedQuery = query.lowercased()
        return items.contains { $0.lowercased().contains(lowercasedQuery) }
    }
    
    /// 过滤包含关键词的知识点
    /// - Parameter keyword: 过滤关键词
    /// - Returns: 过滤后的新实例
    nonisolated func filter(containing keyword: String) -> KnowledgePoints {
        guard !keyword.isEmpty else { return self }
        let lowercasedKeyword = keyword.lowercased()
        return KnowledgePoints(items.filter { $0.lowercased().contains(lowercasedKeyword) })
    }
    
    /// 下标访问（安全版本）
    /// - Parameter index: 索引
    /// - Returns: 对应的知识点，越界返回 nil
    nonisolated subscript(safe index: Int) -> String? {
        guard index >= 0 && index < items.count else { return nil }
        return items[index]
    }
}

// MARK: - KnowledgePoints Sequence

extension KnowledgePoints: Sequence {
    nonisolated func makeIterator() -> IndexingIterator<[String]> {
        items.makeIterator()
    }
}

// MARK: - KnowledgePoints Collection

extension KnowledgePoints: Collection {
    nonisolated var startIndex: Int { items.startIndex }
    nonisolated var endIndex: Int { items.endIndex }
    
    nonisolated func index(after i: Int) -> Int {
        items.index(after: i)
    }
    
    nonisolated subscript(position: Int) -> String {
        items[position]
    }
}

// MARK: - KnowledgePoints ExpressibleByArrayLiteral

extension KnowledgePoints: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: String...) {
        self.init(elements)
    }
}

// MARK: - KnowledgePoints CustomStringConvertible

extension KnowledgePoints: CustomStringConvertible {
    nonisolated var description: String { rawValue }
}

// MARK: - KnowledgePoints Subject Suggestions

extension KnowledgePoints {
    
    /// 数学常用知识点
    enum Math {
        static let sets = "集合"
        static let logic = "逻辑"
        static let algebra = "代数"
        static let geometry = "几何"
        static let function = "函数"
        static let equation = "方程"
        static let inequality = "不等式"
        static let sequence = "数列"
        static let probability = "概率"
        static let statistics = "统计"
        static let permutation = "排列组合"
        static let complex = "复数"
        static let derivative = "导数"
        static let integral = "积分"
        static let vector = "向量"
        static let trigonometry = "三角函数"
        static let solidGeometry = "立体几何"
        static let analyticGeometry = "解析几何"
        
        static var all: [String] {
            [sets, logic, algebra, geometry, function, equation, inequality,
             sequence, probability, statistics, permutation, complex,
             derivative, integral, vector, trigonometry, solidGeometry, analyticGeometry]
        }
    }
    
    /// 物理常用知识点
    enum Physics {
        static let kinematics = "运动学"
        static let dynamics = "动力学"
        static let statics = "静力学"
        static let energy = "能量"
        static let momentum = "动量"
        static let circularMotion = "圆周运动"
        static let gravitation = "万有引力"
        static let electricity = "电学"
        static let magnetism = "磁学"
        static let electromagnetism = "电磁感应"
        static let optics = "光学"
        static let thermodynamics = "热学"
        static let waves = "波动"
        static let modern = "近代物理"
        
        static var all: [String] {
            [kinematics, dynamics, statics, energy, momentum, circularMotion,
             gravitation, electricity, magnetism, electromagnetism,
             optics, thermodynamics, waves, modern]
        }
    }
    
    /// 化学常用知识点
    enum Chemistry {
        static let atomStructure = "原子结构"
        static let periodicTable = "元素周期表"
        static let chemicalBond = "化学键"
        static let reaction = "化学反应"
        static let equilibrium = "化学平衡"
        static let ionicReaction = "离子反应"
        static let redox = "氧化还原"
        static let electrochemistry = "电化学"
        static let organic = "有机化学"
        static let inorganic = "无机化学"
        static let element = "元素化学"
        
        static var all: [String] {
            [atomStructure, periodicTable, chemicalBond, reaction, equilibrium,
             ionicReaction, redox, electrochemistry, organic, inorganic, element]
        }
    }
    
    /// 生物常用知识点
    enum Biology {
        static let cell = "细胞"
        static let metabolism = "代谢"
        static let photosynthesis = "光合作用"
        static let respiration = "呼吸作用"
        static let genetics = "遗传"
        static let dna = "DNA与RNA"
        static let evolution = "进化"
        static let ecology = "生态"
        static let regulation = "生命调节"
        static let reproduction = "生殖发育"
        
        static var all: [String] {
            [cell, metabolism, photosynthesis, respiration, genetics,
             dna, evolution, ecology, regulation, reproduction]
        }
    }
    
    /// 语文常用知识点
    enum Chinese {
        static let readingComprehension = "阅读理解"
        static let classicalChinese = "文言文"
        static let poetry = "诗词鉴赏"
        static let modernText = "现代文阅读"
        static let writing = "作文"
        static let languageApplication = "语言文字运用"
        static let literaryKnowledge = "文学常识"
        static let rhetoric = "修辞手法"
        
        static var all: [String] {
            [readingComprehension, classicalChinese, poetry, modernText,
             writing, languageApplication, literaryKnowledge, rhetoric]
        }
    }
    
    /// 英语常用知识点
    enum English {
        static let grammar = "语法"
        static let vocabulary = "词汇"
        static let reading = "阅读理解"
        static let writing = "写作"
        static let listening = "听力"
        static let tense = "时态"
        static let clause = "从句"
        static let passiveVoice = "被动语态"
        static let nonFinite = "非谓语动词"
        
        static var all: [String] {
            [grammar, vocabulary, reading, writing, listening,
             tense, clause, passiveVoice, nonFinite]
        }
    }
    
    /// 历史常用知识点
    enum History {
        static let ancientChina = "中国古代史"
        static let modernChina = "中国近现代史"
        static let worldAncient = "世界古代史"
        static let worldModern = "世界近现代史"
        static let politics = "政治制度"
        static let economy = "经济发展"
        static let culture = "思想文化"
        static let reform = "改革变法"
        
        static var all: [String] {
            [ancientChina, modernChina, worldAncient, worldModern,
             politics, economy, culture, reform]
        }
    }
    
    /// 地理常用知识点
    enum Geography {
        static let naturalGeography = "自然地理"
        static let humanGeography = "人文地理"
        static let regionalGeography = "区域地理"
        static let atmosphere = "大气"
        static let hydrosphere = "水文"
        static let lithosphere = "地质地貌"
        static let population = "人口"
        static let urbanization = "城市化"
        static let agriculture = "农业"
        static let industry = "工业"
        
        static var all: [String] {
            [naturalGeography, humanGeography, regionalGeography,
             atmosphere, hydrosphere, lithosphere, population,
             urbanization, agriculture, industry]
        }
    }
    
    /// 政治常用知识点
    enum Politics {
        static let economicLife = "经济生活"
        static let politicalLife = "政治生活"
        static let culturalLife = "文化生活"
        static let philosophy = "哲学"
        static let materialism = "唯物论"
        static let dialectics = "辩证法"
        static let epistemology = "认识论"
        static let historicalMaterialism = "历史唯物主义"
        
        static var all: [String] {
            [economicLife, politicalLife, culturalLife, philosophy,
             materialism, dialectics, epistemology, historicalMaterialism]
        }
    }
    
    /// 根据学科获取推荐知识点
    /// - Parameter subject: 学科
    /// - Returns: 该学科的推荐知识点列表
    static func suggestions(for subject: Subject) -> [String] {
        switch subject {
        case .math: Math.all
        case .physics: Physics.all
        case .chemistry: Chemistry.all
        case .biology: Biology.all
        case .chinese: Chinese.all
        case .english: English.all
        case .history: History.all
        case .geography: Geography.all
        case .politics, .ethics: Politics.all
        default: []
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
