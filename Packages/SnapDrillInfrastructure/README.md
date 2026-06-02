# SnapDrillInfrastructure

**Firebase 基础设施实现层 (Firebase Infrastructure Implementation)**

`SnapDrillInfrastructure` 持有所有 Firebase SDK 依赖，封装 Analytics、Crashlytics（Remote Config 已移除——决策来源：#699 epic 隐私决策；ADR-002 是相邻的 ATT 移除决策）。是唯一允许 `import Firebase` 的包。

> ⚠️ **当前状态（ADR-004 · 国内版 Firebase-Free）**：本包代码保留，但**国内版生产不调用 `FirebaseBootstrap.configure()`**——组合根 `DependencyContainer` 注入 `NoOpAnalyticsService`，`GoogleService-Info.plist` 已移出打包，运行时零 Firebase 初始化（OSLog 抓包实证零出境）。下文「启动配置 / Analytics」描述的是 **Firebase 激活态（未来海外版 / C 路径恢复时）** 的设计，**非国内版当前运行时行为**。Firebase SDK 编译层彻底剔除待 C 路径（见 `../../docs/explanations/development-process.md` §5 RC-1）。

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
- **已移除**：原 `FirebaseRemoteConfigService` 因隐私决策不再使用（用户无网络/纯本地工具定位），仅保留代码注释作为历史

## 依赖
- `SnapDrillCore`: 引用协议定义和核心类型
- `FirebaseCore` / `FirebaseAnalytics` / `FirebaseCrashlytics`: Firebase SDK（RemoteConfig 已移除）

> 详细 API 参考见 DocC 文档：`SnapDrillInfrastructure.docc/SnapDrillInfrastructure.md`
