---
last_verified: 2026-05-21
layer: pattern
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-001 三方修复提案 — 任务定义书

> Phase 11 首个 worktree 物理隔离任务。三家共享同一份任务定义，独立产出修复方案 + 测试用例。
>
> Claude CLI / Codex 桌面端 / Antigravity 三家用完全相同的任务定义书，物理隔离在三个 worktree 内独立工作。

## Bug 描述

**症状**：`Scripts/audit/docaudit.py` 的 `rule-usage` check（Phase 4 从 9 → 11 check 升级时加入）实际只把 1 条 F-rule 识别为「declared」，但 `docs/memory/feedback.md` 当前有 13 条 active F-rule 应当被识别。

**根因区域**：`Scripts/audit/docaudit.py` 处理 feedback.md 提取 declared F-rule 集合的逻辑（精确行号自行定位）。

**复现**：

```bash
cd <你的 worktree 根>
python3 Scripts/audit/docaudit.py rule-usage --debug 2>&1 | grep -i declared
# 或直接在 Python 交互环境调用相关函数 dump declared 集合
```

期望 declared 集合：所有 active F-rule（feedback.md 中标 active / 未标 retired 的 F-XXX 编号）。
实际 declared 集合：只有 1 条。

**Phase 10 抓到的证据**：维度 7 S-D7-001 finding，落档在 `docs/audits/audit-ledger-semantic-2026-05.tsv` 和 `docs/audits/semantic-audit-dim7-consensus.md`。
（**修复提案阶段不要读上述基线** — 你需要从代码本身验证。）

## 范围

| 项 | 内容 |
|---|---|
| 修复文件 | `Scripts/audit/docaudit.py` |
| 输入文件 | `docs/memory/feedback.md` |
| 不可改 | feedback.md 本身的格式（feedback.md 是 SSOT，工具适配 SSOT，不是反过来）|
| 周边影响 | 修复后需要重跑 `docaudit all --strict`，所有现存 declared/used/dead 报告会刷新 |

## 修复方案要求

### 1. 代码 diff

提供修复 patch（git diff 格式或完整新代码块），含：
- 修改文件路径 + 精确行号
- 修改前后对比
- 一行注释解释意图

### 2. declared 集合完整性验证

**强制要求**：你的方案必须在 worktree 实际跑过并 dump declared 集合，证明：
- 修复前 declared 集合大小（应为 1）
- 修复后 declared 集合大小（应为 feedback.md 当前 active F-rule 实际数量）
- 修复后 declared 集合内容（列出所有 F-XXX 编号）

### 3. 测试用例（边界覆盖）

至少覆盖以下边界，每条边界必须有显式断言或 dump 验证：

| 边界 | 应识别为 declared 吗 |
|---|---|
| feedback.md 当前 active F-rule 全集 | ✅ 全部识别 |
| feedback.md 标 retired 的 F-rule | 自行判断并解释（rule-usage check 的语义是查「active」还是「ever declared」？读代码上下文）|
| 假想：F-XXX 在文档中以加粗 `**F-001**` 形式声明 | 自行判断 + 写测试 |
| 假想：F-XXX 在文档中以列表项 `- F-001:` 形式声明 | 自行判断 + 写测试 |
| 假想：F-XXX 在文档中以行内 ``F-001`` 反引号形式提及 | 自行判断（注意区分 declaration site vs reference site）|
| F-XXX 三位数边界（F-001 / F-099 / F-999） | 全部识别 |
| 非 F-rule 误匹配（如「F-1」「F-1234」「F-FOO」）| **不**识别 |

### 4. 自检段

在你的产出报告末尾**必须**写一段「本方案的已知盲区」，列出：
- 当前修复**不**覆盖的边界情况（即使在测试用例之外）
- 为什么排除这些边界（是 YAGNI、还是 declaration site 语义就该排除）
- 如果未来 feedback.md 格式变化，本方案需要重审的触发条件

## 产出位置

落档到你的 worktree 的 `docs/audits/S-D7-001-<vendor>.md`（vendor = codex 或 antigravity）。

Claude CLI 主笔产出位置：`docs/audits/S-D7-001-claude.md`（主分支）。

## 验收标准

- ✅ diff 简洁，副作用可控（不动 declared 之外的逻辑）
- ✅ 修复后 `docaudit all --strict` Exit 0
- ✅ declared 集合大小匹配 feedback.md 当前 active F-rule 实际数量
- ✅ 至少 5 个显式测试断言
- ✅ 「已知盲区」段诚实，不空话

## 严禁操作

- 不要修改 `docs/memory/feedback.md` 本身
- 不要修改主分支 ledger / STATUS / handoff / ADR-005
- 不要 cherry-pick 主分支或其他 audit 分支
- 不要参考其他家产出 / 主分支已有的 Phase 10 consensus / ledger

## 收尾后行为

完成后：

1. 在你的 worktree commit + push 到你的 audit 分支
2. 回复用户：worktree 路径 + 分支名 + 产出文件路径
3. 停止，等 Claude CLI 主笔做 cross-fix-consensus

---

## Claude CLI 自约束

Claude CLI 主笔在主分支执行本任务时，**也走同样流程**：

- 在主分支 `docs/audits/S-D7-001-claude.md` 落档（不直接改 docaudit.py）
- 三家齐了之后再写 `S-D7-001-fix-consensus.md` 折叠 + 选最强方案 + apply
- Claude CLI 在主笔阶段才读其他家产出，独立产出阶段**不**读
