# ``SnapDrillUI``

共享设计系统，提供可复用的 SwiftUI 组件和无障碍工具。

## 概述

`SnapDrillUI` 包含所有跨功能模块共用的 UI 组件。
该包依赖 `SnapDrillCore`（用于日志和错误类型），不依赖 `SnapDrillData` 或 `SnapDrillFeatures`。

## 主要组件

### 导航

- ``FeatureRouter`` — 所有功能 Router 遵循的协议，提供 push / pop / reset 默认实现
- ``TabItem`` — 定义 App 底部 Tab 的枚举项及图标、标题

### 交互组件

- ``FlipView`` — 翻转动画视图（复习卡片正反面切换）
- ``TagInputView`` — 标签输入框，支持补全建议
- ``SnapDrillButton`` — 统一样式的主操作按钮
- ``ImageCropperView`` — 基于 Mantis 的图片裁剪视图（`UIViewControllerRepresentable`）

### 错误与反馈

- ``AppError`` — 应用级错误枚举，携带用户友好文案和对应 SF Symbol
- ``ContextualErrorView`` — 全屏错误占位视图
- ``ErrorBannerView`` — 内联非阻断性错误横幅
- ``ErrorMessageView`` — 带重试按钮的错误消息视图
- ``LoadingView`` — 通用加载状态视图
- ``ProgressLoadingView`` — 带进度百分比的加载视图
- ``SkeletonLoadingView`` — 骨架屏加载占位视图

### 引导与隐私

- ``OnboardingView`` — 首次启动引导流程视图
- ``OnboardingPage`` — 引导页数据模型
- ``OnboardingManager`` — 持久化引导完成状态

### 无障碍

- `View.accessible(label:hint:value:)` — 统一设置无障碍标签
- `View.accessibleButton(label:hint:)` — 标记为无障碍按钮
- ``AccessibilityHelper`` — 生成复习项、进度、日期的无障碍文本
- ``AccessibilityAnnouncement`` — 发送 VoiceOver 公告
- ``AccessibilityNotificationPriority`` — 控制通知优先级
