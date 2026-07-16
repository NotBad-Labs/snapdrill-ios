# ``SnapDrillFeatureReview``

> 当前实现 API 参考。Release 1 public candidate 默认隐藏 Review；本页不能作为公开路由或
> 发布范围依据。

间隔回顾模块，基于 SM-2 算法驱动卡片式回顾会话。

## 概述

`SnapDrillFeatureReview` 实现完整的回顾会话状态机：
从资料库中取出到期资料，以卡片翻转形式呈现，
用户评分（Again / Hard / Good / Easy）后由 `ReviewScheduler` 计算下次回顾时间并写入持久化层。
回顾中可直接编辑资料（内嵌 `SnapDrillFeatureLibrary` 的 `LibraryEditView`）。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI` · `SnapDrillFeatureLibrary`

## 核心类型

### 视图

- ``ReviewView`` — 回顾会话主界面，管理卡片展示和进度

### 导航

- ``ReviewRouter`` — 管理回顾会话内的导航（含前往资料库的跨模块回调）

### 内部组件

回顾会话由 `ReviewViewModel` 状态机驱动（展示 → 翻转 → 评分 → 切换），
直接调用 `ReviewScheduler` 计算 SM-2 调度。
卡片正反面由 `ReviewCardFront` / `ReviewCardBack` 渲染，
滑动手势由 `SwipeCard` 容器承载，
评分按钮由 `ReviewActionButtons` 组件提供。
回顾统计看板 `ReviewDashboardView`、会话总结 `ReviewSessionSummaryView`
和空状态 `ReviewEmptyStateView` 均为模块内部实现。
