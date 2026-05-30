---
id: feat-smartpaper
title: 智能组卷（SmartPaper · Pro）
status: blocked
tier: pro
blocked_by: [479]
mode: lightweight
last_updated: 2026-05-30
---

# Feature: 智能组卷（SmartPaper · Pro）

> 人读摘要：⛔ Pro 精准选题阻塞于 StoreKit #479（免费基础组卷已实现 #566）。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 vision / requirements / design / cases / business / journeys / architecture 聚合（docs 重组 B）。
> `mode: lightweight`：Pro 总闸（StoreKit #479）未接、Pro 路径不可达，故以 Why + What 为准；How / Verify 仅浓缩源文档**已实现的免费档 + 已落档的算法/排版机制**，未实现的 Pro 分支不编造设计。

## 1. 为什么做 (Why) — 纯 why，不混实现/UI 细节
- **痛点 / 价值**：家长录题的最终目的是让孩子在纸上练习。手动从题库挑题出卷耗时且凭感觉，难以针对薄弱环节。智能组卷把"导出 PDF"从手动选题升级为算法驱动的精准选题，复用孩子的 SM-2 复习数据自动推荐薄弱题目并排版成可打印练习卷——「看数据 → 出卷子 → 做练习 → 看进步」的闭环。
- **定位**：智能组卷是**导出/打印这一核心价值链终点的 Pro 增值延伸**，不是产品核心；属于"可选功能"，不应侵蚀核心采集/管理/导出路径的简洁性（若复杂度开始挤压主路径，以 vision 简洁原则裁决）。SM-2 选题/weakness/recency 排序是**本机端功能算法**，明确不属被禁的"推荐算法"（无跨用户协同过滤 / 无行为信号采集驱动 feed）。
- **商业定位**：智能组卷是 Pro 核心转化引擎（算法选题 + 多版式），与高级统计转化力叠加（薄弱排行 → 一键生成针对性练习卷）。
- **原则归属**：导出/打印核心价值链 + Pro 增值分层（详见 `../../explanations/vision.md`；Pro/Free 划分与定价见 `../../explanations/business-model.md` 与 `../../decisions/ADR-001-smart-paper-analytics-pricing.md`）。不贩卖焦虑原则约束配额耗尽/Pro 预览文案（中性、不倒计时、不诱导）。

## 2. 需求规则 (What) — 用户可感知的规则与边界
- **核心能力**：选择学科范围与目标题目数量，系统自动选题并复用 PDF 导出管线生成可预览、可打印/分享/保存的练习卷。
- **选题策略（按订阅档差异化，Hybrid）**：
  - **基础选题（免费）**：按学科过滤 + 随机抽取；免费限次体验（有限次/月）。
  - **精准选题（Pro）**：SM-2 weakness 权重 + 难度分布均衡 + 近期错误优先（recency）+ 学科交叉筛选；无限生成 + 多版式。
- **输出格式**：PDF（去答案模式 / 留白答题区 / 页眉页码），复用现有导出管线。
- **与高级统计联动**：可从薄弱排行一键进入智能组卷（Analytics → Smart Paper），联动仅传题目 ID。
- **配额机制（防焦虑铁律）**：免费配额按自然月重置；耗尽后展示 Pro 引导但**不阻断**已有手动导出能力；文案中性（「本月免费额度已用完，下月 X 日重置」），不用红色/警告色/倒计时、不显示「剩余 N 次」、Pro 预览须明确标「Pro 功能预览」、引导 Toast ≤3 秒自动消失不 Modal 阻断。
- **边界 / 不做**：仅在当前 Profile 题库范围内选题，**不跨 Profile**；不在免费层完全锁死（限次体验是转化关键）；不向 Anki 式记忆工具靠拢；组卷入口不得压过采集与题库。
- **前置依赖**：依赖 `../active/feat-review.md` 产出的 SM-2 数据（`easeFactor` / `interval` / weakness 信号）驱动精准选题；依赖 PDF 导出管线（`PDFExportService`）排版输出；Pro 分支前置 StoreKit 入口（#479）。
- **商业分层**：基础模板限次组卷 = 免费档；无限生成 + 精准选题 + 多版式 = Pro（Hybrid，ADR-001）。**当前 StoreKit #479 未接，`ProEntitlementProvider.isProUser` 硬编码 `false`，Pro 分支入口保留、门后"敬请期待"，首版国内 TestFlight 纯免费、不可购买/测试 Pro。**

