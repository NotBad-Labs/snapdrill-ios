---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-003 三方修复方案 — Cross-Fix-Consensus（Phase 11 收官）

> Phase 11 B 方案串行第三战收尾 + Phase 11 整体收官（**F-018 Sprint Contract 机械拦截**）。
> Claude CLI 主笔，融合 **Codex 完整字段 schema** + **Antigravity Scope Creep 实时防御** + Claude 盲区清单。
>
> 单家产出：[claude](S-D7-003-claude.md) · [codex](S-D7-003-codex.md) · [antigravity](S-D7-003-antigravity.md)
> 任务定义书：[S-D7-003-fix-task-definition.md](S-D7-003-fix-task-definition.md)

## 1. 三家共识（3/3 命中）

| 共识点 | 内容 |
|---|---|
| 拦截位置 | Claude `PreToolUse(Edit\|Write\|MultiEdit)` hook 主拦截 |
| 历史 Issue | 不追溯，新 Edit 起机械化 |
| 与 S-D7-002 联动 | 复用 hook 框架 + 字段化 schema + placeholder 防御 + glob ** 工具 |
| Override 哲学 | `F018_SPRINT_CONTRACT_OVERRIDE=1` 单 override + stderr 留痕 |
| 命名约定 | `.github/sprint-contract-policy.yml` + `Scripts/audit/sprint_contract_*.py` |
| Issue 状态识别 | 环境变量 > branch > fallback 三层 |
| Appetite=Small | 不完全豁免，走简化字段（Touches / No-Touch / DoD）|

## 2. 三家差异点对比（关键分歧）

| 维度 | Claude v2 | Codex | Antigravity |
|---|---|---|---|
| **拦截强度** | 渐进硬化（3 次软警告后硬阻断）| **默认硬阻断**（明确反对软警告）| **默认硬阻断**（同 Codex）|
| **Scope Creep 实时防御** | ❌ 不触及 | ❌ 不触及 | ✅ **`check_file_scope` 比对 Touches/No-Touch globs**（独家）|
| **离线兜底** | ❌ | ❌ | ✅ **`.git/sprint_contract_offline.json` 离线锁**（独家）|
| **字段 schema 完整度** | keyword 校验（Touches/No-Touch/DoD）| **完整 12 字段**（Issue Type/Appetite/Status/Interface Delta/Test Additions/Uncertainties/Contract Author 等）| Appetite 三级（small/medium/large）字段差异化 |
| **多行 bullet 字段解析** | ❌ | ✅ **明确支持 `Touches:` 后跟 bullet list** | ✅ 支持 |
| **共享工具抽取** | `from pr_review_trace import` 直接复用 | **建议抽 `Scripts/audit/governance_policy.py`**（更彻底）| 重复实现 _glob_to_regex（设计较粗）|
| **PR closingIssuesReferences** | 间接 | ✅ **明确反查 Issue**（独家）| ❌ |
| **锁文件 / 运行时监督** | ❌ | ❌ | ✅ **运行时检查文件 vs Touches**（独家）|
| **Issue building label** | 默认假设 OPEN | ✅ 明确 `status:building` | ✅ building label |
| **Issue 第三 fallback** | commit msg ref | gh pr view closingIssuesReferences | STATUS.md task ID |
| **测试规范度** | 7 场景 unittest | **7 unittest + mock + 字段级断言** | 设计层 |
| **盲区诚实度** | **7 触发器最全** | 8 条 | 4 条 |

## 3. 综合裁决

### 评分矩阵（1-5 分）

| 维度 | Claude v2 | Codex | Antigravity |
|---|---|---|---|
| 正确性 | 4 | 5 | 5 |
| 拦截强度立场 | 3（渐进路线被多数反对） | **5** | **5** |
| Scope Creep 实时防御 | 2 | 2 | **5**（独家创新）|
| 字段 schema 深度 | 3 | **5**（最完整）| 4 |
| 多行字段解析 | 2 | **5** | 4 |
| 共享工具抽取设计 | 4 | **5**（governance_policy.py 抽取更彻底）| 2 |
| 离线兜底 | 2 | 2 | **5**（独家）|
| PR closingIssuesReferences | 3 | **5** | 2 |
| 运行时监督 | 2 | 2 | **5**（独家）|
| 测试规范度 | 4 | **5** | 4 |
| 盲区诚实度 | **5** | **5** | 4 |
| **总分** | **34** | **48** | **45** |

### 最强方案：**Codex 完整字段 schema 基础 + Antigravity Scope Creep 防御 + Claude 盲区清单**

