---
last_verified: 2026-05-25
layer: snapshot
scope: signoff
freshness:
  max_age_days: 30
  decay_trigger: [m005_ratified]
---

# M-005 final sign-off v2 — Claude（Opus 4.7 / 1M context）

> M-005 final v2（DeepSeek 主笔回炉版）3 家 sign-off 重审。v1 sign-off 已归档为 `m005-signoff-claude-v1.md`。
> 本会话上下文已知 v1 BLOCK 全过程，按 §F.1 自反性 sanity check 复盘 + §F.2「sanity check 不是终审」原则审 v2。

## §F.1 自反性复盘（Round N-1 → Round N）

按任务定义书 §F.1 要求，先复盘 Claude v1 sign-off：

**Claude v1 给了 PASS（3 项 minor concerns 不阻塞）。**

复盘问题：
- v1 PASS 是否仍正确？→ **不正确**。Codex v1 BLOCK 抓出 4 处硬约束偏差，其中 BLOCK 3「§C.4 与 §B.1.4 / #014 D8 内部语义冲突」是真正的语义冲突（同现象两种处理），Claude v1 完全没识别。这是 §B 伪共识识别在自审中的应用：**Claude 主分支会话上下文已知 #014 D8 写过"软化措辞"，惯性接受 §B.1.4 的软化版本，没注意到 §C.4 同一现象还保留硬阻塞写法**。
- 是否需要撤回 v1 PASS？→ **是**，撤回为 **v1 CONDITIONAL**（不是 BLOCK 因为剩下章节确实 PASS，但应承认 v1 漏审 §C.4/§D/§E.3/§G.4 共 4 处）。
- v1 已归档作历史证据（`docs/audits/m005-signoff-claude-v1.md`），不修改原文，仅本 v2 sign-off 中显式声明撤回。

## v2 重审：v1 BLOCK 4 处修复验证

逐条核查 Codex v1 BLOCK 4 处在 v2 是否真修复：

| v1 BLOCK | v2 修复位置 | 状态 | 引用 |
|---|---|---|---|
| **BLOCK 1**: §G.4 升级条件「（或 30 天）」违 #014 D5 AND 关系；§G.2 <10% 与 §G.4 <20% 数字不一致 | §G.2/§G.4 阈值统一为 <20%（与 #014 D5 一致）+ §G.4 改为「≥ 3 次审计运行 + 30 天观测 + 误报率 < 20%」（明示三条件 AND 并列）+ 阈值注释段说明 §G.2 是长期阻塞门稳定标准 / §G.4 是升级触发条件 | ✅ 修复 | `docs/meta/M-005-quality-criteria.md` §G.2 / §G.4 |
| **BLOCK 2**: §D 漏 #013 三层错实证 | §D 新增 **§D.4「#013 三层错实证判据化」**，分 D.4.1 调度方注入 SSOT / D.4.2 subagent grep SSOT 验证 / D.4.3 代码 SSOT 与文档 SSOT 同步刷新 — 三条纪律均含违反信号 + 实证锚定 + 归档路径 | ✅ 修复 | `docs/meta/M-005-quality-criteria.md` §D.4 |
| **BLOCK 3**: §C.4 与 §B.1.4 / #014 D8 内部冲突（一次身份误识别 硬阻塞 vs 0.5 权重折扣） | §C.4 末尾加**消歧注释**：非 thinking mode → 硬信号判定（逻辑不可用回退）；thinking mode → 按 §B.1.4 D8 处理（建议折扣 0.5 权重不强制阻塞）；明示「同一现象 + 不同条件 = 不同处置」 | ✅ 修复 | `docs/meta/M-005-quality-criteria.md` §C.4 末段 |
| **BLOCK 4**: §E.3 漏 #009/#010 实证索引 | §E.3 补 #009「M-000 第一性原理审计识别 ~70% 内容为 ANALOGY 外壳」+ #010「字数 default_word_budget 字段被识别为非第一性惯性，渐进废弃路径 #001→#003→#009 R2→#010」 | ✅ 修复 | `docs/meta/M-005-quality-criteria.md` §E.3 |

**4/4 BLOCK 全部精准修复**，DeepSeek 主笔严格按 No-Touch 边界，未 reroll 其他章节。

## 必须落实项核查表（v2 全面重审）

