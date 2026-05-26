---
last_verified: 2026-05-24
layer: decision
status: active
supersession_status: partially_superseded
superseded_by_partial: docs/meta/M-000-meta-vision.md
archived_findings: docs/archive/audits/phase10-semantic-audit-snapshot.md
derived_from: [M-002]
freshness:
  max_age_days: 365
  decay_trigger: [decision_reverted, downstream_change]
---
> ⚠️ **M-000 v1.2 ratified 后部分内容已被新体系接管（user-decision-log #007 激进拆分；#008 撤回 R1 STATUS_ENUM 修改方向）**
>
> - 模型版本事实由 user-decision-log #002 + [agent-cli-models.md](../tech/reference/agent-cli-models.md) 接管
> - 维度 1-7 收官 findings 与 Phase 10 累计统计见 [phase10-semantic-audit-snapshot.md](../archive/audits/phase10-semantic-audit-snapshot.md)
> - 本文保留语义层审计方法论 + docaudit check 设计稿 + 五大教训摘要（执行层 SSOT）
> - `supersession_status: partially_superseded` 为侧通道字段，保留 `status: active` 以兼容下游消费 `status` 字段的脚本（user-decision-log #008）

# ADR-005: 文档体系语义层审计方法论（Phase 10）

> 状态：**部分被新体系接管** | 日期：2026-05-20（立项）/ 2026-05-21（七维度收官） | 决策者：用户（PO）+ Claude Opus 4.7 主导 + Codex GPT-5.5 + Antigravity(Gemini 3.5 Flash (High)) 三方对抗

## 背景

[ADR-004](ADR-004-doc-system-deep-clean.md) 在 2026-05-19/20 完成了文档体系**结构层**收官，并显式声明：结构层 ≠ 语义层；结构层覆盖 frontmatter / 链接 / 计数 / 算术 / docaudit 11 check 等机械可校验维度，语义层需要独立立项。

语义层审计回答的是判断题：跨文档链条、反向溯源、内部冲突、standards 实际约束力、skill description↔body、F-rule 实际遵守度是否真实成立。本 ADR 即兑现 Phase 10 立项与收官方法论。

## 选项

| 选项 | 描述 | 优势 | 风险 |
|---|---|---|---|
| A | Claude 单家审 7 维度，不动 Codex/Gemini | 成本最低 | 单家盲区无对抗校验，回到 Phase 0 前的状态 |
| B | Claude 主导 + Codex 二意见，Gemini 不参与（ADR-004 原定） | 规避 Gemini over-endorse 已知病灶 | Gemini 3.5 是否仍存在该偏误未验证；放弃一个 GUI 通道 |
| **C** | **三方对抗 7 维度：Claude（CLI）+ Codex（桌面端）+ Antigravity(Gemini 3.5)** | **完整对抗覆盖；新模型可借机验证 over-endorse 是否消除** | **成本最高；若仍 over-endorse 需 fallback 到 B（cross-audit-consensus 降权重）** |

## 决策

**选项 C**：Phase 10 文档体系语义层审计采用 Claude + Codex 桌面端 + Antigravity(Gemini 3.5) 三方对抗模式，7 维度全量覆盖。

**supersedes**：[ADR-004 backlog 段](ADR-004-doc-system-deep-clean.md) 原工具配置「Gemini 不参与判断」局部失效；其余 ADR-004 结构层方法论仍生效。

### 三方角色分工（沿用 F-008「相同完整任务、不分工」纪律）

- **三家独立审完整 7 维度**，不切片分工
- folding 用 `cross-audit-consensus` skill 输出共识 / 单家独有 / 冲突三类
- Claude（CLI）主笔最终 verdict + ADR-005 收官段；Codex 桌面端 + Antigravity 各产一份独立报告附录到 audit-ledger

### 7 个语义维度（方法论骨架）

| # | 维度 | 判据 |
|---|---|---|
| 1 | 跨文档语义链条 | vision → design → requirements → tech 每对邻层强校验 |
| 2 | 反向溯源 | requirements 中每个功能能否反推回 vision 价值主张 |
| 3 | 内部冲突扫描 | vision / design / requirements / tech 内外是否互相抵触 |
| 4 | 技术↔产品对齐 | tech 决策是否真服务「采集 > 管理 > 导出」价值链 |
| 5 | standards 约束力 | 每条 standards 规则是否真被代码 / skill / CI 执行 |
| 6 | skill description ↔ body 一致性 | skill 对外承诺是否与执行体一致 |
| 7 | F-rule 实际遵守度 | F-001 ~ F-019 在 git log / PR / hook 中是否真有触发证据 |

维度 1-7 的历史收官观察、三方表现和 86 OPEN finding 累计统计已切出至 [phase10-semantic-audit-snapshot.md](../archive/audits/phase10-semantic-audit-snapshot.md)。

### 活性新陈代谢约束

本协议的维护与演进纪律已整合至 [docs/standards/worktree-audit-workflow.md](../standards/worktree-audit-workflow.md)。STATUS.md 已 stub 化（user-decision-log #006），审计状态追踪由 docaudit 工具链动态维护，不再允许在 ADR 中静态记录过程状态。Phase 10 当时使用的「维度收尾必须触动 STATUS/handoff/ADR backlog」纪律见 [phase10-semantic-audit-snapshot.md §Phase 10 维度收尾纪律](../archive/audits/phase10-semantic-audit-snapshot.md#phase-10-维度收尾纪律历史快照)。

### 配套的 2 个新 docaudit check 设计稿（不本会话实现，沉到 ADR-004 backlog）