**Codex 显著胜出**理由：
1. **完整字段 schema**（12 字段）远比 Claude keyword 校验深入
2. **多行 bullet 字段解析**（`Touches:` 后跟 list）支持真实 contract 体例
3. **PR closingIssuesReferences 反查** 增加 Issue 识别可靠性
4. **建议抽 `Scripts/audit/governance_policy.py`** 共享工具更彻底
5. **拒绝软警告 + 默认硬阻断** 与 Antigravity 共识，反对 Claude 渐进路线

### 采纳 Antigravity 关键增强

1. **Scope Creep 实时防御**（`check_file_scope` 比对当前 Edit 文件 vs Touches/No-Touch）—— **独家高价值**
2. **三级 Appetite 字段差异化**（small 3 字段 / medium 5 字段 / large 6 字段）
3. **离线兜底**（`.git/sprint_contract_offline.json`）—— 留 follow-up，第一版盲区列出

### 采纳 Claude 增强

- **7 条 future-proof 盲区清单**（最细致）
- **premerge-checklist.sh 闭环 closeout 校验** 模式（与 S-D7-002 共享 hook 同模式）

### 立场重大共识

**采纳 Codex/Antigravity 立场：默认硬阻断**（exit 2），**反对** Claude 渐进路线。

理由：
- 现有数据 0/9 应用率说明软方法已经失败
- `F018_SPRINT_CONTRACT_OVERRIDE=1` + docs/* 路径放行已经提供逃生路径
- Claude 自身被 hook 阻断的 meta loop 通过 override 解决，不是通过软警告

## 4. 融合方案（最终 apply）

### 4.1 文件清单

| 文件 | 操作 | 来源 |
|---|---|---|
| `.github/sprint-contract-policy.yml` | **新增** | Codex 12 字段 schema + Antigravity placeholder + Scope Creep |
| `Scripts/audit/sprint_contract_gate.py` | **新增** | Codex 字段解析 + Antigravity check_file_scope |
| `Scripts/audit/tests/test_sprint_contract_gate.py` | **新增** | Codex unittest 模式 |
| `.claude/hooks/pre-edit-sprint-contract.sh` | **新增** | PreToolUse Edit hook，默认硬阻断 |
| `.claude/settings.json` | **扩展** | 注册 PreToolUse Edit hook |
| `.claude/hooks/premerge-checklist.sh` | **扩展** | 串接 F-005 + F-007 + F-018 closeout |
| `.github/ISSUE_TEMPLATE/feature_request.md` | **扩展** | 字段化 contract 模板 |
| `.github/ISSUE_TEMPLATE/chore.md` | **扩展** | Small 简化模板 |
| `.claude/skills/sprint-contract/SKILL.md` | **扩展** | 字段化输出引导 + Closeout 段 |
| `.github/workflows/ci.yml` | **扩展** | sprint-contract-trace job + unittest |
| `docs/workflow.md` | **不改** | F-018 段保持纪律强度 |

### 4.2 关键技术决策

**字段化 contract 体例**（Codex schema）：

```markdown
## Sprint Contract

Contract Required: yes
Issue: #123
Issue Type: enhancement
Appetite: Medium
Status: Building
Touches:
- Packages/SnapDrillCore/Sources/Foo.swift
- Packages/SnapDrillCore/Tests/FooTests.swift
No-Touch:
- Packages/SnapDrillData/**
- SnapDrillShare/**
Interface Delta:
- public func buildFoo(input: FooInput) async throws -> FooResult
Test Additions:
- FooTests.testBuildFooRejectsInvalidInput
DoD Minimum:
- swiftlint --strict
- xcodebuild build-for-testing -scheme AllTests -testPlan AllTests
Uncertainties:
- Existing repository API may already cover query path; verify before adding abstraction.
Contract Author: claude
```

**Scope Creep 实时防御**（Antigravity 独家融合到 hook）：

```python
# 在 hook 拿到 Edit 目标文件后
if file_in_no_touch_globs(file_path, contract['No-Touch']):
    exit 2  # 越界阻断
if not file_in_touches_globs(file_path, contract['Touches']):
    exit 2  # Touches 外阻断（除非是 STATUS.md 等流程文件白名单）
```

### 4.3 推迟到 follow-up

- Antigravity 离线锁文件 `.git/sprint_contract_offline.json`（盲区清单列出）
- Codex `Scripts/audit/governance_policy.py` 共享工具抽取（本任务 sprint_contract_gate.py 暂用 `from pr_review_trace import` 复用模式）
- commit msg `F-018-Sprint-Contract:` trailer 兜底直推（参考 S-D7-002 `F-005-Review-Trace:` 模式，留 follow-up）

## 5. Apply 计划

1. ✅ 写本 consensus 文件
2. apply policy YAML（Codex 字段 schema + Antigravity placeholder）
3. apply Python gate.py（Codex 字段解析 + Antigravity check_file_scope）
4. apply unittest 测试套件
5. apply pre-edit-sprint-contract.sh hook
6. apply .claude/settings.json hook 注册
7. apply premerge-checklist.sh closeout 扩展
8. apply issue templates 字段化
9. apply sprint-contract skill 输出引导
10. apply ci.yml sprint-contract-trace job
11. 跑 unittest + docaudit
12. ledger 翻面 S-D7-003 OPEN → RESOLVED → **Phase 10 86 finding 全部关闭**
13. STATUS / handoff 翻面到「Phase 11 收官 + 100% 关闭率」
14. commit + push + 清最后两个 worktree

## 6. 已知盲区（融合三家 + 实战补充，7 条 future-proof）

| 盲区 | 处理 | 重审触发条件 |
|---|---|---|
| Antigravity 离线锁文件未在第一版 | follow-up 实现 `.git/sprint_contract_offline.json` | 出现真实离线开发场景 |
| Codex 抽 `governance_policy.py` 共享工具未在第一版 | 本版 sprint_contract_gate.py 复用 `from pr_review_trace import` | 第二个共享工具被引入时 |
| `F018_SPRINT_CONTRACT_OVERRIDE=1` 滥用 | 每次 override 写 stderr 留痕（与 S-D7-002 共哲学）| 滥用率高时 prompt 输入豁免理由 |
| Issue 用 GitHub Projects field 标 Building 而非 label | 第一版强制 `status:building` label；GraphQL projects 留 follow-up | 团队切换到 GitHub Projects |
| 假阴性：Touches 漏列实际改动 | hook 校验 contract 存在 + Scope Creep；scope fidelity 仍需 cross-audit 抽检 | 多人协作时 |
| 渐进迁移期：现有 Issue 没 contract → Edit 被阻 | bug label 自动豁免 + docs/* 路径放行 + override 兜底；用户用 `gh issue comment` 立即解锁 | 初期摩擦大时考虑临时豁免 |
| commit msg trailer 兜底（F-018-Sprint-Contract:）未实现 | 参考 S-D7-002 `F-005-Review-Trace:` 模式，留 follow-up | 直推 develop 场景频繁出现时 |

## 7. Phase 11 整体收官观察

| 战 | finding | 胜出 | 关键创新 |
|---|---|---|---|
| **首战 S-D7-001** | docaudit rule-usage bug | Codex 双正则简洁 | F-rule declared 集合修复 |
| **第二战 S-D4-002** | 通知 ID Multi-Profile | Antigravity 临时 apply 实证 | facade pattern 测试隔离 |
| **第三战 S-D4-001** | ServiceContainer DI 退化 | Antigravity 46 分实证 | 8 服务挂入 + inject() 后置 |
| **第四战 S-D7-002** | F-005 PR review 留痕 | Codex 51 分字段化 schema | placeholder defense + glob ** |
| **第五战 S-D7-003** | F-018 Sprint Contract 拦截 | **Codex 48 字段 schema + Antigravity 45 Scope Creep** | check_file_scope 实时越界防御 |

**Worktree 工作流观察**：
- **物理隔离效果**：5 战全部三家分歧真实（不同维度的最强方案）
- **模型差异化能力**：Codex 工程严谨化（字段 schema） / Antigravity 防御创新（Scope Creep / 锁文件 / 离线兜底） / Claude 盲区清单
- **用户决策影响**：S-D4-001 后用户提议串行（vs B 方案并行）是关键决策，避免了 S-D7-002/003 框架空想式协同
- **B 方案重写**：Claude S-D7-003 v2（基于 S-D7-002 实际框架）证明「公开主线」是公平上下文，不算控制变量法污染

## 8. 关联

- [worktree-audit-workflow](../standards/worktree-audit-workflow.md) Phase 11+ 标准
- [S-D7-002-fix-consensus](S-D7-002-fix-consensus.md) **本提案复用其框架**
- [S-D4-001-fix-consensus](S-D4-001-fix-consensus.md) Phase 11 串行第一战
- `Scripts/audit/pr_review_trace.py` / `.github/review-trace-policy.yml` S-D7-002 落地基础设施
- `.claude/skills/sprint-contract/SKILL.md` 现有 skill（本任务加 §字段化输出 + §Closeout 引导）
- `docs/workflow.md` §编码前契约（**不改**，保持纪律强度）
