---
last_verified: 2026-05-21
layer: pattern
freshness:
  max_age_days: 90
  decay_trigger: [adr_change, methodology_change]
---
# Worktree 物理隔离工作流（Phase 11+ 标准）

> Phase 10 控制变量法污染实战教训沉淀。适用于一切「三方对抗任务」——审计、修 bug、方案选型、设计 review。
>
> **核心命题**：F-008「相同完整任务、不分工」纪律单靠提示词文字封堵不够；任何「Claude 已抓 X，请扫 Y」「不要重复」类语句都会被外审模型解读为分工指令，污染独立性。**物理隔离是唯一可靠手段**。

## 何时使用 Worktree 三方对抗

| 场景 | 是否走 worktree 三方 | 理由 |
|---|---|---|
| 新维度语义审计 | ✅ 必走 | Phase 10 实战证明文字封堵失败 |
| 真生产 bug 修复方案选型 | ✅ 必走 | LOC 小但正确性边界模糊的 fix（正则 / 边界条件 / 并发）|
| 高风险架构决策 | ✅ 必走 | ADR 提案前的对抗性视角 |
| 流程/治理类改动（hook、模板）| ⚠️ 可选 | 设计层走、纯实现可单家 |
| 纯机械工作（批量改 frontmatter、rename）| ❌ 不走 | 对抗成本 > 收益 |
| Skill body 微调、typo 修复 | ❌ 不走 | 同上 |

判断口诀：**「这件事如果做错，三家会不会以不同方式做错？」** 答 yes 就走 worktree。

## 工作流五步

### Step 1：主分支起草任务定义（Claude CLI）

主 worktree `/Users/yiming/Developer/snapdrill-ios` (develop 分支)：

1. Claude CLI 写一份 **任务定义书**，落档到 `docs/audits/<task-slug>-task-definition.md`，包含：
   - 任务目标（一句话）
   - 范围（文件清单 / 代码路径 / 判据）
   - 产出要求（finding 清单 / 修复方案 / 测试用例）
   - 验收标准
2. **不要在任务定义书里出现任何 Claude 已有结论 / 草拟方案 / 倾向性提示**——一字不差三家共用。
3. commit + push 到 develop（让 worktree 拉得到）。

### Step 2：建立两个 worktree

```bash
# 从主仓库根目录执行
git worktree add ../snapdrill-ios-codex -b audit/codex-<task-slug>
git worktree add ../snapdrill-ios-ag    -b audit/antigravity-<task-slug>
```

每个 worktree 是物理独立目录 + 独立分支。Codex / Antigravity 启动时 cd 到自己的 worktree，看不到 Claude CLI 在主 worktree 的进行中产出。

### Step 3：三家独立执行（同时启动，**不**串行）

| 工具 | 工作目录 | 分支 |
|---|---|---|
| Claude CLI | 主目录 `/Users/yiming/Developer/snapdrill-ios` | develop（产出落 `docs/audits/<task-slug>-claude.md`）|
| Codex 桌面端 | `../snapdrill-ios-codex` | `audit/codex-<task-slug>` |
| Antigravity | `../snapdrill-ios-ag` | `audit/antigravity-<task-slug>` |

每家用 **完全相同的任务定义书**（净化版提示词指向同一份 task-definition.md）。

**禁止串行启动**——Claude CLI 先跑会创造「先到优先」偏见，外审会被引导。

### Step 4：三方回汇

三家完成后：

1. Codex / Antigravity 在自己 worktree commit + push 产出（`docs/audits/<task-slug>-codex.md` / `<task-slug>-antigravity.md`）
2. 主 worktree 切回 Claude CLI 主笔
3. `git fetch --all` 拉所有 audit 分支
4. `git checkout audit/codex-<task-slug> -- docs/audits/<task-slug>-codex.md`（cherry-pick 单文件，不合并分支）
5. 三家产出聚齐主分支 develop
6. Claude CLI 写 `<task-slug>-consensus.md` 三方折叠报告
7. 落档相关 ledger / ADR / STATUS / handoff

### Step 5：清理 worktree

任务收尾后：

```bash
git worktree remove ../snapdrill-ios-codex
git worktree remove ../snapdrill-ios-ag
git branch -D audit/codex-<task-slug> audit/antigravity-<task-slug>  # 可选保留作 audit trail
```

## 提示词净化原则（Phase 10 反面教材）

### ❌ 禁用语句（Phase 10 实战污染源）

| 禁用句式 | 为什么被污染 |
|---|---|
| 「Claude CLI 已抓 X，避免重复」| 直接告诉外审分工切片 |
| 「不要重复列入 S-D*-* 编号」| 间接泄露 Claude 编号体系 + 暗示有共识基线 |
| 「Claude 没扫的差异化视角」| 明显的分工性表述 |
| 「请重点关注 Claude 可能漏的 Y 类」| 引导性指令，破坏独立判断 |
| 「参考 docs/audits/dim1-consensus.md」| 让外审看到 Claude 已有结论 |

### ✅ 净化句式

| 净化句式 | 原因 |
|---|---|
| 「在你自己的 worktree 独立审计 / 修复」| 强调物理隔离 |
| 「文件路径使用 worktree 相对路径」| 防止跨 worktree 读取 |
| 「产出与其他家可能重叠是正常的，刻意冗余即控制变量法精髓」| 反向校准外审认知 |
| 「不要刻意避开任何可能 finding」| 显式封堵分工冲动 |
| 「不要参考其他家产出，包括主分支已有 consensus 报告」| 显式封堵基线偷看 |

