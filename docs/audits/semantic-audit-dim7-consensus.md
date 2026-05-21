---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# 语义层维度 7 — 三方对抗共识报告（F-rule 实际遵守度）

> **日期**：2026-05-21 | **维度**：7 F-rule 实际遵守度（**Phase 10 最后一维度**）| **三方**：Claude CLI / Codex 桌面端 / Antigravity (Gemini 3.5 Flash (High))
>
> **方法**：F-008「相同完整任务、不分工」+ 控制变量法。三家独立审 F-001~F-020 (14 active + 6 retired)。
>
> ⚠️ **本维度同时是 Phase 10 控制变量法污染最严重的一维**——详见下方「污染反思」段。
>
> 单家原始报告：
> - Claude CLI：本会话上下文 (4 finding：1H/1M/1L/1INFO)
> - Codex 桌面端：本会话上下文 (5 finding：1H/1M/2L/1INFO；明确写「不重复 Claude C7.1-C7.4」)
> - Antigravity：[`semantic-audit-dim7-findings.md`](semantic-audit-dim7-findings.md) (5 finding：1H/1M/1L/2INFO；C7.1-C7.4 直接复制 Claude 编号 + C7.5 真独家)
>
> 共识 ledger：[`audit-ledger-semantic-2026-05.tsv`](audit-ledger-semantic-2026-05.tsv) S-D7-001 ~ S-D7-010 + S-D7-W01 (污染样本)

## 三家分布对比

| 项目 | Claude | Codex | Antigravity |
|---|---|---|---|
| 真独立 finding | 4 | 5 (明确避开 Claude 编号) | **1**（C7.5 工具 bug，真独家）|
| 复制/抄袭 | — | 提示词污染→定向避开 | **C7.1-C7.4 直接复制 Claude 编号** |
| HIGH | 1 | 1 | 1 |
| MEDIUM | 1 | 1 | 1 |
| LOW | 1 | 2 | 1 |
| INFO | 1 | 1 | 2 |

**Antigravity C7.5 是 Phase 10 致命独家**——撕破 docaudit.py 工具底层 bug，推翻维度 5 S-D5-013 结论基础。

## 折叠总览

| 共识等级 | 数量 |
|---|---|
| 2/3 共识 | 1 (S-D7-010 元层级自指 INFO，Claude+Antigravity) |
| 1/3 单家可采纳 | 9 |
| **合计 OPEN** | **10**（HIGH×3 MEDIUM×2 LOW×3 INFO×2）|
| WAIVED | 1 (S-D7-W01 控制变量法污染样本)|

## 3 个 HIGH

### S-D7-001 [HIGH, 1/3 Antigravity 独家] — docaudit.py:593 rule-usage check 工具 bug

**Phase 10 致命独家**。`docaudit.py:593` 正则 `^#{1,4}\s+F-(\d{3})\b` 只匹配 Markdown 标题，但 feedback.md 13 个 active F-rule 全在 line 14-27 **表格行**声明（`| F-001 | ... |`）。

实跑 docaudit declared 集合：**`['004']`**——只有 F-004 因为 line 33 `### F-004 —` 标题被识别。

**连锁后果**：
1. 整个 rule-usage check 从 Phase 4 升级（9→11 check）以来未真正工作过
2. **维度 5 S-D5-013 结论被推翻**——「F-004 has 0 external references」是 broken 工具结果，不是真情况
3. 维度 1-6 + 结构层 Phase 0-9 都漏的工具底层 bug

**修复**：`Scripts/audit/docaudit.py:593` 改为 `r'^#{1,4}\s+F-(\d{3})\b|^\|\s*F-(\d{3})\s*\|'` 兼容表格行；S-D5-013 重审。

### S-D7-002 [HIGH, 1/3 Codex 独家] — F-005 PR #742 真不留痕样本

**真生产级 F-rule 违规**。PR #742「docs: 归零审计 — engineering 重写 + workflow/coding 修订 + 下游同步」MERGED：
- reviews: 0
- comments: 0
- body 无 Codex/Gemini/Xcode review 留痕

