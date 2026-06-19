# ``SnapDrillFeatureSettings``

系统设置模块，管理通知、外观、隐私、数据同步和分类数据。

## 概述

`SnapDrillFeatureSettings` 提供应用全局配置入口：
通知时间、深色/浅色/跟随系统外观切换、隐私授权状态、数据清除，
以及学科/来源/级别分类的管理入口（复用 `SnapDrillFeatureLibrary` 的管理视图）。
还包含语言切换、存储管理、Multi-Profile 管理、开源许可和法律条款展示。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI` · `SnapDrillFeatureLibrary`

## 核心类型

### 视图

- ``SettingsView`` — 设置主页，分组列表入口

### 视图模型

- ``SettingsViewModel`` — 管理数据清除确认和统计信息

### 导航

- ``SettingsRouter`` — 管理设置内部页面导航

### 内部组件

设置下辖多个子页面：`EditProfileView`（Profile 编辑）、`ProfileListView`（Profile 列表）、
`NotificationSettingsView`（通知时间，由 `NotificationSettingsViewModel` 驱动）、
`ReviewAppearanceSettingsView`（回顾卡片外观）、App 主题切换（深色/浅色/跟随系统，内联在 `SettingsView` 中）、
`PrivacySettingsView`（本地诊断与数据导出说明）、
`DataAndSyncSettingsView`（数据清除与未来 CloudKit 同步）、
`LanguageSettingsView`（App 内语言切换）、`StorageManagementView`（缓存与存储空间管理）、
`LicenseView`（开源许可）、`PrivacyPolicyView` 和 `TermsOfServiceView`（法律条款）。
这些页面均为模块内部实现，不对外暴露。
