---
last_verified: 2026-05-18
layer: pattern
---
# 项目纪律索引（F-NNN 规则）

> F 规则已 skill 化 / rule 化。本文件为索引，不做权威定义源。
> 各规则的权威定义在其对应的 skill 或 rule 文件中。

## 规则路由

| 编号 | 规则 | 权威源 | 触发方式 |
|---|---|---|---|
| F-001 | Git 工作流纪律 | `.claude/rules/f-001-git-workflow.md` | git 操作时自动加载 |
| F-002 | 产品文档优先 | `.claude/rules/f-002-product-first.md` | 文档操作时自动加载 |
| F-004 | 内测不做 Schema 迁移 | `.claude/rules/f-004-no-schema-migration.md` | Model 文件变更时加载 |
| F-005 | 对抗性审查 | `cross-audit` skill + `post-merge` skill | PR 提交/合并时 |
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

## 编号规则

- 格式 `F-NNN`（三位数字零 padding）
- 编号单调自增，退役不复用
- 新规则先在对应 skill/rule 文件中定义，再在本表追加一行

## 退役记录

以下编号已退役，保留供历史 git log 溯源：

| 编号 | 退役日期 | 去向 |
|---|---|---|
| F-003 | 2026-04-22 | 合并入 DOC_DEPENDENCY_MAP.md |
| F-009 | 2026-04-22 | 合并入 review-prompt-guide.md |
| F-010 | 2026-04-22 | 合并入 workflow.md |
| F-015 | 2026-04-22 | 合并入 F-007 |
| F-020 | 2026-04-21 | 合并入 F-005 |
