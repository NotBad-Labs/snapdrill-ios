# SnapDrill 架构（2026-03-07 最终状态）

> **上游依赖**：`principles.md`（工程哲学、包边界原则、DI 原则）
> **下游影响**：`infrastructure.md`（API 清单须与架构一致）

## 包结构（5 包）

```
SnapDrillCore    (0 deps)
  └─ SM-2 调度器（ReviewScheduler）
  └─ OCR / ImageStorage / Logger
  └─ ReviewDataNotification
  └─ Difficulty / ReviewRating enums

SnapDrillData    (→ Core)
  └─ @Model 类（直接作领域对象，无映射层）
  └─ 具体 Repository 类（无协议）
  └─ PersistenceController / 迁移计划
  └─ ReviewExportSnapshot（导出专用 Sendable 快照）

SnapDrillUI      (→ Core)
  └─ 设计系统组件 / ImageCropper

SnapDrillFeatures（5 个独立 target）
  SnapDrillFeatureCapture   (→ Core, Data, UI)
  SnapDrillFeatureLibrary   (→ Core, Data, UI)  ← 含分类管理（Subject/Source/Grade）
  SnapDrillFeatureReview    (→ Core, Data, UI, Library)
  SnapDrillFeatureDashboard (→ Core, Data, UI, Library)
  SnapDrillFeatureSettings  (→ Core, Data, UI, Library)

SnapDrillInfrastructure (→ Core; 仅 SnapDrill/App 可 import)
  └─ Firebase 全部实现（Analytics / Crashlytics / RemoteConfig）
  └─ FirebaseBootstrap

SnapDrill/App（薄壳组合根）
  └─ DependencyContainer（唯一单例）
  └─ AppRouter
```

## 模块依赖方向（严格单向）

```
SnapDrillFeatures ──► SnapDrillData ──► SnapDrillCore
        │                                     ▲
        └──────────► SnapDrillUI ─────────────┘

SnapDrill/App ──► SnapDrillInfrastructure ──► SnapDrillCore
```

反向依赖禁止。SnapDrillCore 不得 import 任何本地包。
SnapDrillInfrastructure 只能被 SnapDrill/App 直接依赖，Features/Data/UI/Core 均禁止 import。

## 数据流

```
@Query（SwiftUI）
  └─ 驱动 View 自动刷新（无需 NotificationCenter）

ViewModel
  └─ 注入具体 Repository（非协议）
  └─ 调用 ReviewScheduler（Core）计算 SM-2 调度
  └─ 直接写入 ModelContext（通过 Repository）

View
  └─ 只读 ViewModel 状态，转发用户事件
  └─ 不直接接触 ModelContext
```

## DI 链路

```
DependencyContainer（@MainActor 单例）
  ├─ LiveServiceContainer  → .environment(\.services)
  ├─ RepositoryContainer   → .environment(\.repositories)
  └─ AppRouter
```

`DefaultUseCaseContainer` 已删除。`\.useCases` Environment key 已删除。

## Feature 结构

```
SnapDrillFeatures/Sources/SnapDrillFeature<Name>/
  ├─ <Feature>View.swift
  ├─ <Feature>ViewModel.swift
  └─ <Feature>Router.swift（如有导航）
```

## 关键设计决策

| 决策 | 结论 |
|---|---|
| Domain 层 | **已删除**（2026-03-03）。@Model 直接作领域对象 |
| UseCase 层 | **已删除**（2026-03-03）。ViewModel 直接调 Repository |
| Repository 协议 | **已删除**。具体类直接使用，测试用 in-memory ModelContainer |
| Export DTO | `ReviewExportSnapshot`（6字段 Sendable struct），桥接 @Model → Transferable |
| 列表驱动 | @Query（LibraryView 等），Repository.fetch（ReviewViewModel 状态机）|

## Feature 间依赖（2026-03-07 精化）

```
SnapDrillFeatureCapture   ──► Core, Data, UI
SnapDrillFeatureLibrary   ──► Core, Data, UI
SnapDrillFeatureReview    ──► Core, Data, UI, Library（LibraryEditView 嵌入复习卡）
SnapDrillFeatureDashboard ──► Core, Data, UI, Library（SubjectManagerView）
SnapDrillFeatureSettings  ──► Core, Data, UI, Library（SubjectManager / SourceManager / GradeManager）
```

分类管理视图（SubjectManagerView 等）语义归属 Library（题目元数据 CRUD），
不属 Dashboard（统计看板）。Settings 直接依赖 Library，无需经由 Dashboard。

## 验证结果（2026-03-07）

| 指标 | 值 |
|---|---|
| SPM 包数 | 5 |
| Swift 文件数 | 157 |
| SnapDrillCore swift test | 24/24 ✅（无 Firebase 依赖）|
| SnapDrillData swift test | 非 Predicate 测试全部通过 ✅ |
| xcodebuild build | BUILD SUCCEEDED ✅ |
| swiftlint | 0 violations ✅ |
