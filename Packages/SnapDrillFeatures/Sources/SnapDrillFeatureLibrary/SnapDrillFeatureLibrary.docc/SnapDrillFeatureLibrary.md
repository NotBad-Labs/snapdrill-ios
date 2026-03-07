# ``SnapDrillFeatureLibrary``

题库浏览与管理模块，支持搜索、过滤、编辑和导出。

## 概述

`SnapDrillFeatureLibrary` 提供题目的全生命周期管理界面：
列表浏览（支持多维过滤）、详情查看、内容编辑和 PDF 导出。
`LibraryEditView` 同时被 `SnapDrillFeatureReview` 复用，用于复习中直接编辑题目。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI`

## 核心类型

### 视图

- ``LibraryView`` — 题库主页，含搜索栏和过滤入口
- ``LibraryListView`` — 题目列表（`@Query` 驱动响应式更新）
- ``LibraryDetailView`` — 单题详情展示
- ``LibraryEditView`` — 题目编辑表单（`public`，供 Review 模块复用）
- ``LibraryFilterSheet`` — 按学科、来源、标签多维过滤
- ``ExportPreviewView`` — PDF 导出预览
- ``SubjectManagerView`` — 学科管理（新增、重命名、删除，`public`，供 Settings/Dashboard 复用）
- ``SourceManagerView`` — 来源管理（`public`，供 Settings/Dashboard 复用）
- ``GradeManagerView`` — 年级管理（`public`，供 Settings/Dashboard 复用）
- ``SFSymbolPickerView`` — SF Symbol 图标选择器（`public`，供分类管理复用）

### 视图模型

- ``LibraryViewModel`` — 管理搜索文字、过滤条件和分页加载
- ``LibraryEditViewModel`` — 管理单题字段编辑和保存
- ``SubjectManagerViewModel`` — 学科增删改及级联更新 `ReviewItemModel`
- ``SourceManagerViewModel`` — 来源增删改及级联更新
- ``GradeManagerViewModel`` — 年级增删改及级联更新

### 导航

- ``LibraryRouter`` — 管理列表 → 详情 → 编辑的导航路径
