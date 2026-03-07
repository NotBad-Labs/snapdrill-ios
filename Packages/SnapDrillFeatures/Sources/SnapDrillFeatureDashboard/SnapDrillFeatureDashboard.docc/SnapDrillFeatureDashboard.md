# ``SnapDrillFeatureDashboard``

首页看板模块，展示学习进度摘要并提供学科/来源/年级分类管理。

## 概述

`SnapDrillFeatureDashboard` 是用户进入应用后看到的第一个界面：
以 Bento Grid 布局展示今日待复习数量、总题目数和近期学习趋势，
检测并恢复意外退出时的采集草稿，快速跳转至复习或采集流程。

> 分类管理视图（学科/来源/年级）已迁入 `SnapDrillFeatureLibrary`。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI` · `SnapDrillFeatureLibrary`

## 核心类型

### 视图

- ``DashboardView`` — 首页看板，Bento Grid 布局的学习摘要

### 视图模型

- ``DashboardViewModel`` — 聚合统计数据（待复习数、总题数）、草稿检测

### 导航

- ``DashboardRouter`` — 管理首页跳转（含"前往复习"和"前往采集+恢复草稿"跨模块回调）

### UI 组件

- ``BentoCard`` — Bento 卡片容器，支持渐变背景和可选点击动作
- ``ReviewHeroCard`` — 复习进度英雄卡片
