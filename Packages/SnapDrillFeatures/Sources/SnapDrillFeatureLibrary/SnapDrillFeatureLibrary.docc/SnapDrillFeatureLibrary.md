# ``SnapDrillFeatureLibrary``

> 当前实现 API 参考；公开工具栏、批量能力和 SmartPaper 可达性由 Release Contract 与
> Library feature spec 决定。

资料库浏览与管理模块，支持搜索、过滤、编辑和导出。

## 概述

`SnapDrillFeatureLibrary` 提供资料的全生命周期管理界面：
列表浏览（支持多维过滤）、详情查看、内容编辑、批量打标签和 PDF 导出。
`LibraryEditView` 同时被 `SnapDrillFeatureReview` 复用，用于回顾中直接编辑资料。

依赖：`SnapDrillCore` · `SnapDrillData` · `SnapDrillUI`

## 核心类型

### 视图

- ``LibraryView`` — 资料库主页，含搜索栏和过滤入口
- ``LibraryEditView`` — 资料编辑表单（`public`，供 Review 模块复用）
- ``CategoryManagerView`` — 分类维度管理（新增、重命名、删除，`public`，供 Settings/Dashboard 复用）
- ``CategoryValueListView`` — 单个维度的值管理
- ``SFSymbolPickerView`` — SF Symbol 图标选择器（`public`，供分类管理复用）

### 视图模型

- ``LibraryViewModel`` — 管理搜索文字、过滤条件和分页加载
- ``LibraryEditViewModel`` — 管理资料字段编辑和保存
- ``CategoryManagerViewModel`` — 管理维度增删改
- ``CategoryValueListViewModel`` — 管理维度值增删改及级联更新 `ArchiveItemModel`

### 导航

- ``LibraryRouter`` — 管理列表 → 详情 → 编辑的导航路径

### 内部组件

列表展示由 `LibraryListView`（`@Query` 驱动响应式更新）和 `LibraryDetailView`（单份资料详情）组成；
过滤面板 `LibraryFilterSheet` 支持按分类、来源、级别、标签多维过滤；
导出功能通过 `ExportOptionsSheet`（选项配置）和 `ExportPreviewView`（PDF 预览）实现；
批量操作通过 `BatchTagSheet`（批量打标签）完成。
这些组件为模块内部实现，不对外暴露。
