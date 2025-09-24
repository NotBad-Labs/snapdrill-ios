# ---

title: NotBad 设计系统 (Design System) v6.0
version: v6.0
lastUpdated: 2025-09-21
baseline:
  ios: 26
  xcode: 26
  swift: 6.2
  device: iPhone 17
---

## NotBad 设计系统 (Design System) v6.0

> **版本**: v6.0
> **技术对应**: Swift 6.2 + iOS 26 + Xcode 26

## 📚 设计文档结构

### 主要文档

- **UX_SPEC.md**: 完整的设计规范，包含：
  - 视觉系统（色彩、字体、间距）
  - SwiftUI组件库（按钮、卡片、Discovery社区组件）
  - 动效规范（ProMotion Max 120fps优化）
  - 无障碍设计标准
  - 多平台适配规格

## 🎨 设计原则概览

### 核心设计价值

1. **Swift 6.2 原生**: 充分利用Enhanced Actor和现代并发特性
2. **iOS 26 先进**: 应用最新Material效果和Advanced Dynamic Type
3. **Discovery社区友好**: 专为匿名化社区交互优化的组件
4. **120fps丝滑**: ProMotion Max支持的高帧率动画
5. **无障碍优先**: WCAG AA标准，全面VoiceOver支持

### 技术特色

- **类型安全色彩**: Swift 6.2类型系统保障的色彩管理
- **Enhanced Actor组件**: 基于现代并发模式的UI组件
- **iOS 26 Material**: 最新毛玻璃和材质效果
- **语义化设计令牌**: JSON格式的标准化设计Token

## 🔗 文档关联关系

```mermaid
PRD v6.0 (产品需求)
    ↓
UX_SPEC.md (设计规范)
    ↓
TDD v6.0 (技术实现)
```

### 协作流程

1. **产品**: PRD v6.0定义功能需求和用户任务
2. **设计**: UX_SPEC.md提供视觉规范和组件标准
3. **开发**: TDD v6.0实现SwiftUI组件和Enhanced Actor架构

## 📱 支持平台

| 平台 | 版本 | 状态 | 特殊考虑 |
|------|------|------|----------|
| iPhone | iOS 26+ | ✅ 完整支持 | ProMotion Max优化 |
| iPad | iPadOS 26+ | 🚧 vNext计划 | 分屏适配 |
| visionOS | visionOS 3+ | 🚧 vNext计划 | 空间计算UI |

## 🛠 设计工具链

- **Figma**: 主要设计工具（待建立项目链接）
- **SF Symbols**: iOS 26最新符号集
- **Xcode Previews**: SwiftUI组件实时预览
- **Accessibility Inspector**: 无障碍验证工具

## 📋 更新日志

### v6.0 (2025-09-19)

- ✨ 初始发布：完整v6.0设计规范
- 🎯 Swift 6.2 + iOS 26技术栈对齐
- 🌟 Discovery社区组件系统
- ⚡ ProMotion Max 120fps动效规范
- ♿ 全面无障碍设计标准

---

**维护责任**: 设计团队
**技术对接**: TDD v6.0开发团队
**版本同步**: 与PRD v6.0、TDD v6.0保持严格一致
