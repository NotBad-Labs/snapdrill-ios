---
last_verified: 2026-07-25
layer: implementation-evidence
freshness:
  max_age_days: 30
  decay_trigger: [analytics_api_change, analytics_callsite_change, privacy_strategy_change]
---
# Analytics 协议实证

> **文档角色：当前实现实证，不是产品、隐私或未来遥测方案的权威。**
> [ADR-005](../decisions/ADR-005-analytics-privacy-strategy.md) 决定当前分析与诊断策略，
> [Release 1 PRD](../product/release-1-prd.md) 决定结果级验收，
> `AnalyticsServiceProtocol.swift` 是编译期 API 的代码事实。

## 当前边界

- 全球生产组合根注入 `NoOpAnalyticsService`；下列调用不会记录、持久化或发送事件。
- `TelemetryGate` 只保存本地同意状态，打开它不会把 NoOp 服务变成网络采集实现。
- Apple MetricKit 是独立的设备诊断能力，不使用本协议，也不上传用户内容。
- App Store Connect 聚合指标、可用性测试和 TestFlight 反馈不由本文件定义。
- 自动上传、用户主动导出诊断、功能使用账本、自愿快照或远程 dashboard 都需要新的产品、
  隐私与 owning feature shaping；不得从本事件列表取得实现授权。

## 当前协议与调用点

事件枚举位于
`Packages/SnapDrillCore/Sources/SnapDrillCore/Service/AnalyticsServiceProtocol.swift`。
“调用点”表示 live source 会调用当前 NoOp 服务，不表示生产环境产生了事件数据。

| 事件 | Live source 调用点 | 当前参数 |
|---|---|---|
| `app_launched` | `SnapDrillApp` 冷启动任务 | `version` |
| `review_item_created` | `CaptureResultViewModel` 保存成功 | `has_image`, `has_content` |
| `review_item_completed` | `ReviewViewModel` 评分持久化成功 | `rating` |
| `review_session_started` | `ReviewViewModel.startSession()` | `queue_size` |
| `review_session_completed` | `ReviewViewModel` 队列完成 | `total`, `good`, `again` |
| `camera_opened` | `CaptureView` 打开相机路径 | 无 |
| `capture_saved` | `CaptureResultViewModel` 保存成功 | `category`, `source` |
| `pdf_exported` | `ExportPreviewView` PDF 临时文件准备成功 | `item_count` |
| `data_exported` | `PrivacySettingsViewModel` 数据导出完成 | `format`, `item_count` |
| `screen_viewed` | 无 live 调用点 | — |
| `session_started`, `session_ended` | 无直接枚举调用；`SnapDrillApp` 改用 `startSession()` / `endSession()` 协议方法 | — |
| `ocr_performed`, `error_occurred` | 无 live 调用点 | — |

协议还声明 `trackScreen`、`setUserProperty` 和 `trackRetention`；当前生产 source 没有调用点。
测试可注入 `AnalyticsServiceMock` 检查调用方行为，但 mock 记录不能证明生产采集。

## 维护规则

1. 修改 `AnalyticsEvent`、协议方法、live 调用点或参数时，同步更新本表并刷新 `last_verified`。
2. 修改生产实现、隐私边界或诊断策略时，先更新 owning ADR / 产品与隐私契约，再更新本实证。
3. 不在本文件定义成功指标、未来数据源、发布范围或遥测路线；这些内容分别归 Release PRD、
   assumptions、owning feature spec 与新的已批准策略。
