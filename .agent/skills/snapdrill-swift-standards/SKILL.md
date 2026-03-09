---
name: snapdrill-swift-standards
description: SnapDrill 项目的 20 条核心 Swift 6 开发标准与架构规约。当需要重构、审查代码或编写新功能时自动激活。
---

# SnapDrill 专属开发标准 (Master Rules)

Inherits from: [Global Constitution](file:///Users/yiming/.gemini/antigravity/GLOBAL_CONSTITUTION.md)

## 🏗️ 项目架构与技术栈

- **Bundle ID**: `com.snapdrill.app` | **最低版本**: iOS 26.0
- **技术栈**: Swift 6.2 + SwiftUI + SwiftData
- **模块化**: SnapDrillFeatures → SnapDrillData/SnapDrillUI → SnapDrillCore (严禁逆向引用)
- **质量核心**: **零技术债 (Zero Tech Debt)** - 绝不为了发布而牺牲代码质量。

## 📍 核心铁律

### 1. 并发稳定与隔离

- **UI 隔离**: 所有 ViewModel 强制标记 `@Observable @MainActor`。
- **任务管理**: 异步 `Task` 必须具备明确的句柄管理和取消逻辑（Cancellation Check），严禁无取消机制的 OCR/IO 任务。
- **绝对禁令**: 严禁使用 `@unchecked Sendable`。
- **`any` existentials**: 默认禁止，以下例外须加注释说明理由：
  - `EnvironmentKey.Value` 为跨模块协议类型（消除 `any` 需打破依赖方向）
  - 无 associated type / Self 约束的协议作为集合元素（如 `[any PDFExportable]`，框架限制）

### 2. 数据生命线 (Data Integrity)

- **Repo 封装**: View/ViewModel 不直接操作 `ModelContext`，必须通过具体 Repository 类（无协议，已删除）。
- **强一致性**:
  - 严禁 `try?` 静默失败（关键保存/初始化路径）。
  - 级联重写：分类重命名必须级联更新记录。
  - 删除拦截：在库中被引用的分类必须拦截删除并引导用户。

### 3. 代码质量与禁令

- **日志系统**: 禁止 `print()`，使用 `SnapDrillLogger`。
- **强制约束**: 严禁强制解包 `!`，`any` 类型受限使用（见上方例外清单）。
- **注释语言**: 公开 API 必须提供 `///` DocC 注释，使用**中文描述**，参数名保留英文。

## 📍 关键原则文件索引

1. **架构与原则**: `.claude/principles.md`（决策前研究铁律、Apple 原生优先、并发规则、Git 工作流）
2. **架构总览**: `.claude/architecture.md`（5 包结构、依赖图、DI 链路）
3. **API 权威参考**: `.claude/infrastructure.md`（所有公开接口签名）
4. **产品思维**: `.claude/product.md`（用户旅程、功能边界、商业化策略）
