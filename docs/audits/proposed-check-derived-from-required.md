---
last_verified: 2026-05-25
layer: snapshot
scope: proposed-check
derived_from: [M-005 §G.4, M-005 §G.6]
freshness:
  max_age_days: 90
  decay_trigger: [check_implemented, check_promoted_to_optional, check_promoted_to_core]
---

# Proposed Check — `derived_from_required`

> M-005 §G.4 提案路径要求：新 check 进入可选列表前必须有 proposed-check 文档（含目的、事故/风险来源、检测方法、误报率估算、预期消费端）。本文为 `derived_from_required` 的提案文档。Codex GUI sign-off [#024 BLOCK 修复](../meta/user-decision-log.md#024) 触发补齐。

## 1. 目的

强制非产品 docs/ 文档 frontmatter 包含 `derived_from:` 字段（数组形式），实现 M-000 §11 SSOT 注册表向文档自身的派生锚传导。

## 2. 事故来源

[#022](../meta/user-decision-log.md#022) ratify M-000 §11 v2 SSOT 注册表后，[#023](../meta/user-decision-log.md#023) 深度审计发现 D1 维度（frontmatter `derived_from:`）缺失率 95%+（102/103 文件）。M-000 §11 注册完整（自上而下）但派生锚未传导到文档自身（自下而上），构成 SSOT 单向闭环漏洞。

## 3. 风险模型

- **派生关系不可追溯**：开发者读单文件无法知道派生归宿，必须跳到 M-000 §11 查表
- **派生归宿漂移**：§11 注册随 ratify 演进，但文档自身 frontmatter 不同步会失锚
- **新文档无锚入库**：缺少机械门禁，新增非产品文档可能不写 `derived_from:` 也通过 docaudit

## 4. 检测方法（详细）

详见 M-005 §G.6 检测方法 4 步。摘要：

1. 扫描范围：`docs/**/*.md`，路径硬豁免 `docs/product/**` + `docs/archive/**` + `docs/tech/**`
2. 缺字段：`scope: product-support` 显式豁免；否则 warning（30 天宽限）/ error（过期）
3. 格式校验：必须 array of strings；元素格式正则 `^M-\d{3}(\s§\d+(\.\d+)?)?$` 或 `^user-decision-log\s#\d{3}$`
4. 锚有效性：M-NNN §N 必须在 M-000 / M-001~M-006 中可定位

## 5. 误报率估算

**修正后估算 <5%**（Codex GUI sign-off 修正：原 <10% 未考虑 docs/tech/ 缺 scope 字段会被全报）。

误报来源：
- §11.7 边界判断（如 docs/tech/architecture.md 是否真属产品支撑）
- 跨规则派生（如 cross-audit-workflow → M-001 + M-003，schema 校验「>3 源应再审」）
- 待 ratify 元规则锚（M-002/M-006 未 ratify 时引用合规但实质未生效）

## 6. 预期消费端

- `Scripts/audit/docaudit.py` 新增 `--check derived-from-required` 子命令（**未实现**）
- `docs/standards/execution-gates.md` `optional_checks` 表登记（**未登记**）
- M-000 §11.10 schema 规则（**已 ratify**）

## 7. 升级路径（严格遵循 M-005 §G.4）

| 阶段 | 状态 | 触发 |
|---|---|---|
| **第一阶段 proposed** | ✅ 当前 | 本文档 + M-005 §G.6 设计入档 |
| 第二阶段 optional | ⏸️ 待 | docaudit 子命令实现 + execution-gates 登记 + ≥1 家异源评估 |
| 第三阶段 候选升核心 | ⏸️ 待 | ≥3 次审计运行 + 30 天观测（≤2026-06-25 之外另算）+ 误报率 <20% |
| 第四阶段 核心 | ⏸️ 待 | §G.2 满足后升 core_checks 表 + error 级 + 阻塞 PR |

## 8. 异源评估状态

- **Antigravity GUI**：✅ PASS（[#024 sign-off](signoff-antigravity-gui-023-024.md)，5 维全 PASS）
- **Codex GUI**：⛔ BLOCK（[#024 sign-off](signoff-codex-gui-023-024.md)）→ 触发本提案文档 + §G.6 修正
- Codex GUI 重 sign-off：⏸️ 待修复后重跑

## 9. Overrule 关系

无。本提案是 [#024](../meta/user-decision-log.md#024) ratify 的配套（修复 Codex BLOCK 后补齐 §G.4 路径合规性）。