## 3. 技术设计 (How) — 仅浓缩已落档机制，未实现 Pro 分支不编造
- **模块归属**：`SnapDrillFeatureLibrary/SmartPaperView` + `SmartPaperViewModel`（触发入口）；选题策略复用 `SnapDrillCore` 的 `ReviewScheduler` + `SM2State`（基于 SM-2 数据驱动）；排版/导出复用 `SnapDrillCore/Service/PDFExportService` 管线（不重新实现 PDF 引擎）；Pro gating 经 `ProEntitlementProvider` 接入 StoreKit。新增 `@Model` 类型：无（复用既有题目与 `SM2State`）。
- **关键机制 / 数据流**：选题 → 生成题目快照 → PDF 预览（去答案 / 留白答题区 / 页眉页码）→ 分享/打印/保存。选题结果与 PDF 导出复用**同一份题目快照**，确保「预览—打印—分享」三步内容一致。免费配额计数为按 Profile 隔离的本地状态，不跨设备同步。
- **State & Concurrency**（Swift 6 strict）：组卷 View 由 `@Observable` 的 `SmartPaperViewModel`（`@MainActor`）驱动（业务编排走 ViewModel，符合"复杂写/编排流程"例外）；SM-2 数据查询与题目读取经 Repository → `DataExecutor`（actor）落库/取数，不阻塞主线程；PDF 批量渲染按 NFR 用 `autoreleasepool` 逐页释放防 OOM。
  - *注*：Pro 精准选题打分细节与多版式实现待 #479 解阻后补；本段仅锁定已落档的模块归属与并发约束，不展开未实现的算法权重公式。
- **设计裁决**：无（本功能复用既有 PDF / SM-2 机制，无对全局原则的局部例外）。

## 4. 验证标准 (Verify) — GWT 风格；Pro 分支当前不作回归基线
- **Success path (GWT)**：
  - 免费档（可达基线）：Given 当前 Profile 有足够题目（建议 ≥10），When 用户选定学科范围与目标题数并触发组卷，Then 系统按随机策略选题、复用导出管线生成 PDF 预览，用户确认后可分享/打印/保存。
  - Pro 档（**当前不可达、不作代码/测试回归基线**，待 #479）：When Pro 用户选精准选题，Then 按 SM-2 weakness + difficulty + recency 选题并支持多版式。
- **边界 / 异常**：
  - 免费配额耗尽 → 展示 Pro 引导，**不阻断**已有手动导出能力。
  - 题目不足 → 提示题库数量不够，建议先录入更多题目。
  - PDF 生成失败 → 提示失败原因，**保留选题结果可重试**。
  - 用户取消预览 → 选题结果不持久化，下次进入需重新选题。
- **数据保证**：仅在当前 Profile 题库范围内选题，不跨 Profile；选题结果与 PDF 导出复用同一份题目快照（三步内容一致）；免费配额计数按 Profile 隔离、为本地状态、不跨设备同步；「薄弱排行 → 智能组卷」联动仅传题目 ID，不携带跨 Profile 数据。
- **NFR**：PDF 批量导出内存 < 200MB（`autoreleasepool` 逐页释放）。其余精准选题性能/埋点指标待 Pro 分支实现后补。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（核心理念 / 定位 / 功能算法非推荐算法 / 转化引擎） | design §智能组卷设计 + vision §不是什么·不是社交产品 + vision §核心价值链 + business §付费模式 |
| Why · 原则归属 / 防焦虑 | vision 产品原则 + design §配额耗尽/Pro 模糊预览 防焦虑铁律 + ADR-001 |
| What（选题策略 / 输出 / 配额 / 分层 / 联动） | design §智能组卷设计 + business §付费模式·免费层定义 + requirements §功能全景·功能状态总表 |
| What · 前置依赖（SM-2） | feat-review（被依赖）+ architecture §Smart Paper |
| What · 分层与阻塞状态 | requirements §功能状态总表（#566 免费已实现 / #479 Pro 阻塞）+ business 分层原则 |
| How（模块 / 数据流 / 并发） | architecture §Smart Paper（智能组卷）+ NFR §内存·PDF 批量导出 |
| Verify（success / 边界 / 数据保证） | cases UC8 Smart Paper Generation + UC9 联动 |
| Verify · NFR | non-functional-requirements §内存 |
| 旅程参照 | journeys 旅程 12 考前精准组卷 |

## 关联
- 原则：`../../explanations/vision.md`（简洁裁决 / Pro 增值 / 功能算法非推荐算法）
- 商业 / 定价：`../../explanations/business-model.md`
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`（旅程 12：考前精准组卷 Analytics → Smart Paper → Print）
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（智能组卷 Hybrid 定价 / 归属 Pro）
- 依赖 feature：`../active/feat-review.md`（SM-2 数据）、`feat-advanced-stats.md`（薄弱排行联动）
