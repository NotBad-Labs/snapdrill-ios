# ``SnapDrillFeatureReview``

间隔重复复习模块，基于 SM-2 算法驱动卡片式复习会话。

## 概述

`SnapDrillFeatureReview` 实现完整的复习会话状态机：
从题库中取出当日到期题目，以卡片翻转形式呈现，
用户评分（Again / Hard / Good / Easy）后由 `ReviewScheduler` 计算下次复习时间并写入持久化层。
复习中可直接编辑题目（内嵌 `SnapDrillFeatureLibrary` 的 `LibraryEditView`）。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI` · `SnapDrillFeatureLibrary`

## 核心类型

### 视图

- ``ReviewView`` — 复习会话主界面，管理卡片展示和进度
- ``ReviewDashboardView`` — 今日复习统计看板
- ``ReviewCardContent`` — 卡片正背面内容渲染（含内嵌编辑入口）

### 视图模型

- ``ReviewViewModel`` — 复习会话状态机（展示 → 翻转 → 评分 → 切换），
  直接调用 `ReviewScheduler` 计算 SM-2 调度

### 导航

- ``ReviewRouter`` — 管理复习会话内的导航（含"前往题库"跨模块跳转回调）

### 卡片组件

- ``SwipeCard`` — 支持左右滑动手势的卡片容器
- ``ReviewActionButtons`` — Again / Hard / Good / Easy 评分按钮组
