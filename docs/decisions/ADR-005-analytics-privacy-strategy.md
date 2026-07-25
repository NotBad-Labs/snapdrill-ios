---
last_verified: 2026-07-25
layer: architecture-decision
decision_id: ADR-005
status: accepted
decided_at: 2026-06-10
decay_trigger: [backend_telemetry_added, third_party_analytics_added, automatic_diagnostics_export_added]
---
# ADR-005: 生产环境无后端行为遥测，使用本地 MetricKit 诊断

## 背景（Context）

SnapDrill 的核心工作流不依赖开发者后端。当前工程不包含 Firebase 或其他第三方分析/崩溃 SDK；
App composition root 注入 `NoOpAnalyticsService`，既有 analytics 调用点不会在生产环境记录或
发送逐事件行为。设备崩溃、hang 和性能诊断由 `LiveMetricService` 接收 Apple MetricKit payload，
并写入有界的 App-private 本地目录。

需要保留的技术取舍是“是否建立开发者可访问的事件遥测管道”，不是决定市场指标、法律充分性
或某次发布的 App Store Connect 回答。

## 决策（Decision）

生产 App 不建立后端行为遥测管道，不链接第三方分析/崩溃 SDK；`AnalyticsServiceProtocol`
继续由 `NoOpAnalyticsService` 满足，以保持调用方边界而不产生网络副作用。

设备诊断使用 Apple MetricKit，并只在设备本地处理和持久化。任何自动上传、用户主动导出、
功能使用账本、用户自愿快照或远程 dashboard 都不属于本 ADR；是否进入某个 Release 必须重新
经过产品、隐私与 owning feature shaping。`analytics-events.md` 只记录当前未启用协议的词汇与
调用点，不能成为未来遥测方案或实现授权。

## 备选方案（Alternatives）

- **Firebase、PostHog 或自建逐事件后端**：拒绝。当前产品不需要该基础设施，且会新增身份、
  网络、隐私、区域和运维边界。
- **完全不保留诊断**：拒绝。崩溃、hang 和性能问题仍需要设备侧可复核证据。
- **第三方 crash-only SDK**：拒绝。MetricKit 已覆盖当前诊断目标，不需要新增供应商依赖。

## 后果（Consequences）

- analytics 调用在生产环境被明确丢弃，不能据此声称拥有功能使用数据；
- MetricKit 文件属于本地诊断数据，必须有界、可清理，并服从资料库清除/恢复的 owning contract；
- App Store Connect 平台聚合数据不是 App 内遥测实现，也不由本 ADR 定义；
- 未来若需要远程遥测，必须重新处理数据最小化、身份、同意、保留、区域、网络和发布声明。

## 验证与复议触发器（Validation）

- Package、Xcode project 和生产源码中不得出现 Firebase 或其他未批准分析 SDK；
- composition root 必须注入 `NoOpAnalyticsService`；
- MetricKit payload 只能进入 App-private 本地存储，不得存在自动网络发送路径；
- 新增后端 endpoint、第三方遥测 SDK、自动诊断上传或用户级事件身份时，本 ADR 立即进入复议。

## 关联权威（Related authorities）

- [Product Vision & Principles](../product/vision.md)：local-first、无开发者内容云和数据所有权；
- [Release 1 PRD](../product/release-1-prd.md)：当前发布范围与明确非目标；
- [Analytics Events](../reference/analytics-events.md)：当前未启用的事件词汇与调用点；
- [隐私与合规](../explanations/privacy-compliance.md)：公开隐私承诺与 legal-gated 内容；
- [Apple MetricKit](https://developer.apple.com/documentation/metrickit)：系统提供的设备诊断与性能报告。
