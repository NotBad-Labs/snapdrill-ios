# ``SnapDrillInfrastructure``

Firebase 基础设施实现层，封装 Analytics、Crashlytics（Remote Config 已移除，详见 README 与 #699 epic 隐私决策）。

## 概述

`SnapDrillInfrastructure` 持有所有 Firebase SDK 依赖，是唯一允许 import Firebase 的包。
仅 `SnapDrill/App`（组合根）可 import 本包；`SnapDrillCore`、`SnapDrillData`、`SnapDrillUI`
和所有 Feature 包均**禁止** import。

依赖方向：`SnapDrill/App` ──► `SnapDrillInfrastructure` ──► `SnapDrillCore`

> Warning: **当前状态（ADR-004 · 国内版 Firebase-Free）**：国内版生产**不调用** `FirebaseBootstrap.configure()`（组合根注入 `NoOpAnalyticsService`、`GoogleService-Info.plist` 已移出打包），运行时零 Firebase 初始化。下文「核心类型」描述的是 Firebase 激活态（未来海外版 / C 路径）设计，非国内版当前运行时行为。

## 核心类型

### 启动配置

- ``FirebaseBootstrap`` — 应用启动时调用 `FirebaseApp.configure()`，封装启动副作用

### Analytics

- ``FirebaseAnalyticsService`` — 遵循 `AnalyticsServiceProtocol`，将事件上报至 Firebase Analytics

### 崩溃监控

崩溃报告通过 `FirebaseBootstrap.setCrashlyticsEnabled(_:)` 控制开关，
无独立 Service 类（Crashlytics 由 Firebase SDK 直接管理）。

### 远程配置（已移除）

`FirebaseRemoteConfigService` 已因隐私决策（#699 epic）从代码库移除。
`SnapDrillCore` 中 `RemoteConfigurable` 协议保留作历史参考；当前无实现。
