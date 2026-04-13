# 误导性文档审计（Batch 1）

> 日期：2026-04-13  
> 基线：`#583`（Codex Baseline v1 文档治理）  
> 范围：第一方文档（`docs/**`, `README.md`, `STATUS.md`, `.github/**`, `CODEX.md`）  
> 排除：第三方开源文档、`.claude/worktrees/**` 镜像副本

## 审计目标

1. 以“文档为唯一事实源”落实可执行边界。  
2. 清理会误导开发/测试/协作的过时规则与引用。  
3. 固化 `#583` 后历史 issue/PR 的继承口径，避免被历史上下文反向驱动。

## 结论（Batch 1）

- 高风险误导项：1 项（已修复）
- 中风险误导项：2 项（已修复）
- 未决项：0

## 发现与处置

### F-001（高）PR 模板仍引用已退役规则路径

- 现象：`.github/PULL_REQUEST_TEMPLATE.md` 要求遵守 `.claude/rules/`。  
- 风险：新 PR 按过时路径执行，直接误导 review 与合规核对。  
- 处置：改为 `docs/agent/rules/`。  
- 状态：✅ 已修复。

### F-002（中）PR 模板文档同步清单与治理规则不一致

- 现象：模板缺少 `PRD` 与 `docs/tech/design/*.md` 触发项，也未声明“仅治理第一方文档”。  
- 风险：实现与文档回写口径不一致，容易形成“代码先改、文档漏改”。  
- 处置：补齐对应清单项，与 `docs/workflow.md` 对齐。  
- 状态：✅ 已修复。

### F-003（中）缺少 `#583` 后历史 issue/PR 继承规则

- 现象：缺少明确条款说明“历史项默认参考，不自动继承承诺”。  
- 风险：后续执行可能被历史过程性上下文牵引，偏离当前 SoT。  
- 处置：在 `docs/workflow.md` 增加“Baseline 切换策略（2026-04-13 / #583）”章节。  
- 状态：✅ 已修复。

## 当前 SoT 口径（执行摘要）

- 源头裁决顺序：`product-vision` → `PRD` → ADR → 设计/合规层 → 用例/旅程/术语层 → 映射/快照层。  
- `architecture` / `api-reference` / `STATUS` / `docs/memory/*` 仅记录映射与状态，不反向定义事实。  
- 历史 issue/PR 默认“参考证据”；仅在冲突、风险、事实不一致时继承为当前行动项。

## 下一批（Batch 2）建议范围

1. 产品层交叉核对：`PRD` vs `product-requirements` vs `product-cases` 的承诺一致性。  
2. 合规层证据化：`docs/tech/compliance.md` 中“待补充证据”闭环计划。  
3. 快照层去噪：`STATUS.md` 中历史工具品牌叙述最小化，避免被误读为执行约束。
