---
last_verified: 2026-07-15
layer: pattern
---
# SnapDrill Analytics 事件字典

> 上游依赖：`../explanations/assumptions.md`。Release 1 的结果级成功证据见
> [Release 1 PRD](../product/release-1-prd.md) 与 `../how-to/release-and-ci.md`。
> 本文件是 Analytics 事件的 SSOT。新增/修改事件必须同步本文档。
> 代码定义见 `AnalyticsEvent` 枚举（`Packages/SnapDrillCore/Sources/SnapDrillCore/Service/AnalyticsServiceProtocol.swift`）。

> **当前实现状态（2026-07-12，全球生产基线）**：Firebase SDK 与 `SnapDrillInfrastructure` 已由 #803 从项目删除；生产注入 `NoOpAnalyticsService`。下列事件仅作为 Core 协议、调用点和测试使用的历史事件词汇，不会在生产环境被记录或发送。端侧 MetricKit 是独立的设备诊断能力，不使用本事件字典，也不上传用户内容。当前策略见 ADR-005。

## 当前采集边界

- 全球生产版本不采集、不持久化、不发送本字典中的逐事件行为。
- 设置中的“匿名遥测”开关只保存本地 `TelemetryGate` 同意状态；当前生产服务仍为 NoOp，打开开关不会激活网络采集。
- Firebase 没有“海外版恢复”计划。任何后端分析方案都必须由 PO 新决策、独立 ADR、隐私披露和代码实证重新启用。
- App Store Connect 聚合指标与端侧 MetricKit 是当前可用信号；未来本地账本或用户自愿快照尚未实现。

## 候选学习信号（非 Release 验收）

> 本节于 2026-05-29 自 `../product/vision.md` 迁移（vision 瘦身重构：vision 只留 why，本类规格归本文档）。

这些信号帮助检验 assumptions，但不能替代
[Release 1 PRD](../product/release-1-prd.md)，也不能让 optional 功能自动成为 Must。

> ⚠️ 以下指标仅作为设计校准方向。生产版本没有逐事件数据源；涉及本字典事件的指标在实现隐私合规的本地账本或自愿快照前不可计算。当前使用 App Store Connect、用户访谈和 TestFlight 反馈。

| 信号 | 度量定义 | 数据来源 | 状态 |
|---|---|---|---|
| 首次录入效率（含 onboarding） | 从 App 冷启动到首次保存成功的时间中位数 | 可用性测试；事件口径：`app_launched` → `capture_saved` | 当前无生产事件数据源 |
| 首次录入效率（进入采集页后） | 从进入采集页到保存成功的时间中位数 | 可用性测试；事件口径：`camera_opened` → `capture_saved` | 当前无生产事件数据源 |
| 持续录入行为 | D7 仍有录入/管理/导出行为的用户占 D0 用户比例 | App Store Connect 聚合留存；事件口径仅供未来本地统计设计 | 待发布后观察 |
| 首个切口清晰度 | 不熟悉产品的成年人能否理解“结构化纸张 / PDF → 资料库 → 打印”用途 | 主持式任务、TestFlight 定性反馈；对应 H11 | 待首批用户验证 |
| 有机增长结构 | App Store 下载来源分布（Search / Browse / Referral / 外部） | App Store Connect（非 Analytics 事件） | 待发布后观察，不做预设比例 |
| 单资料库适配度 | 首批用户能否用分类、标签、过滤和搜索处理多主题资料 | 主持式任务、支持请求；对应 H12 | 待首批用户验证 |
| 成果分发 | 用户能导出或分享整理成果（通过系统分享菜单，非社交功能） | 可用性测试；系统分享 sheet 不产生 Analytics 事件 | 待发布后验证 |
| 价值链完成率 | 完成“采集 → 整理 / 找回 → 导出 / 打印”闭环 | 用户测试；`pdf_exported` 仅保留为历史 / 未来本地统计事件口径 | 当前无生产事件数据源 |

## 事件列表

### 会话生命周期

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `app_launched` | App 冷启动 | — | 留存计算、DAU/MAU |
| `session_started` | 用户进入前台 | — | 会话计数 |
| `session_ended` | 用户进入后台 | `duration_seconds` | 会话时长 |

### 采集

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `camera_opened` | 用户打开相机采集页 | — | 采集入口使用率 |
| `capture_saved` | 用户完成录入并保存 | `capture_method`（camera/photos/pdf/manual/clipboard/share_extension）, `category`, `has_answer`（true/false） | 录入成功率、采集方式分布 |
| `ocr_performed` | OCR 识别完成 | `ocr_language`（zh-Hans/en-US）, `character_count`, `ocr_duration_ms` | OCR 使用量和性能 |

### 管理

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `review_item_created` | 新题目保存成功 | `category`, `capture_method` | 录入量、内容结构 |
| `review_item_completed` | 题目编辑/补充完成 | `category` | 管理行为 |

### 复习

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `review_session_started` | 用户进入复习会话 | `due_count`（到期题目数） | 复习参与率 |
| `review_session_completed` | 复习会话结束 | `reviewed_count`, `remembered_count`, `session_duration_seconds` | 复习完成率和效果 |

### 导出与打印

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `pdf_exported` | PDF 导出完成 | `item_count`, `options`（with_answer/without_answer/with_lines/page_numbers） | 价值链完成率 |
| `data_exported` | JSON/CSV/`.snapdrillbackup` 备份导出 | `format`（json/csv/snapdrillbackup） | 数据可携带权使用率；生产 NoOp，不构成后端采集授权 |

### 屏幕浏览

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `screen_viewed` | 用户进入新屏幕 | `screen_name` | 功能使用分布 |

### 错误

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `error_occurred` | 可恢复错误发生 | `error_domain`, `error_code`, `screen_name` | 错误分布和频率 |

## 成功信号映射

vision 中定义的成功信号仍可使用本字典统一事件命名，但当前生产环境不会记录这些事件。下表是未来本地账本或自愿快照的计算口径，不是已上线的数据管线：

| 信号 | 依赖事件 | 计算方式 |
|---|---|---|
| 首次录入效率（含 onboarding） | `app_launched` → `capture_saved` | 时间差中位数 |
| 首次录入效率（采集页内） | `camera_opened` → `capture_saved` | 时间差中位数 |
| 持续录入行为 | `capture_saved` | D7 仍有该事件的用户 / D0 用户 |
| 激活深度 | `review_item_created` | D7 用户的题目数中位数 |
| 成果分发 | `pdf_exported` 或系统分享 | 事件发生率 |
| 价值链完成率 | `pdf_exported` 或系统打印 | D30 用户中至少触发 1 次的比例 |

## 相关文档

| 文档 | 关系 | 说明 |
|---|---|---|
| `../product/vision.md` | 上游 | 成功信号定义 |
| `feature-status.md` | 相关 | 功能使用事件对应 |

## 维护规则

1. 新增事件 → 先在本文件定义触发条件和参数，再在代码中实现
2. 修改事件名或参数 → 同时更新代码枚举和本文件
3. 废弃事件 → 标记退役日期，保留条目作墓碑（参照 F 规则退役惯例）
