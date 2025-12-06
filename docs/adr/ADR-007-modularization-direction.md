# ADR-007: 模块化架构演进方向

## 状态
**提议中** (Proposed)

## 日期
2025-12-06（更新）

## 核心洞察

> **软件工程中最大的谎言："只要文件夹分得好，架构就很清晰。"**

事实是，只要代码还在同一个 Target 里，混乱就会像引力一样不可避免。你为了赶进度，在 View 里悄悄引用了一个 Entity，在 Model 里偷偷调了一个 UI 函数，编译器不会阻止你，但架构崩塌就是从这里开始的。

**"ReviewKit" 思维的核心不再是"分层"，而是"物理隔离"。**

## 背景

### 为什么"物理隔离"远胜"教科书式分层"？

| 方式 | 机制 | 执行者 |
|------|------|--------|
| 教科书（DDD/Clean Arch） | 逻辑上画界限 | 靠**自律** |
| 模块化（Swift Package） | 物理上建围墙 | 靠**编译器** |

当你创建一个名为 `ReviewKit` 的 Swift Package 时：

1. **它看不见 App**: 它绝对无法引用 `import UIKit` 或 App 里的任何代码。这种"单向依赖"是物理锁死的。
2. **它被迫纯粹**: 为了让编译通过，你必须把业务逻辑写得不依赖任何具体的 View。
3. **它编译极快**: 改 UI 不会触发核心库重编，改核心库不需要重编 UI（除非接口变了）。

### 行业案例印证

| 应用 | 代码量 | 架构风格 | 是否 DDD |
|------|--------|---------|---------|
| Signal | 15-20万行 | MVC + Service Kit | ❌ |
| Kickstarter | 10万+行 | MVVM + FRP | ❌ |
| Wikipedia | 15万+行 | 模块化 MVC/MVVM | ❌ |
| NetNewsWire | 8-12万行 | 原生主义 | ❌ |

**这些顶级应用没有一个用 DDD，但都用了物理模块化。**

## 决策

### 终极目标：App 只是一个"壳"

```text
NotBad.xcodeproj
├── NotBad (App Target)
│   ├── AppEntry.swift       # 入口
│   ├── Views/               # SwiftUI 视图 (只有 UI)
│   └── Navigation/          # 路由逻辑
│
└── Packages (本地 Swift Packages)
    ├── ReviewKit            # 核心业务 (大脑) 🧠
    │   ├── Models/          # ReviewItem, Subject (@Model)
    │   ├── Logic/           # SpacedRepetition (纯算法)
    │   └── Services/        # ImageStorage, OCR (功能)
    │
    └── DesignSystem (可选)   # 核心 UI (皮肤) 🎨
        ├── Colors/
        ├── Tokens/
        └── CommonComponents/
```

**顶级架构的标准：**
- **App Target**：负责"画皮"（渲染 UI）和"组装"（把 ReviewKit 的数据喂给 View）
- **ReviewKit**：负责"灵魂"（数据、算法、逻辑）

### 终极测试：CLI Test

> 在工程里添加一个 **macOS Command Line Tool** Target，让它依赖 `ReviewKit`。

```swift
// main.swift (一个没有任何 UI 的命令行工具)
import ReviewKit
import Foundation

// 1. 初始化服务
let engine = ReviewEngine()
let item = ReviewItem(title: "测试题目")

// 2. 模拟复习逻辑
let nextDate = engine.calculateNextReview(for: item, performance: .good)

// 3. 输出结果
print("下次复习时间: \(nextDate)")
```

**如果能做到这一点，没有任何报错（找不到 `Color`、找不到 `View`），那么：**

- 你的架构已经超越了 90% 的独立开发者
- 甚至超越了很多大厂的模块
- 你的核心资产（算法和数据）已经完全独立于界面存在

**这意味着未来的无限复用：**

| 场景 | 实现方式 |
|------|---------|
| iOS Widget | `import ReviewKit` |
| App Clip | `import ReviewKit` |
| macOS 版 | `import ReviewKit` |
| watchOS 版 | `import ReviewKit` |

## 实施计划：战术突围

不要一口气把所有代码都拆了，按以下步骤"战术突围"：

### 第一步：创建 Package
`File` → `New` → `Package`，命名为 `ReviewKit`，选择 `Add to Project: NotBad`

### 第二步：迁移"纯算法"（最容易）
把 `ReviewScheduler`（复习算法）剪切到 `ReviewKit` 里。

- *痛点*：它可能依赖了某个 App 里的 Enum
- *解决*：把那个 Enum 也剪切进去
- *结果*：你的算法现在是纯 Swift 的了，可以在任何地方跑

### 第三步：迁移"工具服务"（IO）
把 `ImageStorageService` 放入 `ReviewKit`。

- *痛点*：它可能依赖了 UIKit (UIImage)
- *解决*：允许 ReviewKit 依赖 UIKit，但绝不依赖 SwiftUI 的 View

### 第四步（大BOSS）：迁移 SwiftData Models
这是最难的一步，因为 `@Model` 需要 Schema。

- 最终目标是把 `ReviewItemModel` 等模型移入 Package
- 一旦完成这一步，你的 App Target 就真的只剩下一层薄薄的 UI 了

## 核心原则

### 1. 物理隔离 > 逻辑分层

| 方式 | 约束 | 违反代价 |
|------|------|---------|
| 逻辑分层 | "Domain 层不能引用 UIKit" | 只是代码审查时被说一句 |
| 物理隔离 | Package.swift 里没有 UIKit | **编译不过** |

### 2. 编译器当警卫

之前靠"文件夹+自律"维护架构，是在战术上模仿大公司的**"招式"**。
现在靠"Package+编译器"强制架构，是在战略上模仿大公司的**"内功"**。

### 3. 数据流清晰 > 层级严格

不纠结是 Entity 还是 Model，纠结的是：
```
WebSocket 来了 → 存库 → 数据库通知 → UI 刷新
```
这个链路畅通比什么都重要。

## 实施时机

| 条件 | 行动 |
|------|------|
| 当前（功能未稳定） | 保持实用主义架构 |
| 功能稳定后 | 创建 ReviewKit，迁移算法 |
| 代码量 > 5万行 | 拆分 ImageKit、OCRKit |
| 多平台扩展 | 全面依赖 Package |

## 愿景

> 当你有一天，看着 `NotBad.app` 只是简单地 `import ReviewKit`，然后一行行简洁的 UI 代码流淌出来时，你会体验到编程前所未有的掌控感。

这就是我们要去的方向。

## 参考资料

- Signal iOS: https://github.com/signalapp/Signal-iOS
- Kickstarter iOS: https://github.com/kickstarter/ios-oss
- Wikipedia iOS: https://github.com/wikimedia/wikipedia-ios
- NetNewsWire: https://github.com/Ranchero-Software/NetNewsWire

## 相关决策

- [ADR-006: 实用主义架构](ADR-006-pragmatic-architecture.md) - 当前架构
