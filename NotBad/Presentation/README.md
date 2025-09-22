# Presentation Layer 架构说明

## 文件结构

```text
NotBad/Presentation/
├── Coordinators/          # 导航协调器

│   ├── Coordinator.swift      # 核心协调器协议

│   ├── MainCoordinator.swift  # 主协调器

│   ├── HomeCoordinator.swift  # 首页协调器

│   ├── LibraryCoordinator.swift # 题库协调器

│   ├── CaptureCoordinator.swift # 拍照协调器

│   ├── DiscoveryCoordinator.swift # 发现协调器

│   └── ProfileCoordinator.swift  # 个人协调器

├── Core/                  # 核心/共享视图

│   ├── Views/
│   │   ├── MainTabView.swift    # 主Tab导航视图

│   │   └── ContentView.swift    # 内容视图

│   └── Components/              # 共享UI组件

├── Features/              # 功能模块

│   ├── Home/                    # 首页模块

│   │   ├── Views/
│   │   │   └── HomeView.swift
│   │   └── Components/          # 首页专用组件

│   ├── Library/                 # 题库模块

│   │   ├── Views/
│   │   │   └── LibraryView.swift
│   │   └── Components/          # 题库专用组件

│   ├── Capture/                 # 拍照模块

│   │   ├── Views/
│   │   │   └── CaptureView.swift
│   │   └── Components/          # 拍照专用组件

│   ├── Discovery/               # 发现模块

│   │   ├── Views/
│   │   │   └── DiscoveryView.swift
│   │   └── Components/          # 发现专用组件

│   └── Profile/                 # 个人模块

│       ├── Views/
│       │   └── ProfileView.swift
│       └── Components/          # 个人专用组件

└── Shared/                # 共享资源

```

## 设计原则

### 1. 模块化分离

每个功能模块独立管理自己的视图和组件，避免耦合。

### 2. 层次清晰

- **Core**: 应用级别的核心视图
- **Features**: 按功能分组的模块化视图
- **Coordinators**: 导航逻辑管理
- **Shared**: 跨模块共享资源

### 3. 可扩展性

每个模块都有独立的 Views/ 和 Components/ 文件夹，便于未来扩展。

### 4. 架构一致性

与 Coordinator Pattern 和 Clean Architecture 保持一致。

## 使用指南

### 添加新视图

1. **功能视图**: 放入对应的 `Features/{Module}/Views/`
2. **核心视图**: 放入 `Core/Views/`
3. **组件**: 放入对应的 `Components/` 文件夹

### 添加新功能模块

1. 在 `Features/` 下创建新文件夹
2. 添加 `Views/` 和 `Components/` 子文件夹
3. 在 `Coordinators/` 中添加对应的协调器

### 重用原则

- 跨模块的共享组件放在 `Core/Components/`
- 模块特定的组件放在模块内的 `Components/`
- 通用资源放在 `Shared/`

## 迁移记录

**日期**: 2025年9月21日
**变更**: 从扁平化 `Views/` 文件夹重构为模块化架构
**影响**: 提高代码组织性和可维护性，支持更好的团队协作
