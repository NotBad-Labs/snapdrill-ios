# ReviewKit

NotBad 的**领域层核心库**，包含数据模型、业务逻辑和持久化。

## 职责

ReviewKit 是 NotBad 的 **Domain Layer（领域层）**，包含：

| 模块 | 文件 | 说明 |
|------|------|------|
| 实体 | `Models/ReviewItemModel.swift` | SwiftData @Model，充血模型 |
| 值对象 | `ValueObjects/ValueObjects.swift` | Subject, Grade, Difficulty 等 |
| 持久化 | `Data/PersistenceController.swift` | App Groups 共享数据库 |
| 算法 | `ReviewScheduler.swift` | 间隔重复复习调度 |

## 特性

- ✅ **SwiftData** - 使用 @Model 宏，支持 iOS 17+ / macOS 14+
- ✅ **App Groups** - 主 App 和 Widget 共享数据库
- ✅ **充血模型** - Model 自带业务方法 (`recordReview()` 等)
- ✅ **Sendable** - Swift 6 并发安全
- ✅ **跨平台** - iOS, macOS, Widget, CLI 均可使用

## 为什么 Model 在 Package 里？

**解决 SwiftData 命名空间陷阱**：

SwiftData 使用完全限定类名（`模块名.类名`）作为存储标识符。

```
❌ Model 在主 App:
   - App 存储: NotBad.ReviewItemModel
   - Widget 复制一份: NotBadWidget.ReviewItemModel
   - 结果: Widget 读不到 App 的数据！

✅ Model 在 Package:
   - App 导入 ReviewKit: ReviewKit.ReviewItemModel
   - Widget 导入 ReviewKit: ReviewKit.ReviewItemModel
   - 结果: 完美共享！
```

## 使用方法

```swift
import ReviewKit

// 访问持久化
let container = PersistenceController.shared.container

// 创建新错题
let item = ReviewItemModel()
item.title = "二次函数求根"
item.subject = .math
item.difficulty = .medium

// 记录复习
item.recordReview(performance: 2)  // 大部分掌握
// nextReviewDate 自动更新

// 使用调度器
let scheduler = ReviewScheduler()
let days = scheduler.calculateIntervalDays(currentMastery: 2, reviewCount: 3)
```

## 集成到 NotBad 主工程

### 步骤 1: 添加 Package

1. 打开 `NotBad.xcodeproj`
2. File → Add Package Dependencies
3. 点击 "Add Local..."
4. 选择 `Packages/ReviewKit` 目录

### 步骤 2: 添加到 Target

1. 选择 NotBad target → General
2. Frameworks, Libraries... → 添加 `ReviewKit`
3. 同样添加到 NotBadWidget target

### 步骤 3: 删除旧文件

以下文件已迁移到 ReviewKit，可删除：
- `NotBad/Models/ReviewItemModel.swift`
- `NotBad/Models/ValueObjects.swift`
- `NotBad/Data/PersistenceController.swift`

### 步骤 4: 更新 import

```swift
import ReviewKit  // 添加这行
```

## CLI 验证

```bash
cd Packages/ReviewKit
swift run ReviewKitCLI
```

✅ CLI 可以运行证明：即使包含 SwiftData，核心逻辑仍然可以脱离 UI 运行。

## 测试

```bash
cd Packages/ReviewKit
swift test
```

## 架构意义

ReviewKit 代表了"物理隔离"架构理念：

| 对比 | 文件夹分层 | Package 隔离 |
|------|-----------|-------------|
| 约束 | 靠自律 | 靠编译器 |
| 违反代价 | 代码审查被说一句 | **编译不过** |
| 复用性 | 需要手动复制 | `import ReviewKit` |
| Widget 共享 | 命名空间冲突 | **完美共享** |
