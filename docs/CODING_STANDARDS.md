# NotBad 编码规范与工程手册

> 版本: 2.0  
> 最后更新: 2025年12月2日  
> 适用范围: Swift 6.2+ / iOS 26.0+ / SwiftData

---

## 目录

1. [核心原则与风格](#一核心原则与风格)
2. [Swift 6 并发最佳实践](#二swift-6-并发最佳实践)
3. [领域模型与值对象](#三领域模型与值对象)
4. [错误处理规范](#四错误处理规范)
5. [日志规范](#五日志规范)
6. [测试规范](#六测试规范)
7. [Apple 平台规范](#七apple-平台规范)
8. [禁止事项](#八禁止事项-donts)

---

## 一、核心原则与风格

### 1.1 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类型 | UpperCamelCase | `ReviewItem`, `DashboardViewModel` |
| 变量/函数 | lowerCamelCase | `fetchItems()`, `isLoading` |
| 常量 | lowerCamelCase | `let maxRetryCount = 3` |
| 枚举成员 | lowerCamelCase | `.easy`, `.medium` |
| 协议 | 名词或 -able/-ible | `Sendable`, `RepositoryProtocol` |
| 文件名 | 与类型一致 | `ReviewItem.swift` |

### 1.2 文件组织

**文件命名对应关系：**

| 类型 | 命名规范 |
|------|---------|
| 实体 | `ReviewItem.swift` |
| 实体扩展 | `ReviewItem+Actions.swift` |
| 值对象 | `Difficulty.swift` |
| ViewModel | `DashboardViewModel.swift` |
| View | `DashboardView.swift` |

**代码分段 (Mark)：**

```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Protocol Implementation
```

### 1.3 SwiftUI View 结构

```swift
struct MyView: View {
    // 1. 环境变量
    @Environment(\.dismiss) private var dismiss
    
    // 2. 状态 (@State, @Binding)
    @State private var isLoading = false
    @Binding var selection: Item?
    
    // 3. 依赖/属性
    let items: [Item]
    
    // 4. Body
    var body: some View { ... }
    
    // 5. Subviews / Methods
    private func handleTap() { ... }
}

#Preview {
    MyView(items: .preview)
}
```

### 1.4 依赖注入

优先使用**构造器注入**：

```swift
@MainActor
@Observable
final class LibraryViewModel {
    private let repository: ReviewItemRepositoryProtocol
    
    // ✅ 构造器注入
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
}
```

### 1.5 状态管理

| 状态类型 | 作用域 | 管理方式 |
|---------|-------|---------|
| **UI 状态** | 单个 View | `@State` |
| **共享 UI 状态** | 父子 View | `@Binding` |
| **业务状态** | Feature 模块 | ViewModel (`@Observable`) |
| **全局状态** | 整个 App | Environment / Singleton |

---

## 二、Swift 6 并发最佳实践

### 2.1 核心原则

| 原则 | 说明 |
|------|------|
| **默认并发安全** | 启用严格并发检查 |
| **Sendable 优先** | 值类型优先，确保跨隔离域安全传递 |
| **MainActor UI** | 所有 UI 相关代码标记 `@MainActor` |
| **async/await** | 优先使用结构化并发，避免回调 |

### 2.2 Sendable 协议

所有跨并发域传递的类型必须遵循 `Sendable`。

```swift
// ✅ 值类型自动 Sendable
struct Point: Sendable {
    let x: Int
    let y: Int
}

// ✅ 枚举自动 Sendable
enum Difficulty: Int, Sendable {
    case easy, hard
}

// ❌ 引用类型需特殊处理（通常使用 actor 或 @MainActor）
class Counter { var count = 0 }
```

### 2.3 @MainActor 使用

**必须使用 @MainActor 的场景：**
- ViewModel (`@Observable` class)
- UI 相关工具类
- View (SwiftUI 自动处理，无需显式标记)

```swift
@MainActor
@Observable
final class DashboardViewModel {
    var items: [ReviewItem] = []
    
    func loadItems() async {
        // 自动在主线程执行
        items = await repository.fetchAll()
    }
}
```

### 2.4 async/await 与 Task

**基本使用：**

```swift
// ✅ 定义
func fetchItems() async throws -> [ReviewItem] { ... }

// ✅ 调用
func loadData() async {
    do {
        let items = try await fetchItems()
        self.items = items
    } catch {
        Logger.error("Fetch failed", error: error)
    }
}
```

**后台任务 (Task.detached)：**

```swift
func compressInBackground(_ data: Data) async -> Data? {
    await Task.detached(priority: .utility) {
        // 脱离 MainActor，在后台线程执行
        UIImage(data: data)?.jpegData(compressionQuality: 0.7)
    }.value
}
```

### 2.5 @Observable 宏

Swift 6 推荐使用 `@Observable` 替代 `ObservableObject`。

```swift
// ✅ 新方式
@MainActor
@Observable
final class DashboardViewModel {
    var items: [ReviewItem] = [] // 自动追踪
}

// View 中使用
struct DashboardView: View {
    @State private var viewModel = DashboardViewModel() // 不需要 @StateObject
}
```

---

## 三、领域模型与值对象

### 3.1 值对象定义

**值对象 (Value Object)** 是 DDD 核心概念：无标识、不可变、可替换。

**项目清单 (13个)：**
- `Subject`, `Grade`, `Difficulty`, `MasteryLevel` 等枚举
- `KnowledgePoints`, `ReviewInterval` 等结构体

### 3.2 协议遵循顺序

**强制顺序**：`Sendable → CaseIterable → Codable → Hashable → Identifiable`

**记忆口诀**：`"Send Case Code Hash ID"`

```swift
enum Difficulty: Int, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case easy = 0
    case hard = 1
    
    nonisolated var id: Int { rawValue }
}
```

### 3.3 必需属性清单

每个值对象都应提供：

| 属性 | 类型 | 用途 |
|------|------|------|
| `displayName` | `String` | UI 显示 (本地化) |
| `shortLabel` | `String` | 简短标签 |
| `icon` | `String` | SF Symbol |
| `color` | `Color` | 主题色 |
| `id` | Hashable | 唯一标识 |

### 3.4 SwiftData 集成

SwiftData 不直接支持自定义值对象，需使用 `rawValue` 转换模式：

```swift
@Model
final class ReviewItem {
    // 存储层 (Private/Raw)
    private var difficultyRaw: Int = 2
    
    // 领域层 (Public/Value Object)
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
}
```

---

## 四、错误处理规范

### 4.1 统一错误类型

所有业务错误使用 `NotBadError` 枚举。

```swift
enum NotBadError: LocalizedError, Sendable {
    case saveFailed(reason: String)
    case notFound(id: UUID)
    case validationFailed(field: String, reason: String)
    // ...
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let reason): return "保存失败: \(reason)"
        // ...
        }
    }
}
```

### 4.2 错误传播

- **Repository**: 抛出 (`throws`) 错误。
- **ViewModel**: 捕获 (`do-catch`) 错误，转换为 UI 状态 (Toast)。

```swift
// ViewModel
func save() {
    do {
        try repository.save(item)
        toast = .success("保存成功")
    } catch let error as NotBadError {
        toast = .error(error.localizedDescription)
        Logger.error("Save failed", error: error)
    } catch {
        toast = .error("未知错误")
        Logger.error("Unexpected", error: error)
    }
}
```

### 4.3 用户提示 (Toast)

使用轻量级 Toast，不打断用户。

- `.success`: 操作成功
- `.error`: 操作失败
- `.warning`: 警告
- `.info`: 提示信息

---

## 五、日志规范

### 5.1 Logger 工具

使用 `Logger` 枚举统一输出，支持 4 级日志。

| 级别 | 方法 | 生产环境 | 用途 |
|------|------|---------|------|
| **Debug** | `Logger.debug()` | ❌ 禁用 | 调试、变量 |
| **Info** | `Logger.info()` | ❌ 禁用 | 业务流程 |
| **Warning** | `Logger.warning()` | ✅ 保留 | 潜在问题 |
| **Error** | `Logger.error()` | ✅ 保留 | 异常错误 |

### 5.2 隐私保护

**绝对禁止**记录：
- 用户内容（错题文本、图片数据）
- 个人身份信息

**正确做法**：
- 记录 ID (`item.id`)
- 记录元数据 (`imageSize`, `count`)
- 脱敏处理 (`Logger.mask(uuid)`)

```swift
Logger.error("Save failed", error: error, context: [
    "itemId": item.id.uuidString,
    "imageSize": "\(data.count)"
])
```

---

## 六、测试规范

### 6.1 命名规范

`test_方法名_场景_预期结果`

```swift
func test_calculateInterval_withHighMastery_returnsLongerDuration() { ... }
```

### 6.2 测试结构 (Given-When-Then)

```swift
func testExample() {
    // Given
    let item = ReviewItem.mock()
    
    // When
    let result = item.calculateInterval()
    
    // Then
    XCTAssertEqual(result.days, 7)
}
```

### 6.3 值对象测试清单

- [ ] `displayName` / `icon` / `color` 有效性
- [ ] `Codable` 编解码一致性
- [ ] `Comparable` 排序正确性
- [ ] `rawValue` 双向转换

---

## 七、Apple 平台规范

### 7.1 Human Interface Guidelines 合规

遵循 Apple HIG 设计原则：

| 原则 | 实现 |
|------|------|
| **清晰 (Clarity)** | 文字易读、图标清晰、功能明确 |
| **遵从 (Deference)** | 内容优先，UI 不喧宾夺主 |
| **深度 (Depth)** | 层级清晰，过渡流畅 |

### 7.2 无障碍 (Accessibility)

**强制要求**：所有交互元素必须支持 VoiceOver。

```swift
// ✅ 正确：提供完整无障碍支持
Button(action: save) {
    Label("保存", systemImage: "checkmark")
}
.accessibilityLabel("保存错题")
.accessibilityHint("双击保存当前录入的错题到题库")

// ✅ 图片必须提供描述
Image(uiImage: itemImage)
    .accessibilityLabel("错题图片")
    .accessibilityAddTraits(.isImage)
```

**动态字体 (Dynamic Type)**：

```swift
// ✅ 使用系统语义字体
Text(item.title)
    .font(.headline)  // 自动适配 Dynamic Type

// ❌ 禁止固定字号
Text(item.title)
    .font(.system(size: 17))  // 不会响应辅助功能设置
```

**减少动画 (Reduce Motion)**：

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    content
        .animation(reduceMotion ? nil : .spring(), value: isExpanded)
}
```

### 7.3 SF Symbols 使用

所有图标优先使用 SF Symbols，确保系统一致性：

```swift
// ✅ 使用 SF Symbols
Image(systemName: "checkmark.circle.fill")
Label("完成", systemImage: "checkmark")

// ✅ 符号变体
Image(systemName: "star")
    .symbolVariant(.fill)
    .symbolRenderingMode(.hierarchical)
```

### 7.4 系统颜色

优先使用语义化系统颜色，自动适配深色模式：

```swift
// ✅ 语义化颜色
Color.primary      // 主要文字
Color.secondary    // 次要文字
Color.accentColor  // 强调色

// ✅ 背景色
Color(.systemBackground)
Color(.secondarySystemBackground)

// ❌ 避免硬编码颜色
Color.black  // 深色模式下不适配
```

---

## 八、禁止事项 (Don'ts)

| ❌ 禁止 | ✅ 替代方案 |
|--------|-----------|
| `try!` / `force unwrap (!)` | `do-catch`, `guard let`, `??` |
| `print()` | `Logger.xxx()` |
| 回调闭包 (Completion Handler) | `async/await` |
| 非 Sendable 类型跨 Task 传递 | 使用 Sendable 类型 |
| 在 View 中直接处理业务逻辑 | 调用 ViewModel 方法 |
| 硬编码字符串 | `LocalizedStringKey` / `String(localized:)` |
| 固定字号 `.system(size:)` | 语义字体 `.headline` / `.body` |
| 硬编码颜色 `Color.black` | 语义颜色 `Color.primary` |
| 缺少 `accessibilityLabel` | 所有交互元素必须标注 |

