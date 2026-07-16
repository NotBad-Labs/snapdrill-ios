# ``SnapDrillFeatureDashboard``

> 当前实现 API 参考。Dashboard 是 Release 1 默认首屏，但当前 Review hero、统计卡片和五 Tab
> 接线不能据此成为公开承诺。

首页看板模块，展示资料概览并提供快速操作入口。

## 概述

`SnapDrillFeatureDashboard` 是用户进入应用后看到的第一个界面：
当前实现以 Bento Grid 展示待回顾数量、资料总数和分类趋势，
并检测采集草稿、提供跨模块入口。最终可见卡片以 Dashboard feature spec 为准。

> 分类管理视图（分类/来源/阶段）已迁入 `SnapDrillFeatureLibrary`，
> Dashboard 仅通过依赖 Library 弹出 `CategoryManagerView`。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI` · `SnapDrillFeatureLibrary`

## 核心类型

### 视图

- ``DashboardView`` — 首页看板，Bento Grid 布局的资料概览

### 视图模型

- ``DashboardViewModel`` — 聚合统计数据（待回顾数、资料总数）、草稿检测

### 导航

- ``DashboardRouter`` — 管理首页跳转（含"前往回顾"和"前往采集+恢复草稿"跨模块回调）

### 内部组件

看板中的卡片由 `BentoCard`（通用容器）和 `ReviewHeroCard`（回顾进度英雄卡）组成，
均为模块内部实现。
