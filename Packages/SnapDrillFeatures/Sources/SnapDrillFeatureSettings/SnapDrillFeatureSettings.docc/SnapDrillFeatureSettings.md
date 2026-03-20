# ``SnapDrillFeatureSettings``

系统设置模块，管理通知、外观、隐私、数据同步和分类数据。

## 概述

`SnapDrillFeatureSettings` 提供应用全局配置入口：
通知时间、深色/浅色/跟随系统外观切换、隐私授权状态、数据清除，
以及学科/来源/年级分类的管理入口（复用 `SnapDrillFeatureLibrary` 的管理视图）。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI` · `SnapDrillFeatureLibrary`

## 核心类型

### 视图

- ``SettingsView`` — 设置主页，分组列表入口
- ``EditProfileView`` — 用户名和头像图标编辑
- ``NotificationSettingsView`` — 每日复习提醒时间配置
- ``ReviewAppearanceSettingsView`` — 复习卡片字体大小和布局偏好
- ``PrivacySettingsView`` — ATT 授权状态查看与重置入口
- ``DataAndSyncSettingsView`` — 数据清除和未来 CloudKit 同步配置

### 视图模型

- ``SettingsViewModel`` — 管理数据清除确认和统计信息
- ``NotificationSettingsViewModel`` — 管理通知权限请求和时间调度

### 导航

- ``SettingsRouter`` — 管理设置内部页面导航
