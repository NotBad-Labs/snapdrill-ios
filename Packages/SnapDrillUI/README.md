# SnapDrillUI

**设计系统与组件库 (The Design System & Component Library)**

`SnapDrillUI` 定义了应用的视觉语言，并提供高层级的 UI 业务组件。

## 关键组件
- **ImageCropperView**: 图片裁剪器 (基于 Mantis)。
- **Design System**: 基础 Token (Color, Typography)。
- **FeatureRouter**: 统一路由协议。

## 依赖
- `SwiftUI`
- `Mantis` (Image Cropping Library, MIT License)

## 设计理念
所有共享的 UI 组件（如裁剪器、通用弹窗）都应下沉到此层，以避免功能模块之间的循环依赖。
