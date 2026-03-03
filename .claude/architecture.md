# SnapDrill 目标架构

> 本文件描述**重构完成后**的目标状态。当前代码库仍处于过渡中（含 SnapDrillDomain）。
> 重构进度见 `.claude/refactoring-plan.md`。

## 目标包结构（4 包）

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

SnapDrillUI      (→ Core)
  └─ 设计系统组件 / ImageCropper

SnapDrillFeatures (→ Core, Data, UI)
  └─ View（@Query 驱动，纯渲染）
  └─ ViewModel（@Observable @MainActor final class）

SnapDrill/App（薄壳组合根）
  └─ DependencyContainer（唯一单例）
  └─ AppRouter
```

## 模块依赖方向（严格单向）

```
SnapDrillFeatures ──► SnapDrillData ──► SnapDrillCore
        │                                     ▲
        └──────────► SnapDrillUI ─────────────┘
```

反向依赖禁止。SnapDrillCore 不得 import 任何本地包。

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

## Feature 结构（不变）

```
SnapDrillFeatures/Sources/SnapDrillFeatures/<FeatureName>/
  ├─ <Feature>View.swift
  ├─ <Feature>ViewModel.swift
  └─ <Feature>Router.swift（如有导航）
```

## 当前状态 vs 目标状态

| 指标 | 当前 | 目标 |
|---|---|---|
| SPM 包数 | 5（含 Domain） | 4 |
| Swift 文件数 | ~180 | ~120 |
| 协议数量 | ~15 | ~3（Service 层） |
| 新增字段改动文件数 | ~6 | ~2 |
| 跨 context 竞态风险 | 存在 | 消除（@Query 原生） |
