---
id: feat-XXX
title: 功能名称
status: backlog          # implemented | in-progress | blocked | poc-needed | backlog
tier: free               # free | pro
blocked_by: []           # issue 编号列表，如 [479]；status=blocked 时必填
mode: full               # full（四段全填）| lightweight（backlog，仅 Why+What 必填）
last_updated: YYYY-MM-DD
---

# Feature: [功能名称]

> 人读摘要派生自上方 frontmatter；**全局状态以 frontmatter 为唯一真理源（B 方案）**。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 扫描各 spec 的 frontmatter **自动生成**，禁止手改（pre-commit 校验）。
> 本 spec 高内聚承载该功能 Why / What / How / Verify，不拆散到多文件（docs 重组 B）。
> `mode: lightweight`（backlog 用）时，How / Verify 可只写"待实现补"，仅 Why + What 必填——避免给未实现功能写"假设计"。

## 1. 为什么做 (Why) — 纯 why，不混实现/UI 细节
- **痛点 / 价值**：用户的什么痛点，本功能带来什么价值。
- **定位与原则归属**：对应 `../../explanations/vision.md` 的哪条产品原则（如 P3 免费附加值）。

## 2. 需求规则 (What) — 用户可感知的规则与边界
- **核心能力**：做什么（功能点 / 规则）。
- **边界 / 不做**：明确不做的，防范围蔓延。
- **前置依赖**：依赖哪个 feature 的什么产出（如 `feat-review` 的 SM-2 数据）；无则写"无"。
- **商业分层**：免费 / Pro 的**边界**（为什么这样分层属 Why / ADR，不在此展开；定价见 `../../explanations/business-model.md`）。

## 3. 技术设计 (How) — 只放实现机制，不放商业/上位 why
- **模块归属**：`Packages/...` / `SnapDrill/...`；新增 `@Model` 类型与位置（如有）。
- **关键机制 / 数据流**：核心实现、数据模型要点。
- **State & Concurrency**（Swift 6 strict）：State 归属哪个 `@Observable`（是否 `@MainActor`）；重活/落库跑在哪个 actor；如何不阻塞主线程。
- **设计裁决**（如无可省略）：本功能内对全局原则的局部例外 + 理由 + 限定范围。

## 4. 验证标准 (Verify) — GWT 风格，不复述 How 的交互细节
- **Success path**：主流程的 Given-When-Then（承接原 cases UC）。
- **边界 / 异常**：边界 case + 异常处理。
- **数据保证**：必须守住的数据不变量。
- **NFR**：性能容忍（如大图加载）、关键埋点、中断恢复等非功能要求；无则写"无"。

## Provenance（迁移期审计用，全量封板后可删）
| 本 spec 内容 | 来源（旧文档章节 / UC / ADR） |
|---|---|
| Why | vision §… |
| What | requirements §… |
| How | design §… |
| Verify | cases UC… |

## 关联
- 原则：`../../explanations/vision.md`
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`
- 决策：`../../decisions/ADR-XXX`
- 相关 / 依赖 feature：`feat-XXX.md`
