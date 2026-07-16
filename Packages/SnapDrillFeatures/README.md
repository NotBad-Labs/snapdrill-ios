# SnapDrillFeatures

> **文档角色：当前实现参考。** 下列 targets 与入口说明代码现在是什么，不代表每个模块都有
> Release 1 公开路由；公开范围以 Release Contract 与 owning feature spec 为准。

**功能模块集 (Feature Modules Collection)**

`SnapDrillFeatures` 包含 5 个**独立 SPM target**，编译器强制模块边界。每个 target 独立编译，禁止未声明的跨模块访问。

## 模块清单

### 1. SnapDrillFeatureCapture (采集)
- **职责**: 拍照扫描、相册导入、剪贴板文本导入、PDF 导入、OCR 识别、手动录入、裁剪、连续录入。
- **关键入口**: `CaptureView`, `CaptureRouter`.

### 2. SnapDrillFeatureLibrary (资料库)
- **职责**: 浏览、编辑、搜索、多维过滤、PDF 导出；分类管理（分类/来源/级别/标签）。
- **关键入口**: `LibraryView`, `LibraryRouter`.

### 3. SnapDrillFeatureReview (回顾，当前公开路由待收敛)
- **职责**: 卡片翻转回顾、滑动评分、SM-2 调度。
- **关键入口**: `ReviewView`, `ReviewRouter`.
- **依赖**: Library（LibraryEditView 嵌入回顾卡）。

### 4. SnapDrillFeatureDashboard (Dashboard)
- **职责**: 首页概览、今日统计和任务入口；旧 Review hero / analytics 路径是实现事实。
- **关键入口**: `DashboardView`, `DashboardRouter`.
- **依赖**: Library（CategoryManagerView）。

### 5. SnapDrillFeatureSettings (设置)
- **职责**: 录入字段配置、外观设置、数据管理、通知提醒和隐私信息；Profile / CloudKit 入口是待收敛实现。
- **关键入口**: `SettingsView`, `SettingsRouter`.
- **依赖**: Library（分类管理视图）。

## 模块间依赖

```
SnapDrillFeatureCapture   ──► Core, Data, UI
SnapDrillFeatureLibrary   ──► Core, Data, UI
SnapDrillFeatureReview    ──► Core, Data, UI, Library
SnapDrillFeatureDashboard ──► Core, Data, UI, Library
SnapDrillFeatureSettings  ──► Core, Data, UI, Library
```
