---
id: feat-smartpaper
title: 智能组卷（SmartPaper · Pro）
status: in-progress
tier: pro
blocked_by: [479]
mode: lightweight
last_updated: 2026-07-01
intent_refs:
  - vision:P2
  - vision:P3
  - vision:P4
  - ADR-001
---

# Feature: 智能组卷（SmartPaper · Pro）

> 人读摘要：🛠 **免费基础组卷已接通并从 Library 正常浏览态可达**：免费用户可按分类过滤 + 随机抽取生成资料集，设备本地自然月限次（3 次/月）；打开预览不扣，分享/打印完成后每次生成最多扣 1 次。Pro 精准组卷仍等待 StoreKit #479。
> 派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / architecture 聚合（docs 重组 B）。
> `mode: lightweight`：Pro 总闸（StoreKit #479）未接、Pro 路径不可购买，故以 Why + What 为准；How / Verify 记录**已实现的免费档 + 当前已确认的算法/排版机制**，未实现的 Pro 分支不编造设计。

## 1. 为什么做 (Why) — 纯 why，不混实现/UI 细节
- **痛点 / 价值**：用户录题 / 归档的最终目的之一是把内容输出到纸上使用。手动从资料库挑题排版耗时且凭感觉，难以针对薄弱环节。智能组卷把"导出 PDF"从手动选题升级为算法驱动的精准选题，复用 SM-2 回顾数据自动推荐薄弱题目并排版成可打印资料——「看数据 → 生成资料 → 自测 / 回顾 → 看变化」的闭环。
- **定位**：智能组卷是**导出/打印这一核心价值链终点的 Pro 增值延伸**，不是产品核心；属于"可选功能"，不应侵蚀核心采集/管理/导出路径的简洁性（若复杂度开始挤压主路径，以 vision 简洁原则裁决）。SM-2 选题/weakness/recency 排序是**本机端功能算法**，明确不属被禁的"推荐算法"（无跨用户协同过滤 / 无行为信号采集驱动 feed）。
- **商业定位**：智能组卷是 Pro 核心转化引擎（算法选题 + 多版式），与高级统计转化力叠加（薄弱排行 → 一键生成针对性打印资料）。
- **原则归属**：导出/打印核心价值链 + Pro 增值分层（详见 `../../explanations/vision.md`；Pro/Free 划分与定价见 `../../explanations/business-model.md` 与 `../../decisions/ADR-001-smart-paper-analytics-pricing.md`）。不贩卖焦虑原则约束配额耗尽/Pro 预览文案（中性、不倒计时、不诱导）。

## 2. 需求规则 (What) — 用户可感知的规则与边界
- **核心能力**：选择分类范围与目标题目数量，系统自动选题并复用 PDF 导出管线生成可预览、可打印/分享/保存的资料集。
- **选题策略（按订阅档差异化，Hybrid）**：
  - **基础选题（免费）**：按分类过滤 + 随机抽取；免费限次体验（3 次/自然月）。
  - **精准选题（Pro）**：SM-2 weakness 权重 + 近期错误优先（recency）+ 分类 / 动态维度交叉筛选；无限生成 + 多版式。当前 StoreKit #479 未接，`ProEntitlementProvider.isProUser` 仍默认 `false`，此分支保留为门后路径。
- **输出格式**：PDF（去答案模式 / 留白答题区 / 页眉页码），复用现有导出管线。
- **与高级统计联动**：可从薄弱排行一键进入智能组卷（Analytics → Smart Paper），联动仅传题目 ID。
- **配额机制（防焦虑铁律）**：免费配额按自然月重置；耗尽后展示 Pro 引导但**不阻断**已有手动导出能力；文案中性（不红色/警告色、不倒计时、不显示「剩余 N 次」）；Pro 预览须明确标「Pro 功能预览」；引导 Toast ≤3 秒自动消失，不用 Modal 阻断。
- **边界 / 不做**：只从唯一资料库当前候选集选题；不在免费层完全锁死；组卷入口不得压过采集与资料库。
- **前置依赖**：依赖 `../active/feat-review.md` 产出的 SM-2 数据（`easeFactor` / `interval` / weakness 信号）驱动精准选题；依赖 PDF 导出管线（`PDFExportService`）排版输出；Pro 分支前置 StoreKit 入口（#479）。
- **商业分层**：基础模板限次组卷 = 免费档；无限生成 + 精准选题 + 多版式 = Pro（Hybrid，ADR-001）。**当前 StoreKit #479 未接，`ProEntitlementProvider.isProUser` 硬编码 `false`，Pro 分支入口保留、门后"敬请期待"，首版全球版 TestFlight 纯免费、不可购买/测试 Pro。**

