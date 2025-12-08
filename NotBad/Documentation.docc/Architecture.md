# Architecture

NotBad 采用实用主义架构设计，充分发挥 SwiftData 原生能力。

## Overview

我们放弃了严格的 Clean Architecture 分层，采用更简单、更高效的 3 层结构：

```
┌─────────────────────────────────────────┐
│              Views Layer                │
│         (SwiftUI + @Query)              │
├─────────────────────────────────────────┤
│            Services Layer               │
│      (ImageStorage, OCR, Algorithm)     │
├─────────────────────────────────────────┤
│             Models Layer                │
│         (@Model + 业务逻辑)              │
└─────────────────────────────────────────┘
```

## 核心原则

### 1. SwiftData 原生驱动

View 直接使用 `@Query` 读取数据，无需中间层：

```swift
struct LibraryView: View {
    @Query(sort: \ReviewItemModel.createdAt, order: .reverse)
    private var items: [ReviewItemModel]
    
    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### 2. 充血模型

业务逻辑直接写在 `@Model` 中：

```swift
@Model
final class ReviewItemModel {
    var wrongCount: Int
    
    // 业务属性
    var isHardQuestion: Bool {
        wrongCount > 5
    }
    
    // 业务方法
    func recordReview(correct: Bool) {
        // 更新复习状态
    }
}
```

### 3. 图片分离存储

**严禁**将图片 Data 存入 SwiftData：

| 存储位置 | 内容 |
|---------|------|
| SwiftData | `imagePath: String?` |
| FileManager | 图片文件 (.jpg) |

### 4. 服务层职责

无状态的复杂逻辑放入 Service：

- `ImageStorageService`: 图片文件读写
- `OCRService`: 文字识别
- `ReviewAlgorithm`: 复习间隔计算

## 数据流

```
Database (@Model) → @Query (自动刷新) → View
         ↑                                |
         └──────── Service (逻辑/IO) ──────┘
```

## 模块化演进方向

> **核心洞察**：文件夹分层是"君子协定"，Package 隔离是"物理围墙"。编译器才是最好的架构守卫。

当功能稳定后，App 将只是一层薄薄的 UI 壳：

```text
NotBad (App Target) - 画皮 + 组装
└── Packages/
    ├── ReviewKit    # 🧠 大脑：数据、算法、逻辑
    ├── ImageKit     # 图片处理
    └── OCRKit       # 文字识别
```

**终极测试**：创建一个 macOS 命令行工具 Target，依赖 ReviewKit，能直接跑通复习算法。如果做到了，你的核心资产就可以复用到 Widget、App Clip、macOS、watchOS。

详见 [ADR-007: 模块化演进方向](../../docs/adr/ADR-007-modularization-direction.md)

## 架构决策记录

- ``<doc:ADR-006-pragmatic-architecture>`` - 实用主义架构
- ``<doc:ADR-007-modularization-direction>`` - 模块化演进方向

## See Also

- <doc:Views>
