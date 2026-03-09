---
description: 按照分层架构自动初始化新业务功能
---

# 新功能开发工作流

本工作流旨在规范新功能的代码组织结构，确保严格遵守单向依赖。

## 执行步骤

1. **层级定义**:
   - **SnapDrillCore**: 零依赖内核。涉及 Model、Service、Engine。禁止依赖 SwiftUI。
   - **SnapDrillData**: 数据持久化。@Model 类、Repository 具体类、PersistenceController。依赖 Core。
   - **SnapDrillUI**: 视觉组件层。设计系统、共享组件。依赖 Core。
   - **SnapDrillFeatures**: 5 个独立 SPM target，各自包含 View + ViewModel + Router。依赖 Core、Data、UI。
   - **SnapDrillInfrastructure**: Firebase 实现。仅 App 可 import。依赖 Core。
   - **SnapDrill/App**: 薄壳组合根。DependencyContainer + AppRouter。

2. **新功能文件结构**:
   （假设新功能名为 `Fortune`，归入已有 Feature target 或新建 target）

   ```bash
   # 在 Core 中创建 Service（如需要）
   mkdir -p Packages/SnapDrillCore/Sources/SnapDrillCore/Service/Fortune

   # 在对应 Feature target 中创建业务逻辑
   # 新建独立 target 时需同步修改 Packages/SnapDrillFeatures/Package.swift
   mkdir -p Packages/SnapDrillFeatures/Sources/SnapDrillFeatureFortune
   ```

3. **初始化核心文件**:
   - 在 Feature target 中创建 `FortuneView.swift`、`FortuneViewModel.swift`
   - ViewModel 必须为 `@Observable @MainActor final class`
   - 如需路由：创建 `FortuneRouter.swift`

4. **注释规范**:
   - 所有 `public` 接口包含 `///` 格式的中文 DocC 注释；参数名可保留英文。

5. **新增 API 同步**:
   - 新增的 public API 必须同步更新 `.claude/infrastructure.md`。

## 架构原则提醒

- **Core**: 做什么？（算法/服务/模型）
- **Data**: 存在哪？（@Model/Repository）
- **UI**: 长什么样？（设计系统/共享组件）
- **Features**: 业务怎么走？（ViewModel/View/Router）
- **App**: 怎么接线？（DI/Composition Root）

详见 `.claude/architecture.md` 和 `.claude/principles.md`。
