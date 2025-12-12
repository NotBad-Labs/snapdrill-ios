# NotBad 项目架构文档

> 最后更新：2025年12月6日  
> 分支：minimal  
> 权威顺序：ADR → ARCHITECTURE → README（如有冲突以 ADR 优先）

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
│  │ ReviewKit  │  │ CaptureKit │  │ ProcessKit │             │
│  │  ─────────  │  │  ─────────  │  │  ─────────  │             │
│  │  Model     │  │  Storage   │  │  ImageProc │             │
│  │  ValueObj  │  │  OCR       │  │  Enhance   │             │
│  │  Scheduler │  │  Scanner   │  │  AI Erase  │             │
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

### 2. CaptureKit（扫描与输入）

位置：`Packages/CaptureKit/`

**职责**：错题录入全链路，包括扫描、OCR、图片存储。

| 文件 | 职责 |
|------|------|
| `Scanner/ScanState.swift` | 扫描状态机（searching → detected → capturing → processing） |
| `Scanner/DraftScan.swift` | 防腐层临时对象，验证扫描有效性 |
| `Scanner/LiveDocumentDetector.swift` | 实时文档检测（VisionKit） |
| `OCR/OCRService.swift` | Vision OCR 封装 |
| `OCR/OCRTypes.swift` | OCR 结果类型定义 |
| `Storage/ImageStorageService.swift` | 图片存储服务，使用 App Groups 共享目录 |
| `CaptureKit.swift` | 模块入口 |

**关键设计**：
- 实现**C 混合模式**：强引导扫描 + 手动回退
- DraftScan 防腐层防止脏数据污染 ReviewKit
- 只输出事实（facts）和决策提示（hints），不决定业务策略

### 3. ProcessKit（图像处理）

位置：`Packages/ProcessKit/`

**职责**：AI 图像增强与手写擦除。

| 文件 | 职责 |
|------|------|
| `ImageProcessor.swift` | 图像处理主入口 |
| `ColorBasedEraser.swift` | 基于颜色过滤的快速擦除 |
| `CoreML/` | Core ML 模型集成（语义分割） |
| `ProcessKit.swift` | 模块入口 |

**关键设计**：
- 纯图像处理层，不依赖其他 Kit
- 支持异步处理和进度反馈
- 失败时自动降级到原始图像

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

1. 用户在 `CaptureView` 启动扫描
2. `CaptureKit` 实时检测文档边界（VisionKit）
3. 用户确认拍摄 → 生成 `DraftScan`
4. 调用 `OCRService` 识别文字
5. 可选：调用 `ProcessKit` AI 增强图像
6. `DraftScan` 验证通过 → 用户确认
7. 主 App 将 `DraftScan` 转换为 `ReviewItemModel` 保存到 SwiftData
8. `ImageStorageService` 保存图片到 App Groups
9. Widget 自动刷新显示最新数据

> 详细流程说明见 [扫描流程规范](SCAN_FLOW.md)

---

## 📊 文件统计

> 说明：文件数量随分支/迭代变化，以下不再列静态数字。如需统计，可运行 `find NotBad -name '*.swift' | wc -l`（或分目录统计）。

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
| CaptureKit | 集成测试 | ✅ OCR/Scanner/ImageStorageTests |
| ProcessKit | 单元测试 | ✅ ImageProcessorTests |
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

## 🧭 小团队模块化决策卡片

- **优先策略**：薄壳 App + 少数高复用包（ReviewKit 管模型/算法；CaptureKit 管录入链路；ProcessKit 管图像增强；DesignSystem 视需求再抽）。避免“一个巨大 Kit”。
- **依赖方向**：App → Kits；Kits 之间无环；Kit 不引入 SwiftUI（除非专为 UI 的 DesignSystem）；SwiftData 模型只定义在 ReviewKit。
- **何时拆包（满足两项再拆）**：
    1) 代码需被至少两个 Target 复用（App/Widget/CLI/macOS 等）。
    2) 拆出后能显著降低编译/耦合或方便并行开发。
    3) 公共 API 已相对稳定、边界清晰。
- **何时暂缓**：单平台、团队 <5 人、代码量 <5 万行且无编译瓶颈时，保持主 Target 更简单高效。

---

## 📚 相关文档

- [扫描流程规范](SCAN_FLOW.md) - **权威**：C 混合模式扫描流程详细说明
- [架构哲学](ARCHITECTURE_PHILOSOPHY.md) - Domain-First vs Camera-First 设计决策
- [3Kit 验证报告](3KIT_VALIDATION_REPORT.md) - CaptureKit/ProcessKit/ReviewKit 架构验证
- [编码规范](CODING_STANDARDS.md)
- [代码审查指南](CODE_REVIEW_GUIDELINES.md)
- [术语表](GLOSSARY.md)
