---
id: feat-word-export
title: Word 导出（Pro）
status: blocked
tier: pro
blocked_by: [486]
mode: lightweight
last_updated: 2026-05-30
---

# Feature: Word 导出（Pro）

> 人读摘要：⛔ 阻塞（Pro）。Word 本体 = #486 未写；Pro 总闸前置 = StoreKit #479。派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 requirements / business 聚合（docs 重组 B）。`mode: lightweight`（backlog）——仅 Why + What 必填，How / Verify 待实现补，不为未实现功能编造假设计。

## 1. 为什么做 (Why)
- **痛点 / 价值**：PDF 是基础导出（免费），覆盖「打印一份错题卷」核心场景，但版式固定。部分家长想在打印前二次调整段落格式、页眉页码、字体——Word 给的是这份**可再编辑的高级排版能力**。
- **定位**：Word 是 PDF 的**增值升级**（Pro），不是新的录入路径，是导出格式的增值延伸；不破坏 vision §1「录入体验是生命线」边界（承接 business §Word 导出定位说明）。承接 vision §4「数据属于用户」——数据可导出为更可编辑的格式带走。
- **原则归属**：P3 免费即门槛（PDF 导出基础能力永久免费，Word 高级排版作为 Pro 增值）+ P4 数据属于用户。详见 `../../explanations/vision.md`。

## 2. 需求规则 (What)
- **核心能力**：高级排版导出格式，支持家长二次调整段落格式 / 页眉页码 / 字体后再打印（business §Word 导出定位说明 + requirements §导出与打印能力）。
- **边界 / 不做**：
  - Word **不是新的录入路径**，只是导出格式的增值延伸——不得借 Word 引入新的题目录入入口（business §Word 导出定位说明）。
  - 基础日常导出仍走 PDF（免费）；Word 不替代 PDF，是其格式升级。
- **前置依赖**：依赖 `feat-export.md` 的导出管线作为基础（PDF 导出 = 免费基础，Word = 其格式升级）；Pro 总闸依赖 StoreKit（#479，`ProEntitlementProvider.isProUser` 当前硬编码 `false`）。
- **商业分层**：Pro 付费增值。免费层 = 完整单设备产品体验（含 PDF 导出/打印）；Word 高级排版导出属付费增值。**订阅取消后降级**：Word 导出回退到 PDF 免费导出，已有数据完整保留可继续 PDF/JSON/CSV/.zip 导出（business §订阅取消后数据降级策略）。定价见 `../../explanations/business-model.md`。

## 3. 技术设计 (How)
- 待实现补（PoC 阶段填）。Word 本体实现（#486）尚未编写；源文档未给出 docx 生成的模块归属 / 引擎选型 / State & Concurrency 设计，**不在此编造假设计**。
- 已知约束（来自现有文档，非新设计）：与其他 Pro 增值一样需先建 StoreKit 闸门；Word 是「导出格式升级」，预期复用而非重建导出管线（承接 `feat-export.md`「智能组卷、Word 导出均复用同一管线」表述），具体落点待 PoC 确认。

## 4. 验证标准 (Verify)
- 待实现补（PoC 阶段填）。源文档（cases）当前无 Word 导出的 UC / 边界 / NFR，**不为未实现功能编造验收规格**。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why（PDF→Word 增值升级 / 非新录入路径 / P3·P4） | business §Word 导出定位说明（承接 vision §1 + §4）|
| What（高级排版：段落/页眉页码/字体） | requirements §导出与打印能力 + §数据可携带权矩阵 |
| What（前置依赖 / Pro 总闸 #479） | requirements §功能状态总表（SSOT）Word 导出行 |
| What（商业分层 / 订阅取消降级） | business §免费层定义 + §订阅取消后数据降级策略 |
| 状态（blocked #486 前置 #479） | requirements §功能状态总表 + business 免费/Pro 对照表 |
| How / Verify | 源文档无内容——backlog lightweight，待实现补 |

## 关联
- 原则：`../../explanations/vision.md`（P3 免费即门槛 / P4 数据属于用户）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`
- 决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（Pro 分层）
- 基础 / 相关 feature：`../active/feat-export.md`（PDF 导出基础，Word 为其 Pro 格式升级）
