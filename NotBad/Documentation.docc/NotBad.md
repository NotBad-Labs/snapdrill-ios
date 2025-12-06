# ``NotBad``

错题本 iOS 应用 - 基于实用主义架构的 SwiftUI 实现

## Overview

NotBad 是一款帮助学生管理错题、进行间隔复习的 iOS 应用。采用 **实用主义架构**，使用 SwiftUI 和 SwiftData 构建。

### 核心功能

- 📝 **错题录入**: 拍照识别、手动输入
- 🔄 **间隔复习**: 艾宾浩斯算法智能安排复习
- 📊 **学习统计**: 掌握度分析、趋势图表
- 🏷️ **分类管理**: 按科目整理错题

### 架构特点

- **实用主义架构**: SwiftData 原生驱动，3 层结构
- **充血模型**: @Model 包含业务逻辑
- **Swift 6 并发**: 完全并发安全
- **图片分离存储**: FileManager + imagePath

## Topics

### 架构概述

- <doc:Architecture>

### 数据模型 (Models)

- ``ReviewItemModel``

### 服务层 (Services)

- ``ImageStorageService``

### 视图层 (Views)

- <doc:Views>
- ``ContentView``
- ``DashboardView``
- ``LibraryView``
- ``CaptureView``
- ``ReviewView``
- ``SettingsView``
