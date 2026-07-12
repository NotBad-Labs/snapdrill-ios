---
id: feat-smartpaper
title: SmartPaper（候选，商业分层未定）
status: in-progress
tier: undecided
blocked_by: []
mode: lightweight
last_updated: 2026-07-12
intent_refs:
  - vision:P2
  - vision:P3
  - vision:P4
---

# Feature: SmartPaper（候选，商业分层未定）

> 人读摘要：🛠 当前代码已接通基础组卷，并保留按 Profile 的月配额与不可达 Pro 分支；这些是实现实证，不是 Release 1 产品规则。B6-A 下当前无有效 Pro 层，所有 Pro upsell / “敬请期待”界面必须隐藏。SmartPaper 是否进入 Release 1、是否保留配额及选择器范围等待 Gate C。
> 派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / architecture 聚合（docs 重组 B）。
> `mode: lightweight`：How / Verify 只记录当前实现和风险，不把未批准候选写成发布规格。
>
> **商业规范偏差（2026-07-12）**：Product Constitution B6-A 已取代 ADR-001 的 Hybrid / Pro 分层，frontmatter 已改为 `tier: undecided`。07-01 的配额、导出完成才扣费与入口裁决只作 tracked 历史；其 Release 1 可见性、是否保留配额及选择器范围等待 Gate C，当前不可显示 Pro upsell。

## 1. 候选价值假设 (Why)

- 用户可能希望从资料库自动挑选若干资料并生成可打印 PDF，减少手动选择与排版成本。
- 基于本机 SM-2 数据的 weakness / recency 排序可能提供附加复用价值，但 SmartPaper 不得占据或复杂化采集 -> 整理 / 找回 -> 导出 / 打印的核心路径。
- 当前没有外部使用或付费证据；SmartPaper 是否进入 Release 1、是否需要配额及未来如何商业化都等待新 contract，不再沿用 ADR-001 的 Hybrid 结论。

## 2. 候选范围与当前约束 (What)

- 候选能力是选择范围与目标题目数量，自动选题并复用 PDF 导出管线生成可预览、打印、分享或保存的资料集。
- 随机、SM-2 weakness / recency、多版式、配额和高级统计联动都是待 Gate C 取舍的候选，不构成现行需求。
- 若未来进入范围，只能读取唯一资料库；不得引入 Profile 产品语义，不得绕开手动导出或削弱数据权利。
- B6-A 下当前不得显示 Pro 引导、付费锁态、订阅档差异或“敬请期待”。现有配额耗尽 Toast 与不可达 Pro 分支是实现偏差，等待后续 implementation slice 依据 Release Contract 处理。
- PDF 输出复用 `PDFExportService` 是现有技术事实；是否继续采用由实现 review 决定。

## 3. 当前实现结构 (How) — 遗留实证，不是产品 oracle
- **模块归属**：`SnapDrillFeatureLibrary/SmartPaperView` + `SmartPaperViewModel`；当前入口位于 `LibraryView` 工具栏，选题复用 `ReviewScheduler` + `SM2State`，排版复用 `PDFExportService`。旧 Pro gating 经 `ProEntitlementProvider` 表达，B6-A 后不得据此扩展 StoreKit 或用户可见升级路径。
- **关键机制 / 数据流**：选题 → 生成题目快照 → PDF 预览（去答案 / 留白答题区 / 页眉页码）→ 分享 / 打印 / 保存。选题结果与 PDF 导出复用同一份题目快照。当前配额按 Profile 隔离，属于待重基线状态。
  - 当前随机路径：`SmartPaperViewModel` 使用当前 Profile 资料库 + 选定分类值做候选集；预览不扣配额，分享 / 打印后由 `ExportPreviewView.onExport` 调用 `consumeFreeQuota()`。这是现状记录，不是免费档产品规则。
  - Profile 隔离：配额键纳入 `ProfileManager.perProfileKeys`，随 Profile 偏好保存/切换/清理一起搬运，避免跨 Profile 串用。
  - 旧 Pro 分支：`isProUser == true` 时走 `ArchiveRepository.fetchSmartSelection(...)`；该不可达分支只作重基线风险记录，不等待或授权 #479。
- **State & Concurrency**（Swift 6 strict）：组卷 View 由 `@Observable` 的 `SmartPaperViewModel`（`@MainActor`）驱动（业务编排走 ViewModel，符合"复杂写/编排流程"例外）；SM-2 数据查询与题目读取经 Repository → `DataExecutor`（actor）落库/取数，不阻塞主线程；PDF 批量渲染按 NFR 用 `autoreleasepool` 逐页释放防 OOM。
  - *注*：旧精准选题分支与多版式未获产品授权；本段不展开未实现算法，也不以旧 #479 作为重入条件。
- **设计裁决**：无（本功能复用既有 PDF / SM-2 机制，无对全局原则的局部例外）。

## 4. 当前实现证据 (Verify) — 不是 Release 1 验收
- **Success path (GWT)**：
  - 当前代码：在当前 Profile 有足够题目且配额未耗尽时，可按随机策略生成 PDF；这些测试用于防止未审查改动破坏现状，不证明 Release 1 应保留该行为。
- **边界 / 异常**：
  - Release 1 用户可见面不得出现现有 Pro 引导 Toast；手动导出始终不受候选 SmartPaper 状态影响。
  - 题目不足 → 提示题库数量不够，建议先录入更多题目。
  - PDF 生成失败 → 提示失败原因，**保留选题结果可重试**。
  - 用户取消预览 → 不消耗免费配额，选题结果不持久化，下次进入需重新选题。
- **数据保证**：候选能力只读取唯一资料库；当前 Profile / 配额状态属于待退场实现。选题结果与 PDF 导出复用同一份快照，不能跨容器读取资料。
- **当前实现回归**：`SmartPaperViewModelTests` 与 `ProfileManagerPreferenceTests` 仍覆盖旧随机选题、配额、不可达精准分支和 per-profile 状态；这些测试保护重基线过程，不证明相应产品行为应保留。
- **NFR**：PDF 批量导出内存 < 200MB（`autoreleasepool` 逐页释放）。若未来 contract 批准精准选题，再补相应性能与指标约束。


## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P2 简洁 / P3 免费层完成核心闭环 / P4 用户拥有数据） | SmartPaper 只能是可选附加值，不侵蚀核心路径或数据权利 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | 当前无有效 Pro 层；不显示 upsell、付费锁态或“敬请期待” |
| 待验证假设 | `../../explanations/business-model.md` H8 | 验证附加价值，不预设转化或配额模式 |
| 验收证据 | §4 仅为当前实现回归；Release 验收等待 Gate C | 不把代码现状当产品 oracle |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（简洁裁决 / 可选附加值 / 功能算法非推荐算法）
- 商业 / 定价：`../../explanations/business-model.md`
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 当前用户旅程：`../../explanations/user-journeys.md`（无 SmartPaper 旅程承接；高级统计联动仅是 ADR-001 历史构想）
- 历史决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（已被 B6-A 取代）
- 依赖 feature：`../active/feat-review.md`（SM-2 数据）、`feat-advanced-stats.md`（薄弱排行联动）
