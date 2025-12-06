# NotBad 项目架构文档

> 最后更新：2025年12月6日  
> 分支：minimal

## 📋 概述

NotBad 是一款面向 K12 学生的错题本应用，采用 **实用主义架构** 设计。核心理念是：

- **简单优先**：避免过度设计，直接使用 SwiftUI + SwiftData
- **模块化**：核心逻辑抽取为独立 Swift Package，便于测试和复用
- **App Groups 共享**：主 App 和 Widget 共享同一数据库

---

## 🏗️ 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        NotBad App                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    Views Layer                        │   │
│  │  ContentView → DashboardView / LibraryView / ...     │   │
│  │  直接使用 @Query 获取数据                              │   │
│  └──────────────────────────────────────────────────────┘   │
│                           │                                  │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │               Presentation/Common                     │   │
│  │  Components / Styles / Education / Tips              │   │
│  └──────────────────────────────────────────────────────┘   │
│                           │                                  │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                Infrastructure Layer                   │   │
│  │  OCR / AI / Analytics / Search / Widget              │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Swift Packages                            │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │  ReviewKit │  │  ImageKit  │  │   OCRKit   │             │
│  │  ─────────  │  │  ─────────  │  │  ─────────  │             │
│  │  Model     │  │  Storage   │  │  Vision    │             │
│  │  ValueObj  │  │  Service   │  │  Service   │             │
│  │  Scheduler │  │            │  │            │             │
│  │  Persist   │  │            │  │            │             │
│  └────────────┘  └────────────┘  └────────────┘             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   App Groups 共享存储                        │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  group.com.notbad.shared                               │ │
│  │  ├── NotBad.sqlite (SwiftData 数据库)                   │ │
│  │  └── Images/ (错题图片)                                 │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 模块结构

### 1. ReviewKit（核心领域层）

位置：`Packages/ReviewKit/`

**职责**：核心业务逻辑，可独立于 UI 运行和测试。

| 文件 | 职责 |
|------|------|
| `Models/ReviewItemModel.swift` | SwiftData 模型（充血模型），包含业务逻辑 |
| `ValueObjects/ValueObjects.swift` | 值对象：Subject, Grade, MasteryLevel, Difficulty 等 |
| `Data/PersistenceController.swift` | App Groups 共享数据库控制器 |
| `ReviewScheduler.swift` | 间隔重复算法（SM-2 变体） |
| `ReviewKit.swift` | 模块入口，导出 SwiftData |

**关键设计**：
- 使用 `StrictConcurrency` 为 Swift 6 做准备
- Model 放在 Package 中解决 SwiftData 命名空间问题
- 所有类型都是 `public`，供主 App 和 Widget 使用

```swift
// 使用示例
import ReviewKit

// 获取共享容器
let container = PersistenceController.shared.container

// 创建错题
let item = ReviewItemModel(title: "二次函数", subject: .math)

// 记录复习
item.recordReview(newMastery: .partial)
```

### 2. ImageKit（图片存储）

位置：`Packages/ImageKit/`

**职责**：图片文件的保存和读取。

| 文件 | 职责 |
|------|------|
| `ImageStorageService.swift` | 图片存储服务，使用 App Groups 共享目录 |
| `ImageKit.swift` | 模块入口 |

### 3. OCRKit（文字识别）

位置：`Packages/OCRKit/`

**职责**：基于 Vision 框架的 OCR 服务。

| 文件 | 职责 |
|------|------|
| `OCRService.swift` | Vision OCR 封装 |
| `OCRTypes.swift` | OCR 结果类型定义 |
| `OCRKit.swift` | 模块入口 |

---

## 📱 主 App 结构

位置：`NotBad/`

### Views（视图层）

位置：`NotBad/Views/`

采用 **简化架构**：View 直接使用 `@Query` 获取数据，无需 ViewModel。

| 文件 | 职责 |
|------|------|
| `ContentView.swift` | 主入口，TabView 导航 |
| `Dashboard/DashboardView.swift` | 首页仪表盘，统计概览 |
| `Library/LibraryView.swift` | 错题库列表 |
| `Library/ItemRow.swift` | 列表行视图 |
| `Capture/CaptureView.swift` | 拍照录入 |
| `Review/ReviewView.swift` | 复习页面 |
| `Settings/SettingsView.swift` | 设置页面 |