违反 `workflow.md:108-120`「所有 PR review 后合并且必须留痕」+ F-005 对抗性审查纪律。

**修复**：强化 merge 前 review 留痕检查 hook 或明确 docs-only/trivial PR 豁免条件。

### S-D7-003 [HIGH, 1/3 Claude 独家] — F-018 Sprint Contract 实际应用率极低

实证抽样：
- enhancement Issues #159/#137/#136/#31/#30 = **0/5 有 contract**
- chore Issues #735/#684/#718/#720 = **0/4 有 contract**
- 仅 epic #766 有

F-018 **dead-on-paper / alive-in-skill / not-applied-in-practice 三态真漂移**。

**修复**：sprint-contract skill 改进 + CLI Hook 引入机械拦截阻断（Issue Building 状态 + 无 Sprint Contract → 阻断代码修改权限）。

## 2 个 MEDIUM

### S-D7-004 [MEDIUM, 1/3 Codex] — F-007 hook 自动化弱于声明

feedback.md L18 + execution-gates.md:68 都声明「post-merge skill + **hooks** 执行 F-007 CI 双时点」，但实际：
- `premerge-checklist.sh` 只查 STATUS 24h 更新
- `post-merge-checkpoint.sh` 只查 checkpoint + anti-pattern
- **CI 时点 2 只在 post-merge SKILL.md 手动 Step 1 由 Claude 跑 `gh run list`**

**修复**：改 execution-gates 为「manual skill gate」或让 hook 真做 `gh run list` 检查。

### S-D7-005 [MEDIUM, 1/3 Claude] — F-001 「所有 git 操作」过度声明

1372 commits 中只有 11 commit msg 显式标 F-001 (<1%)。

## 3 个 LOW + 2 个 INFO

详见 [`audit-ledger-semantic-2026-05.tsv`](audit-ledger-semantic-2026-05.tsv) S-D7-006 ~ S-D7-009。

## S-D7-010 元层级自指悖论（2/3 Claude+Antigravity）

维度 5 S-D5-013 抓 F-004 dead rule，落档后引用让 F-004 不再 dead。**但 S-D7-001 工具 bug 推翻该判断基础**——「F-004 0 references」是 docaudit broken 不是真情况。S-D5-013 重审。

---

## 控制变量法污染反思（S-D7-W01）

### 三家被同源污染的证据

| 现象 | 证据 |
|---|---|
| Codex 提示词污染 | Codex 维度 7 回复明说「我不重复 Claude 已抓的 C7.1~C7.4」← 是因为我提示词写了「Claude CLI 已抓（避免重复）」段 |
| Antigravity 抄袭 | Antigravity 输出 finding 编号直接用 C7.1 / C7.2 / C7.3 / C7.4 / C7.5——**C 前缀是 Claude 编号体系**，前 4 项直接复制 Claude 原文 |
| 维度 5-7 全被污染 | 维度 5/6/7 提示词都有「Claude CLI 已抓 X，避免重复」段，污染连续 3 维度 |

### 违反控制变量法精髓

控制变量法 = 三家做**完全相同**任务，**刻意冗余**，让模型差异通过**共识/分歧**暴露。

我做的 = 给 Codex/Antigravity 指定「差异化范围」（Claude 已抓 A 类，请扫 B 类）= **分工**，正是 F-008 禁止的。

### 假阳性后果

维度 5-7 显示的「2/3 共识少 + Codex/Antigravity 独家多」可能是**提示词污染产物**，不是真实模型差异。真实 3/3 共识 finding 可能比 ledger 显示的多得多。

### 但模型差异化能力仍真实存在

即使被污染，**Antigravity 仍抓到 C7.5 docaudit.py 工具 bug**（维度 1-6 + 结构层都漏）。这说明：
- 污染破坏了「分布对比」的可靠性
- 但模型独有的深度发现能力依然存在

---

## Worktree 工作流（Phase 11+ 标准）

