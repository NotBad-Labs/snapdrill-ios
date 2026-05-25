---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# 语义层维度 4 — 三方对抗共识报告（技术↔产品对齐）

> **日期**：2026-05-21 | **维度**：4 技术↔产品对齐（tech/* 决策是否真服务「采集 → 管理 → 导出」价值链）| **三方**：Claude CLI / Codex 桌面端 / Antigravity (Gemini 3.5 Flash (High))
>
> **方法**：F-008「相同完整任务、不分工」，三家独立审 docs/tech/* + 代码（Packages/SnapDrillCore + SnapDrillData）。[[cross-audit-consensus]] 折结果。
>
> 单家原始报告：
> - Claude CLI：本会话上下文 (2 finding，C4.1 + C4.2)
> - Codex 桌面端：本会话上下文 (7 finding，D4-001 ~ D4-007，无文件写入)
> - Antigravity：[`semantic-audit-dim4-findings.md`](semantic-audit-dim4-findings.md) (5 finding，F-D4-001 ~ F-D4-005)
>
> 共识 ledger：[`audit-ledger-semantic-2026-05.tsv`](audit-ledger-semantic-2026-05.tsv) S-D4-001 ~ S-D4-011

## 三家分布对比

| 项目 | Claude | Codex | Antigravity |
|---|---|---|---|
| 总 finding 数 | 2 | 7 | 5 |
| HIGH | 1 | 0 | 2 |
| MEDIUM | 1 | 3 | 2 |
| LOW | 0 | 4 | 1 |
| 工作流违规 | — | — | ❌ 无（守规矩，「严禁操作」段生效）|

**形态对比**：
- **Claude CLI** 偏「元规则 + 系统视角」（ServiceContainer 协议系统性退化 / 决策表 claim 兑现）
- **Antigravity** 偏「代码层 grep 真 bug」（通知 ID 物理覆盖 / ProEntitlementProvider 硬编码）
- **Codex** 偏「文档 vs 实现 + 跨文件追踪」（badge 三层背离 / DataExecutor 降级路径 / ZIP 流式过度表述 / Xcode 版本不一致 / compliance 跨 agent 边界）

互补性极强。**Codex 是这一轮最强单家**——7 项里 5 项是 Claude/Antigravity 都漏的真问题。

## 折叠总览

| 共识等级 | 数量 | 严重度分布 |
|---|---|---|
| **3/3 全共识** | 1 | HIGH×1 |
| **2/3 共识** | 0 | — |
| **1/3 单家可采纳** | 10 | HIGH×2 MEDIUM×4 LOW×4 |
| **合计 OPEN** | **11** | HIGH×3 MEDIUM×4 LOW×4 |

## 3/3 全共识

### S-D4-001 [HIGH, 3/3 同域] — DI/架构归属系统性退化

**最大的根本问题**。三家从四个角度同域命中：

- **Claude C4.1 (HIGH 系统视角)**：ServiceContainer 协议只列 5 个 Service（analytics/pdfExport/appConfig/privacyConsent/notification），但 `SnapDrillCore/Service/` 实际有 12+ 个 Service。7+ 个绕过 DI：CaptureDraftService / DeletionScheduler / PrivacyConsentService 内部 / ProEntitlementProvider / ContentTaggingService / QuestionSplittingService / OCRService / AppActivityTracker
- **Antigravity F-D4-001 (HIGH 症状)**：ProEntitlementProvider 硬编码 = DefaultProEntitlementProvider() 默认参数（DashboardAnalyticsViewModel:82 + SmartPaperView:34）
- **Antigravity F-D4-004 (MEDIUM 症状)**：CaptureDraftService.shared 在 CaptureViewModel / DashboardViewModel 绕过 DI
- **Codex D4-005 (LOW 角度)**：ProEntitlementProvider / TelemetryGate / ZIPArchiver 未入 architecture §模块职责表

**修复路径**：
1. ServiceContainer 协议扩展到全部 Service
2. 或写 ADR 显式解释为什么这些 Service 不入 DI
3. architecture §模块职责表补 Service 归属（与维度 1 S-D1-006 ContentTaggingService 联动）

## 1/3 单家可采纳（真 bug + 真漂移）

### S-D4-002 [HIGH, 1/3 Antigravity] — 通知 ID 全局硬编码物理覆盖

`LiveNotificationService.swift:54` `identifier: "com.snapdrill.daily-review"` 全局单一 ID + `:41` `cancelAll()`。**Multi-Profile 在 iOS 系统通知层物理失效**——切换 Profile 会擦除其他孩子的提醒。违反 Vision §细分群体「多孩家庭 Multi-Profile 是刚需」承诺。**真生产 bug**。

修复：identifier 拼接 profileId（`com.snapdrill.daily-review.\(profileId)`）；移除全局 cancelAll() 改为 scope 级清理。

### S-D4-003 [HIGH, 1/3 Codex] — badge 实现 vs 产品规格三层背离

Codex 原标 MEDIUM，**共识提级 HIGH**——构成「规格-实现-发布」三层背离：

- `product-requirements.md:178` 明文「不使用角标，仅使用本地通知提醒（决策依据：vision P2 不贩卖焦虑）」
- `LiveNotificationService.swift:30` 请求 `.badge` 权限
- `NotificationSettingsView.swift:25/65` 有 `badgeEnabled` Toggle，**默认 true**
- `deployment.md:237` 发布清单要求「角标开关均有效」

修复：删除 badge 权限 + 设置 Toggle + L10n + deployment 清单项；或写 ADR 明确产品规格豁免。

### S-D4-004 [MEDIUM, 1/3 Antigravity] — DataExecutor 文档/实现漂移

`architecture.md` 暗示 Repository CRUD 在后台 actor 上执行（"DataExecutor actor 拥有 ModelContainer 消除 MainActor+XPC 死锁 #599"），但代码 Repository 直接拿 `mainContext` 在 MainActor 同步读写。

修复：architecture.md 修正数据流图示；many-to-many 内存过滤补防 UI 卡顿设计。

### S-D4-005 [MEDIUM, 1/3 Codex] — DataExecutor 降级模式无 fail-closed

`DataExecutor.swift:80/118` 持久化容器初始化失败时降级到内存模式。UI 仅 `AppRootView.swift:94` 横幅 + L10n 提示「重启后丢失」。但仍允许用户继续写入，**违反 Vision P4「保存必须可靠」**——没有 fail-closed / read-only / recovery 路径，也没 ADR 解释。

修复：补 ADR 或 NFR——降级模式是否允许采集；若允许，定义导出/迁移路径；若不允许，应阻断保存。

### S-D4-006 [MEDIUM, 1/3 Claude] — 架构决策表 claim 不兑现

`architecture.md:195` 关键设计决策表写「Protocol-based DI + @Environment | 替换实现只需改 DependencyContainer，Feature 层不感知」。实际 Feature 层大量 `.shared` 单例 + 硬编码默认参数。元规则层 finding（与 S-D4-001 紧密相关）。

修复：要么修代码兑现 claim，要么修决策表承认现实。

### S-D4-007 [MEDIUM, 1/3 Codex] — NFR 性能承诺 vs tag 过滤实现

NFR 写「搜索 <300ms / 题库 <500ms (200 题)」，但 `ReviewItemModel.swift:21` 模型只索引 createdAt/nextReviewAt/subjectRawValue。带 tag 过滤时 `ReviewRepository.swift:275` 全量拉取后内存过滤（受 apple-limits SwiftData many-to-many 谓词限制 + #Predicate 崩溃约束）。NFR 没把 tag filter 作为例外或另设口径。

修复：NFR 补 tag filter 例外或另设性能口径；或做 tag/search denormalization。

### S-D4-008 [LOW, 1/3 Antigravity] — NFR 海量场景 / 手写 OCR 指标缺

NFR 性能/内存指标只覆盖 200 题常规 + 印刷体 OCR；缺海量数据 many-to-many 查询、手写/印刷混合 OCR 弱光退级指标。

### S-D4-009 [LOW, 1/3 Codex] — BackupService 流式 NFR 过度表述

NFR 写「<200MB，流式 ZIP 写入，不全量加载」+ BackupService 注释同样声明流式，但实现对每张图 `Data(contentsOf:)`，ZIPArchiver 要求 Data 入参（非真正 file provider streaming）。

修复：NFR 改为「逐文件加载，受单图压缩大小约束」或改实现。

### S-D4-010 [LOW, 1/3 Codex] — Xcode 版本不一致

`workflow.md:126` 写 CI 用 Xcode 26.5，`deployment.md:42` + `.github/workflows/ci.yml:52` 仍写 Xcode 26.4+ / Xcode_26.4.app。

修复：统一表述「最低 26.4+，当前 runner 26.5」或 workflow.md 改为最低要求。

### S-D4-011 [LOW, 1/3 Codex] — compliance.md skill 化跨 agent 边界

`compliance.md` 声明权威执行在 `privacy-manifests` + `app-store-rejection` skill，但 `.agents/skills/app-store-rejection` 不存在，只在 `.claude/skills/` 存在。Claude 可执行但 Codex/Gemini/第三方外审不是 repo-shared 权威。

修复：迁入 `.agents/skills/` 或 compliance.md 明确「Claude-only authority + 外审替代路径」。

## Gemini 3.5 over-endorse 持续监控（维度 4 数据点）

| 指标 | 维度 1 | 维度 2 | 维度 3 | 维度 4 |
|---|---|---|---|---|
| HIGH 占比 | 33% (4/12) | 17% (1/6) | 17% (1/6) | 40% (2/5) |
| 100% VALID 倾向 | ❌ | ❌ | ❌ | ❌ |
| 抓到独家深度 finding | ✅ Dynamic Type | ✅ CSV vs Image is Truth | ✅ H2 vs SM-2 死锁 | ✅ 通知 ID 物理覆盖（真生产 bug）|
| 误判数 | 2 | 0 | 0 | 0 |
| 工作流违规 | — | — | ⚠️ 抢跑落档 | ✅ 守规矩（「严禁操作」段生效）|

**累计结论**：Gemini 3.5 四轮实测**未复现 over-endorse 病灶**。维度 3 暴露的「抢跑落档」工作流违规在维度 4 被改进提示词模板（「严禁操作」段）成功封堵。三方对抗角色继续维持。

## 单家排名变化

| 维度 | 最强单家 | 关键发现 |
|---|---|---|
| 1 | Antigravity | Dynamic Type 概念混淆 |
| 2 | Antigravity | CSV 违反「图片是真相」 |
| 3 | Codex / Antigravity 6/6 一致 | H2 vs SM-2 死锁 |
| 4 | **Codex** | badge 三层背离 + DataExecutor 降级 + 多 tech 文档漂移 |

Codex 在维度 4 大爆发，从前三轮的辅助角色升为最强。三家形态稳定互补。

## 下一步

1. **本会话**：commit + push（ledger + dim4-consensus + ADR-005 维度 4 行 + STATUS/handoff + single-vendor-prompt 工作流纪律）
2. **下一会话**：维度 5「standards 约束力」，**Claude CLI 先跑**，再给 Codex/Antigravity 提示词（new workflow discipline）
3. **累计 OPEN finding**：维度 1 (22) + 维度 2 (11) + 维度 3 (10) + 维度 4 (11) = **54 项**
