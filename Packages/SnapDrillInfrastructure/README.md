# SnapDrillInfrastructure

**Firebase 基础设施实现层 (Firebase Infrastructure Implementation)**

`SnapDrillInfrastructure` 持有所有 Firebase SDK 依赖，封装 Analytics、Crashlytics 和 Remote Config。是唯一允许 `import Firebase` 的包。

依赖方向：`SnapDrill/App` ──► `SnapDrillInfrastructure` ──► `SnapDrillCore`

**隔离规则**：仅 `SnapDrill/App`（组合根）可 import 本包。`SnapDrillCore`、`SnapDrillData`、`SnapDrillUI` 和所有 Feature 包均禁止 import。

## 组成部分

### 启动配置
- **FirebaseBootstrap**: 应用启动时调用 `FirebaseApp.configure()`，封装启动副作用

### Analytics
- **FirebaseAnalyticsService**: 遵循 `AnalyticsServiceProtocol`（定义在 `SnapDrillCore`），将事件上报至 Firebase Analytics

### 崩溃监控
- 通过 `FirebaseBootstrap.setCrashlyticsEnabled(_:)` 控制开关，无独立 Service 类

### 远程配置
- **FirebaseRemoteConfigService**: 遵循 `RemoteConfigurable`（定义在 `SnapDrillCore`），拉取并激活远程参数

## 依赖
- `SnapDrillCore`: 引用协议定义和核心类型
- `FirebaseAnalytics` / `FirebaseCrashlytics` / `FirebaseRemoteConfig`: Firebase SDK

> 详细 API 参考见 DocC 文档：`SnapDrillInfrastructure.docc/SnapDrillInfrastructure.md`
