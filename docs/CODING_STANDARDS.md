# NotBad 编码规范

> Swift 6.2 / iOS 26 项目规范  
> 最后更新: 2025年11月30日

---

## 一、协议遵循顺序

所有值对象遵循固定的协议声明顺序：

```
Sendable → CaseIterable → Codable → Hashable → Identifiable
```

**记忆口诀**：`"Send Case Code Hash ID"`

```swift
// ✅ 正确
enum Difficulty: Int, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case easy = 0
    case medium = 1
    case hard = 2
    
    nonisolated var id: Int { rawValue }
}
```

---

## 二、并发安全

### 2.1 Sendable

所有值对象必须遵循 `Sendable`：

```swift
struct KnowledgePoints: Sendable {
    let items: [String]
    nonisolated var count: Int { items.count }
}
```

### 2.2 @MainActor

UI 相关类型使用 `@MainActor`：

```swift
@MainActor
@Observable
final class DashboardViewModel {
    var items: [ReviewItem] = []
}
```

### 2.3 async/await

异步操作优先使用 `async/await`：

```swift
// ✅ 正确
func fetchItems() async throws -> [ReviewItem] { ... }

// ❌ 避免回调
func fetchItems(completion: @escaping (Result) -> Void) { ... }
```

---

## 三、值对象设计

### 3.1 必需属性

```swift
extension YourValueObject {
    // 显示
    var displayName: String { }
    var shortLabel: String { }
    
    // 视觉
    var icon: String { }      // SF Symbol
    var color: Color { }
    
    // 标识
    var id: Int { rawValue }
}
```

### 3.2 使用 Int rawValue

```swift
// ✅ 高效
enum Difficulty: Int { case easy = 0 }

// ❌ 较慢
enum Difficulty: String { case easy = "easy" }
```

---

## 四、代码组织

### 4.1 扩展分组

```swift
// MARK: - Identifiable
extension YourType: Identifiable { }

// MARK: - Display Properties
extension YourType {
    var displayName: String { }
}

// MARK: - Comparable
extension YourType: Comparable { }
```

### 4.2 文件命名

| 类型 | 命名规范 |
|------|---------|
| 实体 | `ReviewItem.swift` |
| 实体扩展 | `ReviewItem+Actions.swift` |
| 值对象 | `Difficulty.swift` |
| ViewModel | `DashboardViewModel.swift` |
| View | `DashboardView.swift` |

---

## 五、SwiftUI 规范

### 5.1 View 结构

```swift
struct MyView: View {
    // 1. 环境变量
    @Environment(\.dismiss) private var dismiss
    
    // 2. 状态
    @State private var isLoading = false
    
    // 3. 绑定
    @Binding var selection: Item?
    
    // 4. 属性
    let items: [Item]
    
    // 5. body
    var body: some View { ... }
    
    // 6. 私有方法
    private func handleTap() { ... }
}
```

### 5.2 预览

```swift
#Preview {
    MyView(items: .preview)
}
```

---

## 六、SwiftData 规范

### 6.1 Model 定义

```swift
@Model
final class ReviewItem {
    // 存储原始值
    private var difficultyRaw: Int = 0
    
    // 值对象访问器
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
}
```

---

## 七、测试规范

### 7.1 命名

```swift
func test_方法名_场景_预期结果() {
    // Given / When / Then
}

// 示例
func test_calculate_withHighMastery_returnsLongerInterval() { }
```

### 7.2 结构

```swift
func testExample() {
    // Given (准备)
    let item = ReviewItem.mock()
    
    // When (执行)
    let result = item.calculateInterval()
    
    // Then (断言)
    XCTAssertEqual(result.days, 7)
}
```

---

## 八、文档规范

### 8.1 DocC 格式

```swift
/// 题目难度等级
///
/// - ``easy``: 简单题
/// - ``medium``: 中等题
/// - ``hard``: 困难题
enum Difficulty { }
```

### 8.2 参数说明

```swift
/// 计算复习间隔
/// - Parameters:
///   - reviewCount: 复习次数
///   - mastery: 掌握程度
/// - Returns: 复习间隔
func calculate(reviewCount: Int, mastery: MasteryLevel) -> ReviewInterval
```

---

## 九、命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类型 | UpperCamelCase | `ReviewItem` |
| 变量/函数 | lowerCamelCase | `fetchItems()` |
| 常量 | lowerCamelCase | `let maxRetryCount = 3` |
| 枚举成员 | lowerCamelCase | `.easy`, `.medium` |
| 协议 | 名词或 -able/-ible | `Sendable`, `Repository` |

---

## 十、禁止事项

| ❌ 禁止 | ✅ 替代方案 |
|--------|-----------|
| `force unwrap (!)` | `guard let` 或 `??` |
| `try!` | `do-catch` 或 `try?` |
| `implicitly unwrapped (!!)` | 可选值或默认值 |
| 硬编码字符串 | `LocalizedStringKey` |
| `print()` 生产环境 | `#if DEBUG` 包裹 |

---

## 速查表

```
协议顺序: Sendable → CaseIterable → Codable → Hashable → Identifiable
并发: @MainActor (UI) / Sendable (值类型) / actor (共享状态)
测试: test_方法_场景_结果 + Given/When/Then
命名: 类型=大驼峰, 变量=小驼峰, 文件=类型名.swift
```
