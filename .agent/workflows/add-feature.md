---
description: 按照分层架构（Core/UI/Features）自动初始化新业务功能
---

# 新功能开发工作流

本工作流旨在规范新功能的代码组织结构，确保严格遵守 `SnapDrillCore` (逻辑) -> `SnapDrillUI` (视觉) -> `SnapDrillFeatures` (业务) -> `SnapDrill` (组合) 的单一方向依赖。

## 执行步骤

1. **层级定义**:
   - **SnapDrillCore**: 纯逻辑层。涉及 `Model`, `Service`, `Repository`。禁止依赖 `SwiftUI`。
   - **SnapDrillUI**: 视觉组件层。涉及原子组件、动画、样式定义。禁止业务逻辑。
   - **SnapDrillFeatures**: 业务层。负责具体业务逻辑、ViewModel、页面流转。
   - **SnapDrill**: 汇聚层。负责主路由、依赖注入 (Composition Root)。

2. **自动创建目录结构**:
   （假设新功能名为 `Fortune`）

   ```bash
   # 在 Core 中创建 Service 模板
   mkdir -p Packages/SnapDrillCore/Sources/SnapDrillCore/Services/Fortune
   
   # 在 UI 中创建 View 模板 (如果没有业务逻辑)
   mkdir -p Packages/SnapDrillUI/Sources/SnapDrillUI/Components/Fortune
   
   # 在 Features 中创建业务逻辑
   mkdir -p Packages/SnapDrillFeatures/Sources/SnapDrillFeatures/Fortune
   ```

3. **初始化核心文件**:
   - 在 `SnapDrillCore` 中创建 Service（使用 `@Observable`）。
   - 在 `SnapDrillFeatures` 中创建 ViewModel 与 View。

4. **双语注释校验**:
   - 确保所有 public 接口包含 `///` 格式的中英双语文档注释。

## 架构原则提醒

- **Core**: "What does it do?" (Data/Logic)
- **UI**: "How does it look?" (Theme/Animation)
- **Features**: "How is the business flow?" (ViewModel/Screen)
- **App**: "How is it wired?" (DI/Root)
