---
last_verified: 2026-05-24
layer: snapshot
scope: audit-consensus
freshness:
  max_age_days: 90
  decay_trigger: [m000_revision]
---

# M-000 第一性原理审计 — 4 家折叠报告 (P3)

## 4 家产物索引

- [Claude](./m000-first-principles-claude.md) — 24 项 (P6/I7/A8/U3)
- [DeepSeek](./m000-first-principles-deepseek.md) — 7 项 (P2/I2/A3/U0)
- [Gemini](./m000-first-principles-gemini.md) — 14 项 (P2/I5/A4/U3)
- [Codex](./m000-first-principles-codex.md) — 12 项 (P4/I2/A5/U1)

合计 57 条目,经映射归并至 ~22 个核心待审项。

## 强共识红旗 (≥3 家非 PRIMARY)

帅哥可优先处置这 7 条 — 命中率最高,无需挑边。

| # | 待审项 | 4 家 verdict | 改造方向(共识) |
|---|---|---|---|
| **R1** | M-000「协作宪法」叙事 | Claude A / DS A / GM A / Codex A | 改名朴素表述 (核心规则集 / Root Rule),删除政治法律修辞 |
| **R2** | 字数 B+ 硬数字 (2500/400/4000) | Claude A / DS I / GM I / Codex A | 改为软上限 + override_rationale 机制(M-005 #009 已实证) |
| **R3** | frontmatter layer 6 枚举 | Claude I / DS I / GM A / Codex A | 简化为 3 类 (principle/decision/archive) 或转多标签 |
| **R4** | docaudit 11 check | Claude U / GM I / Codex I | 拆开逐个评估,砍到 5-6 项高频触发,其余转可选 |
| **R5** | 5 phases 起草流程 | Claude A / DS A / GM I | 缩到 3 phases (准备/独立产出/合并裁决),不预设 phase 数 |
| **R6** | 古德哈特防御**命名** | Claude A / DS A / GM A(命名)+P(机制) / Codex 未审 | 机制保留(PRIMARY 实质),命名改「目的优先原则」 |
| **R7** | KNOWLEDGE_MAP 45/50 文件硬上限 | Claude I / Codex I | 改为软信号 + 多指标 (Boot 字符预算 + 引用度 + 访问频率) |

## 强共识 PRIMARY (≥2 家 PRIMARY)

| # | 待审项 | 收敛 verdict | 保留理由 |
|---|---|---|---|
| **P1** | F-008「相同完整任务、不分工」 | DS P / GM P | 从异源独立性底层事实推出 |
| **P2** | 用户最高裁决权 (user-decision-log #N 终审) | Codex P / 其他家隐含一致 | 多智能体系统的最终价值函数必须绑定用户 |
| **P3** | append-only user-decision-log | Codex P / Claude A(借 ADR)/ DS+GM 未单审 | Codex 论据:多轮协作需可追溯,#001/#003/#008 实证;Claude 异议:借 ADR 模板 |

## 关键分歧 (帅哥必须挑边)

### D1: 「默认多方异源」(M-000 §3) — 是 PRIMARY 还是 ANALOGY?

| 阵营 A: PRIMARY 保留 | 阵营 B: ANALOGY 改造 |
|---|---|
| Claude / DS | GM / Codex |
| 「多视角防同源盲点」从底层事实推出,#006/#008 实证 | 「任何任务默认多方」未证明边际收益 > 成本;低风险机械任务单方更经济 |
| 改造方向: 保留默认多方 | 改造方向: 改为「风险触发多方」(高风险默认多方,低风险默认单方,用户可显式升级) |

**这条是 M-000 体系的核心命题**。如果阵营 B 对,M-000 §3 + §4.3 双核默认通过 + 所有派生约束都要重写。

### D2: worktree 物理隔离 — PRIMARY 还是 INHERITED?

| 阵营 A: PRIMARY 保留 | 阵营 B: INHERITED 废除 |
|---|---|
| Claude / Codex | GM (唯一反对) |
| Phase 10 实证文字封堵失败,LLM 解读「Claude 已抓 X」为分工 | 各家本来就是异步独立完成,不存在并发写冲突;worktree 增加 git 复杂性 |
| 改造方向: 保留 | 改造方向: 改用「输出目录约定」(/round-N/家名/) 即可 |

**GM 的论据有漏洞**: 它把 worktree 的真目的看成了「防并发写冲突」,但真目的是「防外审看到主笔产物」。3:1 倾向保留,但帅哥可裁决。

### D3: Overrule 机制 — PRIMARY 还是 ANALOGY?

| 阵营 A: PRIMARY 保留 | 阵营 B: ANALOGY 改造 |
|---|---|
| Codex (append-only PRIMARY) | Claude / GM |
| 多轮协作可追溯是底层需求 | append-only + Overrule 字段是 ADR/法律模板模仿;直接 `supersedes: #N` 等价 |
| 改造方向: 保留 + 加机械化 check (Overrule 字段缺失告警) | 改造方向: 简化字段,删除「Overrule」法律修辞 |

## 各家独家发现 (单家信号,值得记)

- **Claude C024**: side-channel frontmatter (`supersession_status: partially_superseded`) 暴露了 status 枚举设计缺陷 — 与 R3 联动
- **DS I002**: 「源」vs「逻辑」之辨 — 把「异源」改成「异逻辑」(论证前提/推理链条不同),更精确,避免「同模型不同 prompt」被误过滤
- **GM I007**: worktree 废除论 — 唯一反对者,论据弱但值得记录
- **Codex I003**: 「双核同意默认通过」UNDETERMINED — 唯一审到此条,建议 M-002 限制适用域
- **Codex I010**: KNOWLEDGE_MAP 45/50 硬阈值改软信号 + Boot 字符预算 (帅哥可移交 M-005 起草时落)

## Meta 观察

### 1. 同源簇

[Claude + Codex] 倾向给 worktree / 净化提示词 / sanity check 自反性 打 PRIMARY,因为这两家是 M-000 起草主笔,审自己的设计有保护偏好。

[DS + GM] 是事后独立审,对 PRIMARY 的门槛更严格,产生更多 ANALOGY/INHERITED 标记。

### 2. 字数预算分布

各家 PRIMARY 比例: Codex 33% / Claude 25% / GM 14% / DS 28%。
**真正的 PRIMARY 内核可能只有 ~5 条**:F-008 / 用户最高裁决 / 多视角防盲点(D1 待裁决)/ 物理隔离(D2 待裁决)/ sanity check 自反性。

### 3. 改造规模预估

如果接受强共识红旗 R1-R7 + 关键分歧倾向保留:
- M-000 v2.0 字数预估降至 ~1500 nwc (从 2400)
- 基础设施层 (frontmatter/docaudit/audit-ledger) 需要做配套瘦身
- ADR-004/005 方法论需要再次复审 (5 Phase / 7 维度 可能 INHERITED)

## 帅哥 N1 节点裁决问题

1. **R1-R7 强共识红旗**: 全部接受改造?
2. **D1 默认多方异源**: A 保留 / B 改风险触发?
3. **D2 worktree**: A 保留 / B 废除?
4. **D3 Overrule**: A 保留 / B 简化为 supersedes?
5. 改造范围: 是直接起草 M-000 v2.0,还是先做单点修订(每个红旗独立 user-decision-log 条目)?

裁决后进 N2 节点(对每条「待改造规则」拍板:重写/废除/保留/暂缓)。
