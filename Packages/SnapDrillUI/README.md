# SnapDrillUI

**设计系统与组件库 (The Design System & Component Library)**

`SnapDrillUI` 定义了应用的视觉语言，并提供共享 UI 组件。所有跨功能模块共用的 UI 组件都下沉到此层，以避免功能模块之间的循环依赖。

依赖方向：`SnapDrillUI` ──► `SnapDrillCore`（引用核心类型）

## 组成部分

### 导航
- **FeatureRouter**: 所有功能 Router 遵循的协议，提供 push / pop / reset 默认实现
- **TabItem**: App 底部 Tab 枚举（dashboard/library/capture/review/settings）

### 交互组件
- **ImageCropperView**: 图片裁剪器（基于 Mantis，`UIViewControllerRepresentable`）
- **FlipView**: 卡片翻转动画组件（泛型，用于复习卡片正反面切换）
- **TagInputView**: 标签输入控件（自由输入 + 历史建议）
- **SnapDrillButton**: 统一样式的主操作按钮

### 错误与反馈
- **AppError**: 应用级错误枚举，携带用户友好文案和对应 SF Symbol
- **ContextualErrorView**: 全屏错误占位视图
- **ErrorBannerView**: 内联非阻断性错误横幅

### 引导与帮助
- **OnboardingView**: 首次启动引导流程视图
- **OnboardingManager**: 持久化引导完成状态，管理功能提示气泡

### 无障碍
- `View.accessible(label:hint:value:)` / `View.accessibleButton(label:hint:)`: 统一无障碍标签设置
- **AccessibilityHelper**: 生成复习项、进度、日期的无障碍文本
- **AccessibilityAnnouncement**: 发送 VoiceOver 公告

### 扩展工具
- `Collection[safe:]`: 安全下标访问
- `Date` 格式化与相对描述

## 依赖
- `SnapDrillCore`: 引用核心类型（日志、错误）
- `Mantis`: 图片裁剪库（MIT License）

> 详细 API 参考见 DocC 文档：`SnapDrillUI.docc/SnapDrillUI.md`
