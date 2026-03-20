# ``SnapDrillInfrastructure``

Firebase 基础设施实现层，封装 Analytics、Crashlytics 和 Remote Config。

## 概述

`SnapDrillInfrastructure` 持有所有 Firebase SDK 依赖，是唯一允许 import Firebase 的包。
仅 `SnapDrill/App`（组合根）可 import 本包；`SnapDrillCore`、`SnapDrillData`、`SnapDrillUI`
和所有 Feature 包均**禁止** import。

依赖方向：`SnapDrill/App` ──► `SnapDrillInfrastructure` ──► `SnapDrillCore`

## 核心类型

### 启动配置

- ``FirebaseBootstrap`` — 应用启动时调用 `FirebaseApp.configure()`，封装启动副作用

### Analytics

- ``FirebaseAnalyticsService`` — 遵循 `AnalyticsServiceProtocol`，将事件上报至 Firebase Analytics

### 崩溃监控

崩溃报告通过 `FirebaseBootstrap.setCrashlyticsEnabled(_:)` 控制开关，
无独立 Service 类（Crashlytics 由 Firebase SDK 直接管理）。

### 远程配置

- ``FirebaseRemoteConfigService`` — 遵循 `RemoteConfigurable`（定义在 `SnapDrillCore`），
  拉取并激活远程参数，驱动 `AppConfiguration.FeatureFlags`（包括 Emergency Kill Switch）
