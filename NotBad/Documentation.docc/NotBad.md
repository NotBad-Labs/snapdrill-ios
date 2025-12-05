# ``NotBad``

错题本 iOS 应用 - 基于 Clean Architecture 的 SwiftUI 实现

## Overview

NotBad 是一款帮助学生管理错题、进行间隔复习的 iOS 应用。采用 Clean Architecture 架构，使用 SwiftUI 和 SwiftData 构建。

### 核心功能

- 📝 **错题录入**: 拍照识别、手动输入
- 🔄 **间隔复习**: SM-2 算法智能安排复习
- 📊 **学习统计**: 掌握度分析、趋势图表
- 🏷️ **分类管理**: 按科目整理错题

### 架构特点

- **Clean Architecture**: 分层设计，职责清晰
- **Swift 6 并发**: 完全并发安全
- **SwiftData**: 现代化数据持久层
- **依赖注入**: DI Factory 模式

## Topics

### 架构概述

- <doc:Architecture>
- <doc:CleanArchitecture>
- <doc:DependencyInjection>

### 领域层 (Domain)

- ``ReviewItem``
- ``Subject``
- ``MasteryLevel``
- ``ReviewItemRepository``

### 应用层 (Application)

- <doc:UseCases>
- ``CreateReviewItemUseCase``
- ``FetchReviewItemsUseCase``
- ``RecordReviewResultUseCase``
- ``GetStatisticsUseCase``

### 数据层 (Data)

- ``SwiftDataReviewItemRepository``
- ``SwiftDataSubjectRepository``

### 基础设施层 (Infrastructure)

- ``DependencyFactory``
- ``ProductionDependencyFactory``
- ``TestDependencyFactory``

### 表现层 (Presentation)

- <doc:ViewModels>
- <doc:Views>
