---
last_verified: 2026-05-09
layer: pattern
---
# SnapDrill Analytics 事件字典

> 上游依赖：`product-vision.md`§成功信号。
> 本文件是 Analytics 事件的 SSOT。新增/修改事件必须同步本文档。
> 代码定义见 `AnalyticsEvent` 枚举（`Packages/SnapDrillCore/Sources/SnapDrillCore/Service/AnalyticsServiceProtocol.swift`）。

## 采集说明

- 所有事件默认不采集（Analytics opt-in）
- 用户可在设置中独立开启/关闭 Analytics 和 Crashlytics
- opt-in 后数据发送到 Firebase Analytics（Google 服务器）
- 样本偏差：数据仅覆盖主动 opt-in 的用户，不代表全体用户

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
| `capture_saved` | 用户完成录入并保存 | `capture_method`（camera/photos/pdf/manual/clipboard/share_extension）, `subject`, `difficulty`, `has_answer`（true/false） | 录入成功率、采集方式分布 |
| `ocr_performed` | OCR 识别完成 | `ocr_language`（zh-Hans/en-US）, `character_count`, `ocr_duration_ms` | OCR 使用量和性能 |

### 管理

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `review_item_created` | 新题目保存成功 | `subject`, `difficulty`, `capture_method` | 录入量、内容结构 |
| `review_item_completed` | 题目编辑/补充完成 | `subject` | 管理行为 |

### 复习

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `review_session_started` | 用户进入复习会话 | `due_count`（到期题目数） | 复习参与率 |
| `review_session_completed` | 复习会话结束 | `reviewed_count`, `remembered_count`, `session_duration_seconds` | 复习完成率和效果 |

### 导出与打印

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `pdf_exported` | PDF 导出完成 | `item_count`, `options`（with_answer/without_answer/with_lines/page_numbers） | 价值链完成率 |
| `data_exported` | JSON/CSV/.zip 备份导出 | `format`（json/csv/zip） | 数据可携带权使用率 |

### 屏幕浏览

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `screen_viewed` | 用户进入新屏幕 | `screen_name` | 功能使用分布 |

### 错误

| 事件名 | 触发条件 | 参数 | 用途 |
|---|---|---|---|
| `error_occurred` | 可恢复错误发生 | `error_domain`, `error_code`, `screen_name` | 错误分布和频率 |

## 成功信号映射

vision 中定义的 8 个成功信号中，**6 个由本字典事件支撑，2 个为非事件来源**（有机增长来自 App Store Connect、Multi-Profile 可用性来自定性验证 + 自动化测试）。事件对应关系：

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
| `product-vision.md` | 上游 | 成功信号定义 |
| `product-requirements.md` | 相关 | 功能使用事件对应 |

## 维护规则

1. 新增事件 → 先在本文件定义触发条件和参数，再在代码中实现
2. 修改事件名或参数 → 同时更新代码枚举和本文件
3. 废弃事件 → 标记退役日期，保留条目作墓碑（参照 F 规则退役惯例）
