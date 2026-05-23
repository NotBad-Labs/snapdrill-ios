---
last_verified: 2026-05-19
layer: pattern
---
# 项目纪律索引（F-NNN 规则）

> F 规则已 skill 化 / rule 化。本文件为索引，不做权威定义源（F-004 例外，见"政策标签"段）。
> 各规则的权威定义在其对应的 skill 或 rule 文件中。

## 规则路由

| 编号 | 规则 | 权威源 | 触发方式 |
|---|---|---|---|
| F-001 | Git 工作流纪律 | `docs/protocol.md` § Git 工作流 | 所有 git 操作 |
| F-004 | 内测不做 Schema 迁移 | 本文件（policy 标签，timeboxed，见下方"政策标签"段） | Model 文件变更时 |
| F-005 | 对抗性审查 | `docs/protocol.md` § Code Review | PR 提交/合并时 |
| F-006 | 审计深度验证 | `verify-audit-report` skill | 收到审计报告时 |
| F-007 | CI 双时点门禁 | `post-merge` skill + hooks | PR 合并时 |
| F-008 | 三方相同完整任务 | `cross-audit` skill | 审计启动时 |
| F-011 | 审计期间三方只读 | `cross-audit` skill | 审计启动时 |
| F-012 | 全量做不偷懒 | `verify-audit-report` skill | 审计验证时 |
| F-013 | Scope 膨胀拆分 | `sprint-contract` skill | 编码时 |
| F-014 | 跳过测试门禁 | `sprint-contract` skill | 编码时 |
| F-016 | 质疑方批准 | `cross-audit` skill | 修复后复核时 |
| F-017 | UI/SDK 调研 | `api-research` skill | UI/SDK 改动时 |
| F-018 | 编码前契约 | `sprint-contract` skill | Issue 进入 Building |
| F-019 | 反模式回流 | `post-merge` skill | PR 合并后 |

## 政策标签（本文件就地权威）

不值得单独建 skill 的短期/timeboxed policy 直接在本段定义。

### F-004 — 内测不做 Schema 迁移

**规则**：内测期（App Store 上架前）SwiftData 模型变更不走 schema migration，直接 reset 本地数据库。任何破坏性 Model 改动只需保证编译通过 + 测试通过，不需要写 `SchemaMigrationPlan`。

**理由**：内测用户少 + 数据无价值，写 migration 是反 ROI；上架后真实用户数据进入才需要严肃迁移。

**触发**：改 `Packages/*/Models/*.swift` 或任何 `@Model` 类型的字段时。

**Timebox**：`review_after: 2026-07-01`，`sunset: App Store 上架后强制废止`。届时本段移入退役表，启用正式 migration 流程。

## 触发方式声明语义

「触发方式」列是**典型场景关键词**，不是穷举的精确触发条件：
- `所有 git 操作`：≠ 每一条 git 命令都强制触发；指**关键 git 操作（push / merge / branch 切换 / commit msg 体例）需遵守 F-001**。日常 `git status / log / diff` 不触发
- `编码时`：泛指代码改动场景；具体触发由各 skill 的 frontmatter / 启动逻辑决定
- `所有 PR review`：含人审 + 各 agent 自审 + Codex/Gemini 委派 review 留痕，不限于 GitHub PR comment

不同 F-rule 的实际触发覆盖率因 skill 实现而异；用 `docaudit rule-usage` 和 commit log grep 复核实际应用率，而非依赖触发方式列的字面表达。

## 编号规则

- 格式 `F-NNN`（三位数字零 padding）
- 编号单调自增，退役不复用
- 新规则先在对应 skill/rule 文件中定义，再在本表追加一行

## 退役记录

以下编号已退役，保留供历史 git log 溯源：

| 编号 | 退役日期 | 去向 |
|---|---|---|
| F-002 | 2026-05-19 | 字面悬空、无 skill/PR 引用；事实上由 `docs/standards/engineering.md` 原则 2 + `docs/KNOWLEDGE_MAP.md` 路由覆盖，编号无独立价值 |
| F-003 | 2026-04-22 | 合并入 DOC_DEPENDENCY_MAP.md |
| F-009 | 2026-04-22 | 合并入 review-prompt-guide.md |
| F-010 | 2026-04-22 | 合并入 protocol.md |
| F-015 | 2026-04-22 | 合并入 F-007 |
| F-020 | 2026-04-21 | 合并入 F-005 |
