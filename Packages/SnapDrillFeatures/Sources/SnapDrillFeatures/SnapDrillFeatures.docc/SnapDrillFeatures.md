# ``SnapDrillFeatures``

所有产品功能的实现层，包含 View、ViewModel 和 Router。

## 概述

`SnapDrillFeatures` 是最上层的功能包，依赖 `SnapDrillCore`、`SnapDrillData`、`SnapDrillUI`。
每个功能模块遵循统一的目录结构：`<Feature>View.swift` + `<Feature>ViewModel.swift` + `<Feature>Router.swift`。

View 层通过 `@Environment(\.repositories)` 和 `@Environment(\.services)` 获取依赖，
不直接接触 `ModelContext`。

## 功能模块

### Dashboard（首页仪表盘）

- ``DashboardView`` — 展示复习进度概览和快捷入口
- ``DashboardViewModel`` — 加载统计数据，监听 `reviewDataDidChange` 通知
- ``SubjectManagerViewModel`` — 学科的增删改（含使用中校验）
- ``SourceManagerViewModel`` — 来源的增删改
- ``GradeManagerViewModel`` — 年级的增删改

### Capture（题目采集）

- ``CaptureViewModel`` — 协调相机扫描、相册选图、OCR 识别流程
- ``CaptureResultViewModel`` — 采集结果的预览与表单编辑，支持保存到数据库
- ``CaptureDraftServiceProtocol`` — 草稿服务协议
- `CaptureDraftService` — 草稿的磁盘持久化实现

### Library（题库）

- ``LibraryViewModel`` — 多维度过滤（搜索、学科、标签）和分页加载
- ``LibraryEditViewModel`` — 现有题目的编辑与保存，含图片替换和 OCR 重新识别

### Review（复习）

- `ReviewViewModel` — 复习会话状态机，调用 `ReviewScheduler` 计算 SM-2 调度

### Settings（设置）

- ``SettingsViewModel`` — 处理数据清除等设置操作

## 依赖注入

```swift
// 在 View 中访问 Repository
@Environment(\.repositories) private var repositories: RepositoryContainer

// 在 View 中访问服务
@Environment(\.services) private var services: any ServiceContainer
```

## 并发规范

所有 ViewModel 使用 `@Observable @MainActor final class`。
异步任务句柄保存为 `@ObservationIgnored private var xxxTask: Task<Void, Never>?`，
由 View 的 `.onDisappear` 调用 `cancelTasks()` 取消。