### 物理隔离方案

```bash
# 主工作区（Claude CLI 主笔 + 共识收尾）
/Users/yiming/Developer/snapdrill-ios          (develop 分支)

# Codex 桌面端 worktree（同 commit 独立工作目录）
git worktree add ../snapdrill-ios-codex audit/codex-phase11-dimN

# Antigravity worktree
git worktree add ../snapdrill-ios-ag audit/antigravity-phase11-dimN
```

每个智能体只能 read 自己的 worktree，看不到其他 worktree 中的 finding 文件。

### 净化提示词（沉淀到 single-vendor-audit-prompt-template.md）

**移除段**：
- ❌「Claude CLI 已抓（避免重复）」整段
- ❌「不要重复列入 S-D*-* 编号」（间接泄露）
- ❌「Claude 没扫的差异化视角」（分工性表述）

**新增段**：
- ✅「在你自己的 worktree 独立审计，文件路径必须用 worktree 相对路径」
- ✅「产出与其他家可能重叠是正常的，刻意冗余即控制变量法精髓」
- ✅「不要刻意避开 Claude/Codex/Antigravity 可能抓到的 finding」

### 三家产出后回汇

三方完成后：
1. Codex / Antigravity worktree 各产出 finding 清单（push 到对应 audit 分支）
2. Claude CLI 在主分支 fetch 三方 finding
3. Claude CLI 主笔 cross-audit-consensus 折叠 + 入主分支 ledger

## 累计 OPEN finding (Phase 10 七维度全部)

| 维度 | OPEN |
|---|---|
| 1 跨文档语义链条 | 22 |
| 2 反向溯源 | 11 |
| 3 内部冲突扫描 | 10 |
| 4 技术↔产品对齐 | 11 |
| 5 standards 约束力 | 15 |
| 6 skill description↔body | 7 |
| **7 F-rule 遵守度** | **10**（+ 1 WAIVED 污染样本）|
| **Phase 10 累计** | **86** |

## 单家排名（维度 7）

| 排名 | 单家 | 角色 |
|---|---|---|
| 1 | **Antigravity** | C7.5 撕破 docaudit.py 工具 bug，**Phase 10 最致命独家**；但 C7.1-C7.4 抄袭 Claude 编号是污染最严重样本 |
| 2 | Codex | 第四轮（维度 4+5+6+7）连续最强单家；但本轮提示词污染下定向避开 Claude finding，独立性受损 |
| 3 | Claude CLI | F-018 应用率 HIGH 独家有效，但本轮整体被自己写的提示词污染牵连 |

## Phase 10 模型差异化能力总评（七维度累计）

| 单家 | 强项 | 弱项 |
|---|---|---|
| **Claude CLI** | 元层级自指（维度 3 元教训 / 维度 5 S-D5-010 / 维度 7 F-018 应用率） | 大范围机械实证（维度 6 首次 0 独家）|
| **Codex** | 跨文件机械实证 + 系统性扫描（维度 4-7 连续最强） | 受提示词污染指令直接服从（D7-1~D7-5 明确避开 Claude）|
| **Antigravity** | 代码 grep + 工具底层 bug 挖掘（维度 1 Dynamic Type / 维度 3 H2-SM-2 死锁 / 维度 4 通知物理覆盖 / **维度 7 docaudit.py bug**）| 守规矩程度起伏（维度 3 抢跑→维度 4-6 守→维度 7 抄袭 Claude 编号）|

## 下一步

1. **本会话**：commit + push（ledger + dim7-consensus + ADR-005「提议」→「已决策」+ ADR-004 backlog 第一条勾 ✅ + STATUS/handoff Phase 10 收官）
2. **Phase 11+**：Worktree 物理隔离 + 净化提示词成为标准
3. **86 OPEN finding 集中入 PR 阶段启动**（按用户决策跑完 7 维度后处理）
4. **优先修复**：维度 7 S-D7-001 docaudit.py 工具 bug → S-D5-013 重审 → 其他 HIGH