```swift
// LibraryView 示例 - 直接使用 @Query
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

### Presentation/Common（通用组件）

位置：`NotBad/Presentation/Common/`

| 目录 | 内容 |
|------|------|
| `Components/` | 可复用 UI 组件（AsyncButton, FilterChip, ToastView 等） |
| `Styles/` | 主题、按钮样式、卡片样式 |
| `Education/` | 教育体系配置（中国、美国、日本等） |
| `Tips/` | TipKit 提示定义 |
| `Views/` | 启动页等通用视图 |
| `Services/` | SearchHistoryManager 等 |

### Infrastructure（基础设施）

位置：`NotBad/Infrastructure/`

| 目录 | 职责 |
|------|------|
| `AI/` | Apple Intelligence 集成（SmartAnalysisService, SocraticTeachingService） |
| `OCR/` | OCR 服务封装 |
| `Search/` | Spotlight 索引服务 |
| `Widget/` | Widget 数据同步 |
| `Analytics/` | 本地分析服务 |
| `Protocols/` | 服务协议定义 |
| `Utils/` | 工具类（日志、缓存、压缩等） |
| `Localization/` | 本地化键定义 |

---

## 🔗 数据流

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   用户操作   │ ──▶ │   View      │ ──▶ │  SwiftData  │
│  (拍照/复习)  │      │ (@Query)    │      │  ModelContext │
└─────────────┘      └─────────────┘      └─────────────┘
                            │                     │
                            ▼                     ▼
                     ┌─────────────┐      ┌─────────────┐
                     │ Infrastructure │      │  App Groups │
                     │  (OCR/AI)   │      │   Storage   │
                     └─────────────┘      └─────────────┘
```

### 典型流程：添加错题

1. 用户在 `CaptureView` 拍照
2. 调用 `OCRService` 识别文字
3. 调用 `SmartAnalysisService` 分析学科
4. 创建 `ReviewItemModel` 保存到 SwiftData
5. `ImageStorageService` 保存图片到 App Groups
6. Widget 自动刷新显示最新数据

---

## 📊 文件统计

| 类别 | 数量 |
|------|------|
| 主 App Swift 文件 | 61 个 |
| ReviewKit 文件 | 5 个 |
| ImageKit 文件 | 2 个 |
| OCRKit 文件 | 3 个 |
| Views 文件 | 7 个 |
| Components 文件 | 15 个 |
| Infrastructure 文件 | 13 个 |

> 注：Components 中大部分为待集成的预备组件，当前仅 ImagePicker 被使用。

---

## 🎯 设计决策

### 为什么选择实用主义架构？

1. **SwiftData 原生支持**：`@Query` 自动响应数据变化，无需手动刷新
2. **减少样板代码**：避免 ViewModel/UseCase/Repository 层层传递
3. **更快迭代**：功能开发更直接，调试更简单

### 为什么使用 Swift Package？

1. **解决 SwiftData 命名空间问题**：Widget 和 App 必须使用相同的 Model 类名
2. **独立测试**：ReviewKit 可以不依赖 UI 进行单元测试
3. **代码复用**：未来可以复用到其他项目

### App Groups 的作用

| 共享内容 | 路径 |
|---------|------|
| 数据库 | `group.com.notbad.shared/NotBad.sqlite` |
| 图片 | `group.com.notbad.shared/Images/` |

---

## 🧪 测试策略

| 层级 | 测试类型 | 当前状态 |
|------|---------|---------|
| ReviewKit | 单元测试 | ✅ ReviewSchedulerTests |
| OCRKit | 集成测试 | ✅ OCRIntegrationTests |
| ImageKit | 单元测试 | ✅ ImageStorageServiceTests |
| 主 App | UI 测试 | 📋 待补充 |

---

## 📝 开发指南

### 添加新功能

1. **纯业务逻辑** → 添加到 ReviewKit
2. **UI 组件** → 添加到 Presentation/Common/Components
3. **新页面** → 添加到 Views/，使用 @Query 获取数据
4. **外部服务** → 添加到 Infrastructure/

### 修改 Model

1. 修改 `ReviewKit/Models/ReviewItemModel.swift`
2. 如需迁移，更新 `NotBad/Data/ReviewItemMigrationPlan.swift`
3. 运行 ReviewKit 测试验证

### 添加新的值对象

1. 添加到 `ReviewKit/ValueObjects/ValueObjects.swift`
2. 确保是 `public` 且符合 `Codable`, `Sendable`

---

## 🔮 未来规划

- [ ] 添加 Widget Target
- [ ] 补充 UI 测试
- [ ] 添加 iCloud 同步
- [ ] 支持 PDF 导出
- [ ] 添加学习报告功能

---

## 📚 相关文档

- [编码规范](CODING_STANDARDS.md)
- [代码审查指南](CODE_REVIEW_GUIDELINES.md)
- [术语表](GLOSSARY.md)
