---
last_verified: 2026-05-28
layer: decision
freshness:
  max_age_days: 365
  decay_trigger: [decision_reverted, firebase_readded_to_cn, cpath_launch]
---
# ADR-004: 国内版 Firebase-Free（中国大陆 build 不含 Firebase）

> 状态：**已决策** | 日期：2026-05-28 | 决策者：PO | 关联：[[ADR-003]]
>
> **2026-06-11 状态说明**：本 ADR 的“中国 build 分流”是挂起路线的历史决策。#803 已从整个项目删除 `SnapDrillInfrastructure` 与 Firebase SDK，全球生产基线同样 Firebase-free；下文关于“海外版保留 Firebase”“编译层待剔除”已失效，仅保留决策演进记录。当前策略见 ADR-005 与根 `README.md`。

## 背景

[[ADR-003]] 定了"国内版无 Firebase"的方向。本 ADR 将其落实为可执行决策，并记录 2026-05-28 的实证现状（多源 PIPL 复核 + 律师简报 v2 驱动）。

### 当前实证状态（2026-05-28 核查，重要）

app 当前**捆绑** Firebase（Analytics + Crashlytics，隔离在 `SnapDrillInfrastructure`），但**默认不收集、不上报**，三层防御均已验证：

> ⚠️ 下表为 2026-05-28 interim 快照（plist 内禁用标志）。**当前（2026-05-29）已演进为完全移除**：`FirebaseBootstrap.configure()` 删除、`GoogleService-Info.plist` 移出 Copy Resources、注入 `NoOpAnalyticsService`，运行时零初始化/零出境（OSLog 实证）。编译层彻底剔除待 C 路径。

| 层 | 设置 | 出处 |
|---|---|---|
| Analytics 采集 | `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED = true` | `SnapDrill/App/GoogleService-Info.plist` |
| Crashlytics 采集 | `FirebaseCrashlyticsCollectionEnabled = false` | 同上 |
| 统一同意门 | `TelemetryGate` 默认 `.denied`（opt-in，显式授权才开）| `Packages/SnapDrillCore/.../TelemetryGate.swift` |

**残余风险（2026-05-28 评估，已于 2026-05-29 消除并验证）**：原风险为 opt-in 前 `FirebaseApp.configure()` + Installations 可能发 FID。当前 interim 止血已落地（见上），OSLog 实证首启未 opt-in 时零网络出境，无残余风险。编译层隔离（Release-CN 不链接 Firebase）待 C 路径。

## 决策

**中国大陆 build 不链接、不初始化 Firebase**（build-level removal），分析/崩溃改为：分析端侧或不做、崩溃用 Apple 原生 MetricKit / Xcode Organizer。

### 理由

- **PIPL 合规叙事 airtight**：Firebase 根本不在国内 build = FID 跨境问题不存在 = 无需单独同意/PIPIA/境外接收方告知（详见律师简报 `~/Desktop/snapdrill-data-compliance-briefing-v2.md`）
- 个人主体做跨境数据传输位置弱；国内主体未定前，最干净是无跨境
- 四方独立复核 + PO 直觉一致指向方案 A

### 海外版（未来，美国 LLC）

**保留 Firebase**，受 GDPR/CCPA 管辖，opt-in 披露。即 [[ADR-003]] 的区域差异。

## 实现

### 架构已隔离（改动面小）

- `AnalyticsServiceProtocol`（Core）+ `AnalyticsServiceMock`（Core，测试用）已存在
- Firebase 仅在 `SnapDrillInfrastructure`：`FirebaseBootstrap.swift` + `FirebaseAnalyticsService.swift`
- App 层装配点集中在 `DependencyContainer.swift`（私有 init）：现注入 `NoOpAnalyticsService()`、不调 `FirebaseApp.configure()`；`FirebaseBootstrap.configure()` / `FirebaseAnalyticsService()` / `syncTelemetryGate` 已归档至 `SnapDrillInfrastructure`（`FirebaseBootstrap.swift` / `FirebaseAnalyticsService.swift`），App 层不再引用

### 两级实现（执行 prompt 见 `~/Desktop/snapdrill-firebase-removal-prompt.md`）

1. **运行时止血（interim，半天）**：新增 `NoOpAnalyticsService`（Core，生产级空实现）；`DependencyContainer` 改用 NoOp + 不调 `FirebaseBootstrap.configure()`；移除 `GoogleService-Info.plist`。SDK 仍链接但永不初始化。
2. **编译层 airtight（baseline，随 C 路径）**：国内 build target 不链接 Firebase SDK（条件化 SPM 依赖 / Release-CN 配置），`FirebaseBootstrap`/`FirebaseAnalyticsService` 归档到仅海外 build 编译。

### 执行时机

当前**仅单一国内 build**（海外 Apple 账号未注册）。鉴于现状已 opt-in/默认关（低风险），不必紧急 churn：
- **TestFlight 阶段**：先抓包验证现状；若 opt-in 前零出境，现状即可内测
- **公开上架前**：执行 airtight 移除，最好随 C 路径（Release-CN/Global 拆分）一并做，避免移除后又为海外版加回

## 验证（DoD）

- **抓包**：真机/模拟器首启 + 未 opt-in，无 `googleapis.com` / `firebaseinstallations.googleapis.com` / `app-measurement.com` / `crashlytics` 请求
- `swiftlint --strict` 0 violations
- `xcodebuild build-for-testing -scheme AllTests` 0 errors
- 移除后 `grep -rn "import Firebase" Packages/ SnapDrill/` 仅剩海外隔离模块（或为空）

## 后果

- 国内版 PIPL 主义务收缩为：隐私政策合规 + 用户权利响应（"清空本地数据"）+ 安全保护义务 + 儿童特殊规则（详见律师简报 §8）
- 失去国内版第三方分析能力 —— 可接受（核心产品价值不依赖分析；未来要统计走境内方案如阿里云/腾讯云，数据不跨境）
- 保留 `AnalyticsServiceProtocol` 抽象 + 归档（不删）`FirebaseAnalyticsService`，便于 C 路径恢复海外版
