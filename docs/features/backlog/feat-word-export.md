---
id: feat-word-export
title: Word 导出（候选，商业分层未定）
status: backlog
tier: undecided
blocked_by: []
mode: lightweight
last_updated: 2026-07-12
intent_refs:
  - vision:P3
  - vision:P4
release_refs:
  - release-1:section-7
---

# Feature: Word 导出（候选，商业分层未定）

> 人读摘要：📋 候选 backlog，产品范围与商业分层未定；旧 #486 不能自行授权实现。派生自上方 frontmatter；frontmatter 仅是本功能候选实现状态的单一来源，不构成产品批准或发布承诺。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 自动生成，禁手改。
> 本 spec 于 2026-05-30 从 requirements / business 聚合（docs 重组 B）。`mode: lightweight`（backlog）——仅 Why + What 必填，How / Verify 待实现补，不为未实现功能编造假设计。
>
> **商业规范偏差（2026-07-12）**：Product Vision & Principles B6-A 已把 Word 与 Pro 降为未来候选，frontmatter 已改为 `tier: undecided`。外部价值证据、新商业裁决与 Release PRD 生效前不得实现或公开承诺。

## 1. 候选价值假设 (Why)

- 部分用户可能希望在打印前继续编辑段落、页眉页码和字体；Word 可能成为 PDF 之外的可编辑导出格式。
- 当前没有外部价值或付费证据。Word 不是 Release 1、Pro、价格或发布时间承诺，也不能替代 PDF 与手动备份的数据权利。

## 2. 需求规则 (What)
- **核心能力**：高级排版导出格式，支持用户二次调整段落格式 / 页眉页码 / 字体后再打印。
- **边界 / 不做**：
  - Word **不是新的录入路径**，只是导出格式的增值延伸——不得借 Word 引入新的题目录入入口（business §Word 导出定位说明）。
  - 基础日常导出仍走 PDF（免费）；Word 不替代 PDF，是其格式升级。
- **前置依赖**：若未来进入范围，应复用 `../active/feat-export.md` 的导出管线；引擎、格式质量和文件兼容性需先 PoC。
- **商业政策**：B6-A 下当前无有效 Pro 层或订阅降级规则；商业化等待外部证据与新 contract。

## 3. 技术设计 (How)
- 待实现补（PoC 阶段填）。Word 本体实现（#486）尚未编写；当前没有经确认的 docx 生成模块归属 / 引擎选型 / State & Concurrency 设计，**不在此编造假设计**。
- 已知约束：Word 是候选导出格式，预期复用而非重建导出管线；具体落点待 PoC 与新 contract 确认，不以前置 StoreKit 为产品假设。

## 4. 验证标准 (Verify)
- 待实现补（PoC 阶段填）。当前没有经 PO 确认的 Word 导出 UC / 边界 / NFR，**不为未实现功能编造验收规格**。


## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Vision | `../../product/vision.md`（P3 免费层完成核心闭环 / P4 用户拥有数据） | Word 若回归只能是可选格式，不能削弱基础导出与数据权利 |
| Release 1 PRD | `../../product/release-1-prd.md` §7 (`release-1:section-7`) | Word 导出是 Release 1 明确非目标；该引用只固定隐藏边界，不表示候选纳入 |
| 产品政策 / ADR | `../../explanations/business-model.md`（B6-A） | 当前无有效 Pro 层、价格或订阅降级规则 |
| 待验证假设 | 无（承接 H3 导出/打印是高价值终点） | — |
| 验收证据 | 等待外部价值证据、PoC 与新 contract（backlog lightweight） | 见本 spec Verify 节 |

找不到上游依据的需求是孤儿需求，不应直接实现。

## 关联
- 原则：`../../product/vision.md`（P3 免费层完成核心闭环 / P4 数据属于用户）
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`
- 历史决策：`../../decisions/ADR-001-smart-paper-analytics-pricing.md`（已被 B6-A 取代）
- 基础 / 相关 feature：`../active/feat-export.md`（PDF 导出基础，Word 为候选格式扩展）
