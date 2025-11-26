# 值对象最佳实践指南

> 基于 Difficulty.swift 的审查和改进经验

---

## 🎯 核心原则

### 1. 完整的协议支持
```swift
enum YourValueObject: Int, Sendable {
    // 案例定义
}

// 分别在扩展中声明协议
extension YourValueObject: Identifiable { }
extension YourValueObject: CaseIterable { }
extension YourValueObject: Codable { }
extension YourValueObject: Hashable { }
extension YourValueObject: Comparable { }
extension YourValueObject: CustomStringConvertible { }
```

**必需协议**：
- ✅ `Sendable` - Swift 并发安全
- ✅ `Identifiable` - SwiftUI 集成
- ✅ `CaseIterable` - 遍历所有案例
- ✅ `Codable` - 序列化支持
- ✅ `Hashable` - 集合类型支持

**推荐协议**：
- 💡 `Comparable` - 如果有明确的排序逻辑
- 💡 `CustomStringConvertible` - 优化调试体验

---

## 📚 文档标准

### 类型级别文档
```swift
/// [简短描述]
///
/// [详细说明，解释这个类型的作用和使用场景]
///
/// ## [章节标题]
/// - ``case1``: 说明
/// - ``case2``: 说明
///
/// ## 使用示例
/// ```swift
/// let example = YourType.someCase
/// print(example.property)
/// ```
enum YourValueObject {
```

### 案例级别文档
```swift
/// [完整描述案例含义]
case someCase = 0
```

### 属性级别文档
```swift
/// [属性用途]
///
/// [详细说明]
/// - Returns: [返回值说明]
var computedProperty: Type {
```

---

## 🗂 代码组织

### 标准扩展结构
```swift
// MARK: - Identifiable
extension YourValueObject: Identifiable {
    var id: Int { rawValue }
}

// MARK: - Display Properties
extension YourValueObject {
    var displayName: String { }
    var shortLabel: String { }
    var detailText: String { }
}

// MARK: - Visual Properties
extension YourValueObject {
    var icon: String { }
    var color: Color { }
}

// MARK: - Metrics (业务逻辑)
extension YourValueObject {
    var coefficient: Double { }
    // 其他计算属性
}

// MARK: - Comparable
extension YourValueObject: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

**分组原则**：
1. **协议一致性** - 每个协议单独一个扩展
2. **显示属性** - UI 文本相关
3. **视觉属性** - 图标、颜色等
4. **业务逻辑** - 度量、计算等
5. **比较逻辑** - 排序相关

---

## 🎨 SwiftUI 集成

### 必需属性
```swift
// MARK: - Display Properties
extension YourValueObject {
    /// 显示名称 - 完整文本
    var displayName: String { }
    
    /// 简短标签 - 空间受限场景
    var shortLabel: String { }
    
    /// 详细描述 - 帮助文本
    var detailText: String { }
}

// MARK: - Visual Properties
extension YourValueObject {
    /// SF Symbol 图标名称
    var icon: String { }
    
    /// 主题颜色
    var color: Color { }
}
```

### SwiftUI 视图示例
```swift
// Picker 集成
Picker("标签", selection: $value) {
    ForEach(YourValueObject.allCases) { item in
        Label(item.displayName, systemImage: item.icon)
            .tag(item)
    }
}

// List 集成
List(YourValueObject.allCases) { item in
    HStack {
        Image(systemName: item.icon)
            .foregroundStyle(item.color)
        VStack(alignment: .leading) {
            Text(item.displayName)
            Text(item.detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// 自定义徽章
struct Badge: View {
    let value: YourValueObject
    
    var body: some View {
        Label(value.shortLabel, systemImage: value.icon)
            .padding(8)
            .background(value.color.opacity(0.2))
            .foregroundStyle(value.color)
            .clipShape(Capsule())
    }
}
```

---

## ⚡️ 性能优化

### 1. 使用 Int rawValue
```swift
enum YourValueObject: Int { // ✅ 高效
    case item1 = 0
    case item2 = 1
}
```
**避免**：
```swift
enum YourValueObject: String { // ❌ 较慢
    case item1 = "item1"
}
```

### 2. 计算属性保持轻量
```swift
// ✅ 好 - 简单计算
var coefficient: Double {
    Double(rawValue) / Double(Self.allCases.count - 1)
}

// ❌ 避免 - 复杂逻辑
var complexCalculation: Double {
    // 大量计算...
    // 考虑使用方法或缓存
}
```

### 3. 使用 switch 而非 if-else
```swift
// ✅ 编译器优化更好
var displayName: String {
    switch self {
    case .item1: return "名称1"
    case .item2: return "名称2"
    }
}
```

---

## 🧪 测试模板

```swift
import Testing
@testable import YourModule

@Suite("YourValueObject 值对象测试")
struct YourValueObjectTests {
    
    // MARK: - 基础测试
    
    @Test("所有案例数量")
    func caseCount() {
        #expect(YourValueObject.allCases.count == expectedCount)
    }
    
    @Test("所有案例都有显示名称")
    func displayNames() {
        for item in YourValueObject.allCases {
            #expect(!item.displayName.isEmpty)
            #expect(!item.shortLabel.isEmpty)
            #expect(!item.detailText.isEmpty)
        }
    }
    
    @Test("所有案例都有图标")
    func icons() {
        for item in YourValueObject.allCases {
            #expect(!item.icon.isEmpty)
        }
    }
    
    // MARK: - Identifiable 测试
    
    @Test("ID 唯一性")
    func uniqueIDs() {
        let ids = Set(YourValueObject.allCases.map(\.id))
        #expect(ids.count == YourValueObject.allCases.count)
    }
    
    // MARK: - Comparable 测试
    
    @Test("排序正确性")
    func sorting() {
        let sorted = YourValueObject.allCases.sorted()
        #expect(sorted == YourValueObject.allCases)
    }
    
    // MARK: - Codable 测试
    
    @Test("编解码正确性")
    func codableRoundTrip() throws {
        for item in YourValueObject.allCases {
            let data = try JSONEncoder().encode(item)
            let decoded = try JSONDecoder().decode(YourValueObject.self, from: data)
            #expect(decoded == item)
        }
    }
    
    // MARK: - 业务逻辑测试
    
    @Test("度量值范围")
    func metrics() {
        for item in YourValueObject.allCases {
            #expect(item.coefficient >= 0.0)
            #expect(item.coefficient <= 1.0)
        }
    }
}
```

---

## 🔄 迁移 Checklist

将现有值对象升级为最佳实践：

### 第1步：添加协议
- [ ] `Sendable` 协议
- [ ] `Identifiable` 协议（添加 `id` 属性）
- [ ] `Hashable` 协议
- [ ] `CustomStringConvertible` 协议（添加 `description` 属性）

### 第2步：重组代码
- [ ] 将协议一致性移到单独的扩展
- [ ] 添加 MARK 注释分组
- [ ] 按功能组织计算属性

### 第3步：完善文档
- [ ] 类型级别文档（含示例）
- [ ] 所有案例的文档注释
- [ ] 所有公共属性的文档注释

### 第4步：统一命名
- [ ] `displayName` - 完整名称
- [ ] `shortLabel` - 简短标签
- [ ] `detailText` - 详细说明
- [ ] `icon` - SF Symbol 名称
- [ ] `color` - SwiftUI Color

### 第5步：测试
- [ ] 编写单元测试
- [ ] 验证向后兼容性
- [ ] 性能测试（如需要）

---

## 📋 审查 Checklist

在代码审查时检查：

### 结构
- [ ] 使用 `Int` rawValue（如果合适）
- [ ] 案例从 0 开始连续编号
- [ ] 协议在单独的扩展中
- [ ] 使用 MARK 注释组织

### 文档
- [ ] 类型有完整的文档注释
- [ ] 所有案例有说明
- [ ] 所有公共 API 有文档
- [ ] 包含使用示例

### 协议
- [ ] `Sendable` 用于并发安全
- [ ] `Identifiable` 用于 SwiftUI
- [ ] `CaseIterable` 用于遍历
- [ ] `Codable` 用于序列化
- [ ] `Hashable` 用于集合

### SwiftUI 集成
- [ ] 提供 `displayName`
- [ ] 提供 `icon` (SF Symbol)
- [ ] 提供 `color`
- [ ] 可用于 Picker/List

### 测试
- [ ] 有对应的单元测试
- [ ] 测试覆盖所有案例
- [ ] 测试协议一致性

---

## 🚫 反模式

### 避免
```swift
// ❌ 魔法数字
if difficulty == 3 { }

// ✅ 使用类型
if difficulty == .hard { }

// ❌ 字符串比较
if difficulty.displayName == "困难" { }

// ✅ 使用枚举
if difficulty == .hard { }

// ❌ 可选解包
let diff = Difficulty(rawValue: value)!

// ✅ 提供默认值
let diff = Difficulty(rawValue: value) ?? .medium

// ❌ 在视图中硬编码颜色
Text("困难").foregroundColor(.red)

// ✅ 使用值对象属性
Text(difficulty.displayName)
    .foregroundStyle(difficulty.color)
```

---

## 📚 参考资源

1. **Swift 官方指南**
   - [API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
   - [Swift DocC](https://www.swift.org/documentation/docc/)

2. **Apple 文档**
   - [SwiftUI Protocols](https://developer.apple.com/documentation/swiftui)
   - [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

3. **最佳实践**
   - [WWDC Sessions on Swift](https://developer.apple.com/videos/frameworks/swift)
   - [Point-Free](https://www.pointfree.co/) - 函数式编程

---

## 🎓 总结

遵循这些最佳实践可以确保：
- ✅ 代码质量一致
- ✅ 易于维护和扩展
- ✅ 完美的 SwiftUI 集成
- ✅ 优秀的开发体验
- ✅ 专业的 API 设计

**记住**：值对象是领域驱动设计的核心，投入时间完善它们会在整个项目中获得回报。

---

**创建日期**: 2025年11月25日  
**基于**: Difficulty.swift 审查经验  
**状态**: ✅ 已验证并实施
