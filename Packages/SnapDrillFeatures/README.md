# SnapDrillFeatures

**功能模块集 (Feature Modules Collection)**

`SnapDrillFeatures` 包含 5 个**独立 SPM target**，编译器强制模块边界。每个 target 独立编译，禁止未声明的跨模块访问。

## 模块清单

### 1. SnapDrillFeatureCapture (采集)
- **职责**: 拍照扫描、相册导入、OCR 识别、手动录入、裁剪、连续录入。
- **关键入口**: `CaptureView`, `CaptureRouter`.

### 2. SnapDrillFeatureLibrary (题库)
- **职责**: 浏览、编辑、搜索、多维过滤、PDF 导出；分类管理（学科/来源/年级）。
- **关键入口**: `LibraryView`, `LibraryRouter`.

### 3. SnapDrillFeatureReview (复习)
- **职责**: 卡片翻转复习、滑动评分、SM-2 调度。
- **关键入口**: `ReviewView`, `ReviewRouter`.
- **依赖**: Library（LibraryEditView 嵌入复习卡）。

### 4. SnapDrillFeatureDashboard (仪表盘)
- **职责**: 首页概览、今日统计、待复习计数。
- **关键入口**: `DashboardView`, `DashboardRouter`.
- **依赖**: Library（SubjectManagerView）。

### 5. SnapDrillFeatureSettings (设置)
- **职责**: 录入字段配置、外观设置、数据同步、通知提醒、隐私导出。
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
