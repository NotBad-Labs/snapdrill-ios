# SnapDrill 代码与注释风格指南 (Style Guide)

本文档定义了 SnapDrill 项目的“最大公约数” (GCD) 开发规范，所有现有及新代码均须遵循此标准。

## 1. 文件结构与头部 (File Header)

每个文件顶部必须包含标准的 Xcode 版权声明，并在其下方紧跟一行核心职责描述。

```swift
//
//  FileName.swift
//  SnapDrill...
//
//  Created by ...
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  一句话描述该文件的功能。
//
```

## 2. 代码组织 (Organization)

强制使用 `// MARK: - [Section]` 划分代码块，确保文件结构扫描器（如 Xcode Minimap）清晰可见。

### 2.1 推荐顺序

1. **Properties**: `@State`, `@Environment`, `private let` 等属性。
2. **Initialization**: `init` 方法。
3. **Public API**: 对外暴露的方法或计算属性。
4. **View Body / Lifecycle**: SwiftUI `body` 或 `onAppear` 等。
5. **Private Helpers**: 私有辅助方法。
6. **Preview**: 预览代码。

## 3. 注释规范 (Documentation)

### 3.1 类与结构体

使用 `///` 提供职能描述。复杂类需包含 `## 职责` 或 `## 架构设计` 章节。

```swift
/// 复习会话 ViewModel
///
/// 管理复习流程的完整状态，包括队列加载、评分与调度。
```

### 3.2 属性

使用 `///` 描述属性用途，而非其类型。

```swift
/// 当前待复习的队列
var reviewQueue: [ReviewItemModel] = []
```

### 3.3 方法 (DocC)

必须包含摘要，必要时提供 `- Parameters:`, `- Returns:`, `- Throws:`。

```swift
/// 处理卡片划走后的回调
/// - Parameter direction: 正数代表右滑（记得），负数代表左滑（忘记）
func handleSwipeCompletion(direction: Int)
```

## 4. 语言规范

- **注释语言**: 强制使用 **中文**（Simplified Chinese）。对于极其通用的专业术语（如 SM-2, OCR）可保留英文。
- **DocC**: 公开 API 使用中文 `///` 注释；参数名可保留英文。

## 5. 交互与 UI 连通性

- **禁止孤儿功能**: 每一个 Repository 层的方法或 ViewModel 的公开属性，都必须有明确的 UI 调用链。
- **UI 预留**: 若功能已实现但 UI 未准备好，必须标注 `// TODO: UI Integration Pending`。
