# SnapDrill Copilot 指令 (重构版草案)

## 项目愿景
SnapDrill 是一款专为 **iOS** 设计的间隔重复（Spaced-Repetition）学习应用（错题本）。目标是提供极致的原生体验，利用 Swift 6 的现代特性构建高性能、高可靠性的学习工具。

## 技术栈
- **语言**: Swift 6 (开启严格并发检查)
- **UI 框架**: SwiftUI (仅限 iOS 17.0+)
- **持久化**: SwiftData
- **架构**: 模块化 SPM (Swift Package Manager) + 单向依赖原则

## 架构与模块命名规约

### 模块命名 (SPM)
所有内部包统一采用 `SnapDrill` 前缀，后接具体职责名。严禁使用模糊的 `Kit` 后缀。

| 包名 | 职责层级 | 说明 | 依赖限制 |
| :--- | :--- | :--- | :--- |
| **SnapDrillCore** | Kernel (内核层) | 对应 `ReviewItem` 概念。包含题目定义、通用协议、基础枚举。 | **0 依赖** |
| **SnapDrillEngine** | Logic (逻辑层) | 对应 `ReviewPlan` 概念。包含复习调度算法、掌握程度计算。 | 依赖 `SnapDrillCore` |
| **SnapDrillData** | Infrastructure (数据层) | 对应 `Storage` 概念。SwiftData 模型定义及持久化逻辑。 | 依赖 `SnapDrillCore` |
| **SnapDrillService** | Service (服务层) | 对应 `Capture` 核心逻辑。封装 OCR、Vision、图像处理。 | 依赖 `SnapDrillCore` |
| **SnapDrillUI** | Presentation (组件层) | 全局设计系统、通用 UI 组件、图标资源。 | 依赖 `SnapDrillCore` |
| **SnapDrillFeatureDashboard** | Feature (功能层) | **首页流程**：复习概览、今日统计、快捷入口。 | 依赖 Core, UI |
| **SnapDrillFeatureCapture** | Feature (功能层) | **采集流程**：拍照、实时检测、预览编辑界面。 | 依赖 Core, UI, Service |
| **SnapDrillFeatureLibrary** | Feature (功能层) | **题库流程**：题目列表、搜索、详情查看。 | 依赖 Core, UI, Data |
| **SnapDrillFeatureReview** | Feature (功能层) | **复习流程**：复习会话、答题交互、进度展示。 | 依赖 Core, Engine, UI, Data |
| **SnapDrillFeatureSettings** | Feature (功能层) | **设置流程**：个人资料、打印配置、系统设置。 | 依赖 Core, UI, Service |

### 依赖原则
1. **单向依赖**: 上层模块可以依赖下层模块，严禁循环依赖。
2. **接口隔离**: 模块间通过协议 (Protocol) 通讯，减少硬编码依赖。
3. **iOS 专属**: 移除所有 macOS 兼容性代码，充分利用 iOS 系统特性（如 `UIKit` 桥接、相机 API）。

## 关键开发约定

### 1. Swift 6 严格并发
- 模块必须开启 `.swiftLanguageMode(.v6)`。
- 所有的异步回调必须标注为 `@Sendable`。
- 耗时操作（I/O, 图像处理）必须封装在 `actor` 中。
- 仅在 View 层使用 `@MainActor`。

### 2. SwiftData 持久化
- 模型定义在 `SnapDrillData` 中，业务逻辑在 `SnapDrillCore` 中。
- 使用 App Groups 共享数据，确保未来可能的 Widget 扩展。
- 写入操作建议封装在专门的 `DataHandler` 或 `Repository` 中，避免在 View 中直接操作 `modelContext`。

### 3. UI 与资源
- 优先使用原生 SwiftUI 组件。
- 资源（颜色、图片）必须通过 `Asset Catalog` 管理，并使用 Swift 生成的类型安全引用。
- 本地化统一使用 `String Catalog` (.xcstrings)。

## 开发工作流
1. **分支管理**: 遵循 Git Flow。重构期间在 `refactor/` 分支进行。
2. **PR 流程**: 即使是单人开发，也建议通过 PR 进行自我审查。
3. **测试**: 核心逻辑（尤其是复习算法）必须编写 Swift Testing 测试用例。

## 避坑指南
1. **禁止跨层引用**: 例如 `SnapDrillService` 不应直接引用 `SnapDrillData`。
2. **类型安全**: 严禁使用 `Int` 或 `String` 代替枚举（如复习等级、科目类型）。
3. **平台限制**: 发现任何 macOS 相关的代码片段请立即清理。

---
**注意**: 此文档为重构期间的最高准则，Copilot 在生成代码时必须严格遵守。