| check name | 检测什么 | 实现要点 |
|---|---|---|
| `superseded-by-reverse-link` | ADR 内任何 `superseded_by: ADR-X` 标注必须在 ADR-X 找到对应 `supersedes:` 反向链 | 扫 docs/decisions/*.md，正则匹配两个字段，bipartite 配对验证 |
| `backlog-item-staleness` | ADR / STATUS / handoff 内的 backlog bullet 若引用一个已 merge 的 phase / issue / commit 仍标 ⏳ 或 ❌，告警 | 扫 backlog 段 + git log/gh issue 状态对账；候选清单 → warning 级别 |

两个 check 与 ADR-004 原 4 个 check 设计稿（ssot-cross-check / dep-map-reality / terminology-glossary / snapshot-freshness）并列，每个 1-2 小时实现。

### 终态判据

- 7 维度各产出一份独立 finding 清单（VALID / VALID_WITH_GAP / NEEDS_REVISION / DRIFT）
- audit-ledger 追加语义层段（不复用结构层 ledger）
- 真 finding 落 PR 修复；可保留的 GAP 写明 `gap_due`
- 收官时本 ADR 状态从「提议」→「已决策」，回填实际耗时 + 三家对抗结果汇总

## Phase 10 五大方法论实战教训

### 1. 控制变量法污染

Phase 10 维度 5-7 提示词「Claude CLI 已抓」段导致 Codex/Antigravity 避开或抄袭，违反 F-008 控制变量法精髓。已沉淀为 worktree 物理隔离。
- 历史原文: [phase10-semantic-audit-snapshot.md#1-控制变量法污染维度-5-7-同源](../archive/audits/phase10-semantic-audit-snapshot.md#1-控制变量法污染维度-5-7-同源)
- 反向链: [worktree-audit-workflow.md](../standards/worktree-audit-workflow.md) + 将作为 M-001/M-005 起草输入

### 2. 抢跑落档

维度 3 Antigravity 未等三家齐就独立写 ledger / STATUS / handoff / ADR-005；提示词「严禁操作」段在维度 4-7 封堵成功。
- 历史原文: [phase10-semantic-audit-snapshot.md#2-抢跑落档维度-3-暴露--维度-4-7-封堵](../archive/audits/phase10-semantic-audit-snapshot.md#2-抢跑落档维度-3-暴露--维度-4-7-封堵)
- 反向链: [user-decision-log #005](../meta/user-decision-log.md) + 将作为 M-002 起草输入（共识未齐前不得形成事实）

### 3. 文档新陈代谢

Phase 10 自产文档把易变模型版本写死，违反 ADR-004 反漂移机制；修复路径是 `gap_due` 与外部事实刷新机制。
- 历史原文: [phase10-semantic-audit-snapshot.md#3-文档新陈代谢连续性-vs-更新](../archive/audits/phase10-semantic-audit-snapshot.md#3-文档新陈代谢连续性-vs-更新)
- 反向链: [user-decision-log #002](../meta/user-decision-log.md) + 已被 M-005 起草输入 + docaudit `external-gap-expiry`

### 4. 元层级 self-non-compliance

维度 3/5/7 反复出现「制定规则的人不遵守自己规则」：模型版本、shared-constraints、docaudit 正则真值均曾自我违纪。
- 历史原文: [phase10-semantic-audit-snapshot.md#4-元层级-self-non-compliance维度-357-反复出现](../archive/audits/phase10-semantic-audit-snapshot.md#4-元层级-self-non-compliance维度-357-反复出现)
- 反向链: [user-decision-log #002 / #005](../meta/user-decision-log.md) + 将作为 M-005 核心退化模式

### 5. 易变事实 + gap_due 机制

`docaudit external-gap-expiry` 在 Phase 4 建立，ADR-005 §模型版本注是首次正式使用；该历史样本已降级为 archive 快照。
- 历史原文: [phase10-semantic-audit-snapshot.md#5-易变事实--gap_due-机制维度-6-验证](../archive/audits/phase10-semantic-audit-snapshot.md#5-易变事实--gap_due-机制维度-6-验证)
- 反向链: docaudit `external-gap-expiry` + [agent-cli-models.md](../tech/reference/agent-cli-models.md) + 将作为 M-005 输入

## Worktree 工作流（Phase 11+ 标准）

详见 [docs/standards/worktree-audit-workflow.md](../standards/worktree-audit-workflow.md)。核心：主工作区只做主笔与共识收尾；Codex / Antigravity 各自使用同 commit 独立 worktree；提示词移除「Claude CLI 已抓」「不要重复 S-D*-*」「差异化视角」等分工性表述。

```bash
# 主工作区（主笔 + 共识收尾）
/Users/yiming/Developer/snapdrill-ios          (develop)

# Codex / Antigravity 各自 worktree（同 commit 独立目录）
git worktree add ../snapdrill-ios-codex audit/codex-phase11-dimN
git worktree add ../snapdrill-ios-ag audit/antigravity-phase11-dimN
```

## 元数据

- 本 ADR 决策者：用户批准三方对抗 + 先立项再实施流程；Claude 起草 ADR-005；Codex/Antigravity 实施阶段加入
- 关联 ADR：[ADR-004](ADR-004-doc-system-deep-clean.md)（结构层方法论 + 本 ADR 的 backlog 立项依据）
- 关联 skill：`cross-audit` / `cross-audit-consensus` / `verify-audit-report`
- 历史 findings 与模型版本快照已切出至 [phase10-semantic-audit-snapshot.md](../archive/audits/phase10-semantic-audit-snapshot.md)
