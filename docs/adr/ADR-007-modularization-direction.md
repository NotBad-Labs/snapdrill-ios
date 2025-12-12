# ADR-007: 模块化架构演进方向

## 状态
**已采纳** (Accepted)

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

### 4. 小团队的取舍（避免过度拆分）

- **优先保持 App 薄壳 + 少数高复用包**：App 只管 UI/导航/组装；`ReviewKit` 管模型与算法；`CaptureKit` 管录入链路；`ProcessKit` 管图像增强；`DesignSystem` 视需求再抽。不要做“一个巨大 Kit”。
- **触发拆包的条件**：多端复用（Widget/CLI/macOS）、并行开发、编译时间瓶颈、或需要对外分发库。否则先留在主 Target，避免无谓复杂度。
- **依赖方向**：App → Kits；Kits 之间尽量无环；Kit 不 import SwiftUI（除非专为 UI 的 DesignSystem），SwiftData 模型只定义一处（ReviewKit）。
- **决策清单**（满足两项再拆）
    1) 这段代码是否会被至少两个 Target 复用？
    2) 业务/编译耦合是否能因拆包显著降低？
    3) 接口是否足够稳定，拆出后维护成本可控？
    4) 是否有明确的公共 API 轮廓和封装边界？

### 5. Swift 6.x 的实践提示

- 保持核心 Kit 不依赖 SwiftUI；使用 `StrictConcurrency`/`Sendable` 提前规避并发问题。
- 尽量 internal 化非必要 API，减轻接口膨胀与编译负担。
- 通过局部包划分减少全量重编，兼顾原生性能与迭代效率。

## 实施时机

| 条件 | 行动 |
|------|------|
| 当前（功能未稳定） | 保持实用主义架构 |
| 功能稳定后 | 创建 ReviewKit，迁移算法 |
| 代码量 > 5万行 | 拆分 ImageKit、OCRKit |
| 多平台扩展 | 全面依赖 Package |

> **更新 (2025-12-12)**: ImageKit 和 OCRKit 已整合为 **CaptureKit**，同时新增 **ProcessKit** 用于图像处理。当前架构为 ReviewKit + CaptureKit + ProcessKit（3-Kit 架构）。详见 [SCAN_FLOW.md](../SCAN_FLOW.md)。

> 小团队决策卡片见 `docs/ARCHITECTURE.md`（薄壳 App + 少量高复用包，避免巨大单包；依赖方向 App→Kits，满足复用/降耦合/接口稳定再拆包）。

## 工程师点评（摘要）

- **薄壳 App + 核心三包**：保持 App 只做 UI/导航/组装；核心仅维护 `ReviewKit`（模型/算法/迁移）、`CaptureKit`（扫描/OCR/图片存储）、`ProcessKit`（图像增强/AI擦除）。DesignSystem 视需求再抽，避免“巨大 CommonKit”。
- **依赖与命名空间**：App/Widget 共享 ReviewKit 中的 SwiftData 模型，杜绝多处定义；Kits 不引入 SwiftUI（除非专为 UI 的 DesignSystem），避免环依赖。
- **拆包触发**：需多 Target 复用或明显降低编译/耦合时再拆；单平台、小团队、<5 万行且无编译瓶颈时可暂缓，保持主 Target 简单高效。
- **并发与性能**：先在核心 Kit 开启 Strict Concurrency（Swift 6），分而治之；包内尽量 internal 化非公开 API，减轻接口膨胀与编译负担。
- **验证与测试**：用 CLI Target 仅依赖 ReviewKit 跑通算法，证明核心可独立于 UI；核心测试快速、无须启动模拟器。

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
