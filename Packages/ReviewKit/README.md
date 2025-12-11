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

- ## 特性

- ✅ **Swift 6.2 / Strict Concurrency** — Package targets 强制 `swiftLanguageMode(.v6)`
- ✅ **SwiftData** — @Model，最低 iOS 17 / macOS 14（与 Package 平台声明一致）
- ✅ **App Groups** — 主 App / Widget 共享数据库
- ✅ **充血模型 + 领域服务** — 模型轻，业务放服务
- ✅ **Sendable 思维** — 跨模块并发安全
- ✅ **模块化** — Core / Models / Persistence / ReviewKit 聚合

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

// 启动早期（App/Scene 初始化前）配置共享参数
ReviewKitConfiguration.configure(
   .init(appGroupIdentifier: "group.com.example.shared")
)

// 访问持久化
let container = PersistenceController.shared.container

// 创建新错题（知识点为原生数组）
let item = ReviewItemModel(
   title: "二次函数求根",
   subjectRaw: Subject.math.rawValue,
   difficultyRaw: Difficulty.medium.rawValue,
   knowledgePoints: ["二次函数", "求根"]
)

// 记录复习
item.recordReview(performance: 2)  // 大部分掌握
// nextReviewDate 自动更新

// SwiftData 谓词示例（iOS 17+ 原生数组查询）
// let predicate = #Predicate<ReviewItemModel> { $0.knowledgePoints.contains("二次函数") }

// 使用调度器
let scheduler = ReviewScheduler()
let days = scheduler.calculateIntervalDays(currentMastery: 2, reviewCount: 3)
```

### 自定义配置（App Group / 路径）

在应用启动早期设置共享配置，然后用自定义实例：

```swift
ReviewKitConfiguration.configure(
   .init(
      appGroupIdentifier: "group.com.example.shared",
      databaseFileName: "Example.sqlite",
      imagesDirectoryName: "Images"
   )
)

let persistence = PersistenceController(configuration: .shared)
let imageStorage = ImageStorageService(configuration: .shared)

// 异步保存/读取图片（仅在 canImport(UIKit)/canImport(AppKit) 下）
let fileName = try await imageStorage.saveImage(image, for: itemId)
let loaded = await imageStorage.loadImage(named: fileName)
```

### 模块结构

- `ReviewKitCore`: 调度器、值对象、通用错误
- `ReviewKitModels`: SwiftData 模型
- `ReviewKitPersistence`: 配置、数据库、图片存储
- `ReviewKit`: 聚合层，`import ReviewKit` 即可使用全部 API

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
