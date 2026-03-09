# SnapDrillUI

**设计系统与组件库 (The Design System & Component Library)**

`SnapDrillUI` 定义了应用的视觉语言，并提供共享 UI 组件。

## 关键组件
- **ImageCropperView**: 图片裁剪器（基于 Mantis）
- **FlipView**: 卡片翻转动画组件（泛型）
- **TagInputView**: 标签输入控件（自由输入 + 历史建议）
- **SnapDrillButton**: 统一按钮样式
- **TabItem**: Tab 枚举（dashboard/library/capture/review/settings）
- **Navigation.swift**: FeatureRouter 路由协议

## 依赖
- `SnapDrillCore`: 引用核心类型
- `Mantis`: 图片裁剪库（MIT License）

## 设计理念
所有共享的 UI 组件（如裁剪器、翻转动画）都下沉到此层，以避免功能模块之间的循环依赖。