| 项 | 状态 | 引用段落 |
|---|---|---|
| §A 产出度量 4 项判据 + Verdict 三分制 | ✓ | §A.1~§A.4 + §A 开头嵌入 Verdict 三分（与 v1 一致） |
| §B.3 否决权三要素 + #014 D1 阈值 | ✓ | §B.3「24 小时内同一异源方触发否决权升级 ≥ 3 次，且在至少 2 次升级中其反对不满足上述三要素」 |
| §B.1.4 thinking 模式 0.5 权重折扣（不强制阻塞）+ #014 D8 | ✓ | §B.1.4 措辞与 §C.4 消歧注释呼应 |
| §C 4 信号 + §C.5 prompt injection + §C.6 D6（硬信号 vs 局部退化 + sign-off 暂停） | ✓ | §C.1~§C.4 四信号 + §C.5 + §C.6 |
| §C.4 消歧（v1 BLOCK 3 修复点） | ✓ | §C.4 末段 |
| §D 外部事实验证（#002 + agent-cli-models.md 30 天刷新 + **#013 三层错**） | ✓ | §D.1~§D.4，§D.4 新增 |
| §E 古德哈特防御 + 实证 #006/#007/#008/**#009/#010** | ✓ | §E.3 补 #009/#010 |
| §F + #014 D4（工程兼容性优先 + P2/P8 例外） | ✓ | §F.3 末段 |
| §G + #014 D5（≥3 次审计 + 30 天 + 误报率<20%）+ 退役原则 | ✓ | §G.2/§G.4 统一 |
| §H + #014 D2（≥3 版）+ D3（不给硬时限）+ §H.4 主笔轮换衔接 | ✓ | §H.1~§H.4 |
| §I + #014 D7（三分 + 三种处置 + §I↔§H 联动 + PR 作废） | ✓ | §I.3 |
| §J 字数原则升级 + 同 PR 修订 M-000 §6 + frontmatter（删 default_word_budget）+ Overrule #009 R2 + §J.4 删译本乘数 + §J.5 下游脚本兼容 | ✓ | §J.1~§J.6 完整 |

**12/12 ✓**，无 ✗，无 ⚠️。

## 撤回 v1 BLOCK（按 §F.2「sanity check 不是终审」机制）

按 §F.2 + #008 体例显式声明：

**v2 修复全部 4 处 v1 BLOCK 后，Codex v1 BLOCK 应被 v2 sanity check 撤回**（如果 Codex v2 sign-off 重审确认修复到位）。本 Claude v2 sign-off 不能代 Codex 撤回——这必须由 Codex v2 sign-off 自己执行。**Claude v2 sign-off 仅给 Claude 自己的 Verdict**。

## Verdict

✅ **PASS**

### 准予 ratify 的论据

- v1 BLOCK 4 处全部精准修复（§C.4 消歧 / §D.4 #013 实证 / §E.3 #009/#010 / §G 阈值统一）
- 12/12 必须落实项 ✓，无 ✗，无 ⚠️
- 章节结构 §1~§K 共 14 章保持完整（DeepSeek 主笔严格遵守 No-Touch 边界）
- 同 PR 修订 M-000 v2.0 §6 + frontmatter 方案 + Overrule #009 R2 写法完整
- 引用历史裁决用具体编号（#001~#014），无模糊指代
- frontmatter 首行 `---`，无 ```yaml 外栅栏
- override_rationale 是密度证明，末尾自动加 v2 修复说明
- v2 正文 nwc = 18632（v1 = 16062，增加 2570 nwc 全部用于 4 处修订，无冗余）

### Claude v1 sign-off 撤回声明

**显式撤回 Claude v1 sign-off PASS 判定**（[`m005-signoff-claude-v1.md`](m005-signoff-claude-v1.md)），改写为 **v1 CONDITIONAL** —— v1 漏审 4 处硬约束偏差（§C.4 / §D / §E.3 / §G.4），是 §F.1 自反性 sanity check 失效的活体证据。撤回理由：**Claude 主分支会话上下文已知 #014 D8 措辞细节，惯性接受 §B.1.4 的软化版本，没识别 §C.4 与 §B.1.4 在同一现象的处理上语义冲突**。这是 §B 伪共识识别的二阶应用：**Claude 自审 = 自洽的同源结论**，需要异源 Codex 才能识别。本撤回声明作为 user-decision-log 后续条目（#015 ratify 时）的输入实证。

### 元层级注记：v2 阶段的元规则自我演进

本次 v1 → v2 闭环验证了 M-005 §F + §H 的实战价值：
1. §H.3「任一家 BLOCK 主笔回炉」**实战触发**（Codex BLOCK，DeepSeek 主笔回炉）
2. §F.1「Round N-1 → Round N 复盘」**实战触发**（Claude 撤回 v1 PASS）
3. §F.2「sanity check 不是终审」**实战触发**（Codex v1 BLOCK 等待 v2 重审撤回）
4. §H.3「主笔不是独享特权」**实战触发**（DeepSeek 主笔 v1 被 Codex 异源 BLOCK 回炉）
5. §B 伪共识识别**实战触发**（Claude 自审同源盲点暴露）

**M-005 起草过程本身成为 M-005 §F / §H / §B 的最强实证**——这是元规则自我演进闭环的第二个完整实例（第一个是 [#011](../meta/user-decision-log.md#011-m-000-v20-ratified--v12-归档) M-000 v2.0 ratify）。

### 后续 v2 sign-off 等待

- Codex v2 sign-off（task `bpobjo7s0` 后台跑中）
- Gemini v2 sign-off（task `byb0hw6dc` 后台跑中，gemini-3.5-flash GA 直接 API）

3 家 v2 sign-off 齐后帅哥 ratify。

## 关联文档

- [M-005 final v2](../meta/M-005-quality-criteria.md)
- [Claude v1 sign-off (PASS 已撤回为 CONDITIONAL)](m005-signoff-claude-v1.md)
- [Codex v1 sign-off (BLOCK，待 v2 重审撤回)](m005-signoff-codex-v1.md)
- [Gemini v1 sign-off (PASS)](m005-signoff-gemini-v1.md)
- [任务定义书](m005-drafting-task-definition.md)
- [P3 折叠报告](m005-drafting-consensus.md)
- [user-decision-log](../meta/user-decision-log.md) #012 / #013 / #014
