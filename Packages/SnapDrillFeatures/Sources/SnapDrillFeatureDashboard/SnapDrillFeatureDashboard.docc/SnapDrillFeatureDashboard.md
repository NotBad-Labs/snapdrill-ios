# ``SnapDrillFeatureDashboard``

首页看板模块，展示学习进度摘要并提供学科/来源/年级分类管理。

## 概述

`SnapDrillFeatureDashboard` 是用户进入应用后看到的第一个界面：
以 Bento Grid 布局展示今日待复习数量、总题目数和近期学习趋势，
检测并恢复意外退出时的采集草稿，快速跳转至复习或采集流程。
分类管理视图（`SubjectManagerView` 等）被 `SnapDrillFeatureSettings` 复用。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI`

## 核心类型

### 视图

- ``DashboardView`` — 首页看板，Bento Grid 布局的学习摘要
- ``SubjectManagerView`` — 学科管理（新增、重命名、删除，`public`，供 Settings 复用）
- ``SourceManagerView`` — 来源管理（`public`，供 Settings 复用）
- ``GradeManagerView`` — 年级管理（`public`，供 Settings 复用）
- ``SFSymbolPickerView`` — SF Symbol 图标选择器（`public`，供 Settings 复用）

### 视图模型

- ``DashboardViewModel`` — 聚合统计数据（待复习数、总题数）、草稿检测
- ``SubjectManagerViewModel`` — 学科增删改及级联更新 `ReviewItemModel`
- ``SourceManagerViewModel`` — 来源增删改及级联更新
- ``GradeManagerViewModel`` — 年级增删改及级联更新

### 导航

- ``DashboardRouter`` — 管理首页跳转（含"前往复习"和"前往采集+恢复草稿"跨模块回调）

### UI 组件

- ``BentoCard`` — Bento 卡片容器，支持渐变背景和可选点击动作
- ``ReviewHeroCard`` — 复习进度英雄卡片