## 三方修 bug 工作流（新场景）

修 bug 时 task-definition.md 内容包含：

1. **bug 描述**（症状、根因区域、复现方式）
2. **范围**（文件路径 + 行号 + 周边函数）
3. **要求每家产出**：
   - 修复方案 diff
   - 测试用例（覆盖 N 个边界情况）
   - 完整 declared 集合 / 输入空间验证
   - 自检：本方案可能漏的边界
4. **禁止**：参考其他家方案、参考主分支已有提案

三家方案聚齐后 Claude CLI 主笔 `cross-fix-consensus.md`，按下列维度选最强方案：

- 覆盖率（边界情况数）
- 简洁度（LOC / 圈复杂度）
- 副作用（diff blast radius）
- 测试可验证性

合并后的最终方案仍需走第二轮三方独立 review（不只看代码，要跑断言）。

## 关联

- [ADR-005](../decisions/ADR-005-doc-semantic-layer-audit.md) §Phase 10 五大方法论实战教训 + [Phase 10 全局收官历史快照](../archive/audits/phase10-semantic-audit-snapshot.md#phase-10-全局收官)
- [S-D7-001 任务定义书](../archive/audits/S-D-series/S-D7-001-fix-task-definition.md) Phase 11 首个 worktree 实战任务（工具 bug）
- [S-D4-002 任务定义书](../archive/audits/S-D-series/S-D4-002-fix-task-definition.md) Phase 11 第二个 worktree 任务（首个真生产 bug 三方修复）
- [S-D4-002 三方修复 consensus](../archive/audits/S-D-series/S-D4-002-fix-consensus.md) 第二战收尾报告（Codex 4 层 namespace + facade 测试架构胜出）
- 三家原始产出（S-D4-002）：[claude](../archive/audits/S-D-series/S-D4-002-claude.md) · [codex](../archive/audits/S-D-series/S-D4-002-codex.md) · [antigravity](../archive/audits/S-D-series/S-D4-002-antigravity.md)
- [S-D4-001 任务定义书](../archive/audits/S-D-series/S-D4-001-fix-task-definition.md) Phase 11 B 方案三任务并行（ServiceContainer DI 系统性退化重构）
- [S-D7-002 任务定义书](../archive/audits/S-D-series/S-D7-002-fix-task-definition.md) Phase 11 B 方案三任务并行（F-005 PR review 留痕机械化）
- [S-D7-003 任务定义书](../archive/audits/S-D-series/S-D7-003-fix-task-definition.md) Phase 11 B 方案三任务并行（F-018 Sprint Contract 机械拦截）
- [S-D4-001 三方修复 consensus](../archive/audits/S-D-series/S-D4-001-fix-consensus.md) Phase 11 B 方案串行第一战收尾（ServiceContainer DI 系统性退化重构，Antigravity 实证胜出 46 分）
- 三家原始产出（S-D4-001）：[claude](../archive/audits/S-D-series/S-D4-001-claude.md) · [codex](../archive/audits/S-D-series/S-D4-001-codex.md) · [antigravity](../archive/audits/S-D-series/S-D4-001-antigravity.md)
- [S-D7-002 三方修复 consensus](../archive/audits/S-D-series/S-D7-002-fix-consensus.md) Phase 11 B 方案串行第二战收尾（F-005 PR review 留痕机械化，Codex 字段化 schema 胜出 51 分）
- 三家原始产出（S-D7-002）：[claude](../archive/audits/S-D-series/S-D7-002-claude.md) · [codex](../archive/audits/S-D-series/S-D7-002-codex.md) · [antigravity](../archive/audits/S-D-series/S-D7-002-antigravity.md)
- [S-D7-003 三方修复 consensus](../archive/audits/S-D-series/S-D7-003-fix-consensus.md) **Phase 11 收官战**（F-018 Sprint Contract 机械拦截，Codex 48 分字段 schema + Antigravity 45 分 Scope Creep 实时防御）
- 三家原始产出（S-D7-003）：[claude](../archive/audits/S-D-series/S-D7-003-claude.md) · [codex](../archive/audits/S-D-series/S-D7-003-codex.md) · [antigravity](../archive/audits/S-D-series/S-D7-003-antigravity.md)
- [S-D7-001 三方修复 consensus](../archive/audits/S-D-series/S-D7-001-fix-consensus.md) 首战收尾报告（含三家产出对比 + 评分矩阵 + 工作流自评）
- 三家原始产出：[claude](../archive/audits/S-D-series/S-D7-001-claude.md) · [codex](../archive/audits/S-D-series/S-D7-001-codex.md) · [antigravity](../archive/audits/S-D-series/S-D7-001-antigravity.md)
- [[semantic-audit-dim7-consensus]] §Worktree 工作流 + §控制变量法污染反思
- [[single-vendor-audit-prompt-template]] 净化版提示词模板（Phase 11+ 适用）
- [[F-008]] 「相同完整任务、不分工」纪律

## 历史

- 2026-05-21：Phase 10 维度 5-7 控制变量法污染（Antigravity 抄 Claude 编号、Codex 定向避开 Claude finding）触发本 SSOT 创建
- 维度 7 S-D7-W01 ledger 记录污染样本作 audit trail
