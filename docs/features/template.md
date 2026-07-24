---
id: feat-XXX
title: 功能名称
status: backlog          # implemented | in-progress | blocked | poc-needed | backlog
tier: undecided          # free | pro | undecided；pro 仅在 effective 商业 / Release PRD 存在时可用
blocked_by: []           # issue 编号列表，如 [479]；status=blocked 时必填
mode: full               # full（四段全填）| lightweight（backlog，仅 Why+What 必填）
last_updated: YYYY-MM-DD
intent_refs:              # 至少一项 Vision / 产品政策 / ADR 引用
  - vision:P1
release_refs:             # 当前 effective Release PRD 的精确消费边；非目标仅按受限 section-7 规则
  - release-1:C2-Core
release_outcomes: []      # active feature 直接拥有 / 承接的 M1-M10；无 Must owner 时保持空列表
---

# Feature: [功能名称]

> 人读摘要派生自上方 frontmatter；frontmatter 仅是本功能实现状态的单一来源，不表示产品批准、Release PRD 符合、公开可达或发布就绪。
> 状态总表 `../../reference/feature-status.md` 由 `Scripts/generate_feature_status.py` 扫描各 spec 的 frontmatter **自动生成**，禁止手改（pre-commit 校验）。
> 本 spec 高内聚承载该功能 Why / What / How / Verify，不拆散到多文件（docs 重组 B）。
> `mode: lightweight`（backlog 用）时，How / Verify 可只写"待实现补"，仅 Why + What 必填——避免给未实现功能写"假设计"。
> `tier: undecided` 表示商业归属尚未裁决；候选功能不得为了填字段而默认归入 Pro。
> `release_refs` 只表示 Feature 消费 / 追溯边，不把 Feature 变成上游裁决 owner，也不证明实现符合、候选纳入、公开可达或发布就绪。
> `release_outcomes` 只声明本 spec 对 Must outcome 的产品 owner / 直接承接关系；它不证明实现或候选证据已通过。
> `blocked_by` 的 issue 编号只表示依赖元数据，不构成当前 bet、scope 或执行授权。

## 1. 为什么做 (Why) — 纯 why，不混实现/UI 细节
- **痛点 / 价值**：用户的什么痛点，本功能带来什么价值。
- **定位与原则归属**：对应 Product Vision & Principles 和当前 Release PRD 的哪条结果或原则。

## 2. 需求规则 (What) — 用户可感知的规则与边界
- **核心能力**：做什么（功能点 / 规则）。
- **边界 / 不做**：明确不做的，防范围蔓延。
- **前置依赖**：依赖哪个 feature 的什么产出（如 `feat-review` 的 SM-2 数据）；无则写"无"。
- **商业分层**：引用 `../../explanations/business-model.md` 与当前 Release PRD。Release 1 免费、无 IAP；feature spec 不得自行创建 Pro、配额或价格承诺。

## 3. 技术设计 (How) — 只放实现机制，不放商业/上位 why
- **模块归属**：`Packages/...` / `SnapDrill/...`；新增 `@Model` 类型与位置（如有）。
- **关键机制 / 数据流**：核心实现、数据模型要点。
- **State & Concurrency**（Swift 6 strict）：State 归属哪个 `@Observable`（是否 `@MainActor`）；重活/落库跑在哪个 actor；如何不阻塞主线程。
- **设计裁决**（如无可省略）：本功能内对全局原则的局部例外 + 理由 + 限定范围。

## 4. 验证标准 (Verify) — GWT 风格，不复述 How 的交互细节
- **Success path**：主流程的 Given-When-Then；验收条件必须能追溯到当前上游意图或已确认用例。
- **边界 / 异常**：边界 case + 异常处理。
- **数据保证**：必须守住的数据不变量。
- **NFR**：性能容忍（如大图加载）、关键埋点、中断恢复等非功能要求；无则写"无"。

## 意图追溯（永久保留）

| 层 | 上游依据 | 本功能承接 |
|---|---|---|
| Product Vision & Principles | `../../product/vision.md#pX-...` | 本功能如何服务该原则 / 边界 |
| Release PRD | 当前发布 contract；如尚未建立则停止 shaping | 本功能在本次发布中的结果与非目标 |
| 产品政策 / typed decision | 如无写“无” | 本功能必须遵守的细化边界或已决取舍 |
| 待验证假设 | 如无写“无” | 本功能会改变哪条 H# 的置信度 |
| 验收证据 | 测试 / 构建 / 真机 / 发布证据 | 如何证明实现满足上游意图 |

找不到上游依据的需求是孤儿需求，不应直接实现。历史迁移来源由 Git 记录，不在当前 spec 中保留旧体系编号。

## 当前执行准入（非产品 SSOT）

<!-- 仅当本 spec 被指定为具名执行 brief 时填写；否则指向独立的当前 issue / PR brief。 -->

- **Base / current evidence**：`origin/develop@<full-sha>`
- **Authority / outcome**：
- **Owner / scope / red lines**：
- **Acceptance / validation**：
- **Routing / dependencies / unresolved gates**：

Yellow / Red、T4、历史恢复或跨 lane 时，只追加 DoR 定义的适用 expanded admission 字段。

历史 issue / PR / 审计 / 报告只作证据；编号、时间、open / closed、Draft / Ready、label、旧授权
或旧 CI 不构成当前执行权。准入规则见
[`definition-of-ready.md#current-admission`](../how-to/definition-of-ready.md#current-admission)。

## 关联
- 原则：`../../product/vision.md`
- 状态总表（自动生成）：`../../reference/feature-status.md`
- 用户旅程：`../../explanations/user-journeys.md`
- 决策：`../../decisions/ADR-XXX`
- 相关 / 依赖 feature：`feat-XXX.md`