## 3. 技术设计 (How) — 仅浓缩已落档机制，未实现 Pro 分支不编造
- **模块归属**：`SnapDrillFeatureLibrary/SmartPaperView` + `SmartPaperViewModel`；入口位于 `LibraryView` 正常浏览态右上工具栏（非编辑/多选导出路径，免费用户可见）；选题策略复用 `SnapDrillCore` 的 `ReviewScheduler` + `SM2State`（基于 SM-2 数据驱动）；排版/导出复用 `SnapDrillCore/Service/PDFExportService` 管线（不重新实现 PDF 引擎）；Pro gating 经 `ProEntitlementProvider` 接入 StoreKit。新增 `@Model` 类型：无（复用既有题目与 `SM2State`）。
- **关键机制 / 数据流**：选题 → 生成题目快照 → PDF 预览 → 分享/打印/保存。免费配额是设备级本地状态，不跨设备同步。
  - 免费层：`SmartPaperViewModel` 使用资料库 + 选定分类值做候选集；实际分享/打印完成后扣减，同一次预览最多扣 1 次，计数写入 `UDKey.smartPaperFreeQuotaMonth` / `UDKey.smartPaperFreeQuotaUsed`。
  - Pro 层：`isProUser == true` 时仍走 `ArchiveRepository.fetchSmartSelection(...)`（SM-2 排序），且不消耗免费配额；真实购买状态待 #479 接入。
- **State & Concurrency**（Swift 6 strict）：组卷 View 由 `@Observable` 的 `SmartPaperViewModel`（`@MainActor`）驱动（业务编排走 ViewModel，符合"复杂写/编排流程"例外）；SM-2 数据查询与题目读取经 Repository → `DataExecutor`（actor）落库/取数，不阻塞主线程；PDF 批量渲染按 NFR 用 `autoreleasepool` 逐页释放防 OOM。
  - *注*：Pro 精准选题打分细节与多版式实现待 #479 解阻后补；本段仅锁定已落档的模块归属与并发约束，不展开未实现的算法权重公式。
- **设计裁决**：无（本功能复用既有 PDF / SM-2 机制，无对全局原则的局部例外）。

## 4. 验证标准 (Verify) — GWT 风格；Pro 分支当前不作回归基线
- **Success path (GWT)**：
  - 免费档（可达基线）：Given 资料库有足够题目且本自然月配额未耗尽，When 用户触发组卷并完成分享或打印，Then 消耗 1 次设备级免费配额，同一预览不重复扣减。
  - Pro 档（**当前不可达、不作代码/测试回归基线**，待 #479）：When Pro 用户选精准选题，Then 按 SM-2 weakness + recency + 动态维度筛选选题并支持多版式。
- **边界 / 异常**：
  - 免费配额耗尽 → 展示中性 Pro 引导 Toast，**不阻断**已有手动导出能力。
  - 题目不足 → 提示题库数量不够，建议先录入更多题目。
  - PDF 生成失败 → 提示失败原因，**保留选题结果可重试**。
  - 用户取消预览 → 不消耗免费配额，选题结果不持久化，下次进入需重新选题。
- **数据保证**：选题结果与 PDF 导出复用同一份题目快照；免费配额为设备级本地状态；联动仅传题目 ID。
- **回归测试**：`SmartPaperViewModelTests` 覆盖随机选题、预览不扣、导出扣减、同一预览只扣一次、Pro 分支、月配额与月重置。
- **NFR**：PDF 批量导出内存 < 200MB（`autoreleasepool` 逐页释放）。其余精准选题性能/埋点指标待 Pro 分支实现后补。


## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../explanations/vision.md`（P2 简洁 / P3 免费层完成核心闭环 / P4 用户拥有数据） | 导出/打印终点的 Pro 增值延伸；不侵蚀核心简洁；SM-2 选题为端侧算法、非被禁的推荐算法 |
| 产品政策 / ADR | `../../decisions/ADR-001-smart-paper-analytics-pricing.md`（Hybrid：免费限次 + Pro 无限精准选题） | 基础组卷免费限次、精准选题 Pro；配额耗尽文案防焦虑 |
| 待验证假设 | `../../explanations/business-model.md` H8（智能组卷是否补强 Pro 转化、不破坏简洁主路径） | 解锁后验证 H8 |
| 验收证据 | §4 免费档可达基线 + AllTests；Pro 分支待 #479 | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../explanations/vision.md`（简洁裁决 / Pro 增值 / 功能算法非推荐算法）
- 商业 / 定价：`../../explanations/business-model.md`
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（高级统计 → 智能组卷 → 打印联动；本版本未单列该 Pro 旅程）
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（智能组卷 Hybrid 定价 / 归属 Pro）
- 依赖 feature：`../active/feat-review.md`（SM-2 数据）、`feat-advanced-stats.md`（薄弱排行联动）
