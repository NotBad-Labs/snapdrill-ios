---
last_verified: 2026-05-25
layer: principle
scope: meta
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, skill_audit_quarterly, external_shock]
word_count_actual: 5222  # 正文 Unicode nwc（不含 frontmatter）；M-005 §J.7 标准 `awk + tr + wc -m` 实测 2026-05-25
override_rationale: |
  正文 5222 nwc（M-005 §J.7 标准实测：`awk 抠 body | tr -d 空白 | wc -m`，参考篇幅 2500 nwc，本文超 ~109%）。按 M-005 §J.2 v2「分层 + 触发」证明（路径 C [#021](user-decision-log.md#021) ratify 落地）：

  **章节级证明（mandatory）**：以下 8 章 + 附录均不可下沉、不可省略：
  (1) §1 P1 定位 — 三维度正交 + 治理派生关系，不可下沉到 standards（这是 M-003 自身合法性章），不可省略（删除即 M-003 失锚）
  (2) §2 Q1 判定 + §2.4 入库门槛 — P3 三条不可机械化判据是 skill 体系防膨胀的最小完整集，不可下沉到 skill 文档自身（这是元规则层判据）
  (3) §3 命名空间 + 公私分治表 — Q2/Q4 答案，不可下沉到 standards/skill-source-ledger.md（治理范围分类是元规则层声明）
  (4) §4 生命周期 — Q3 状态机 + 入口/出口条件 + 触发频率监控，不可下沉到 hook 文档（状态机本身是规则）
  (5) §5 升降级流程 + D1-D7 决策点 — 决策点必须留给帅哥 Stage 7.9 裁决，不可省略（剥夺裁决权）
  (6) §6 治理规则派生映射 — Q5 答案，是 P2「治理 top-down」的核心证据链，不可下沉到 ADR（这是元规则间派生关系声明）
  (7) §7 主笔体系隔离 + N≤2 — P4 落地，不可下沉到 task definition（这是元规则层约束）
  (8) §8 下游接口 — 与 M-001/M-002/M-004 的边界声明，不可省略（防越界）

  **段级证明（按 §J.2 v2 触发：超参考篇幅 + sign-off 指出 + 作者主张）**：以下 2 段为已识别的最可能冗余段落示例（按 DeepSeek CONDITIONAL C3 建议）：

  - **§5.7 D1-D7 选项块（line 116-167）**：含 7 个决策点 × 3-4 选项 × 1-2 行利弊。Codex 指出可表格化压缩 ~30%。
    *压缩分析*：选项陈述若表格化，每选项的「利弊」必须缩为短语（如「B/C 强制防同源互审；增目录复杂度」），失去 Stage 7.9 帅哥裁决所需的「完整选项语境」。决策点是元规则层裁决入口，不可压缩至损失裁决依据。
  - **§6 派生映射 5 行**：每行格式 `M-000 §X | 派生为 M-003 治理规则`。
    *压缩分析*：5 行已是最简映射，删除任一行破坏 P2「治理 top-down」证据链（如删 §10 派生，M-003 失合法性来源；删 §6 派生，入库门槛失底层）。

  **不接受的简化路径**：
  - 删 D1-D7 利弊（→ 剥夺帅哥 §5 裁决权）
  - 删派生映射（→ P2 原则失证据链）
  - 章节合并（→ 八章结构对应 task def v2 §4 强约束）

  **采用候选 D 的两层 + 触发条件变体**（按 [#021](user-decision-log.md#021) D-J1 裁决 + 反思报告 §2.4 候选 D 简化）：章节级 mandatory + 段级 trigger-driven，未实现 D 三层中的「句级 recommended」。
derived_from: [M-000 §11.1]
---
# M-003 技能库治理 v1（路径 C Stage 7 ratified）

> **状态**：v1 ratified ([#021](user-decision-log.md#021))，路径 C Stage 7.9 落地
> **实证锚**：路径 C #016–#021 全过程，详见各节引用。
> **前置依赖**：M‑000 v2.0 §5/§6/§8/§10、M‑005 §G.5 + §J.2 v2「分层 + 触发」（[#021](user-decision-log.md#021) D-J1=D 裁决）为底层判据。

## §1 定位（内容正交 + 治理派生，P1）

**三维度内容范畴正交**：
- M‑000（HOW 协作规则）
- 产品文档（WHAT 业务领域）
- skill（WHEN X, DO Y 任务模式套路）
三者互不派生，各自独立演化。

**治理合法性派生**：
M‑003 是 M‑000 §10 预留的“技能库治理”派生文档；其治理规则（入库、命名、升降级、淘汰）显式从 M‑000/M‑005 派生（见 §6）。**内容正交 ≠ 治理无关**。

## §2 skill 内容判定（回答 Q1 + P3 入库门槛）

### §2.1 下沉判定流程

**决策树**（机械化可执行）：

1. 内容是否静态规则/约束/规范且不需 LLM 动态判断？→ **PROMOTE_TO_STANDARDS**
2. 是否纯代码模板/片段，无需推理即用？→ **DOWNGRADE_TO_TEMPLATE**
3. 是否可被 hook/CI 脚本自动化？→ 下沉 `.claude/hooks`、`.github/workflows` 或 `Scripts/`
4. trigger 条件是否依赖实时上下文推理且无法替代？→ 保留 skill（进入 §2.4 入库检验）

**判据**（skill‑audit‑final §6.2.1，#017）：trigger 依赖 LLM 实时推理且不可静态化 → skill。
**可验伪信号**：季度审计发现 skill trigger 可机械化则自动标记候选降格。

**反例 ≥3**：
- ✅ 保留：`dod-checklist` 需 LLM 动态判断完成状态（#017 共识 KEEP）。
- ❌ 下沉 standards：`coding-best-practices` 纯规范 → `docs/standards/swift-coding.md`（#017 PROMOTE）。
- ❌ 下沉 templates：`cross-audit` 审计流程可静态模板化（#017 DOWNGRADE）。

### §2.4 入库门槛（P3 三条全满足）

**仅在 §2.1 判定“可 skill”后适用**；以下三条**全部满足**方可进入入库提案：

1. **实践重复触发 ≥3 次**（M‑000 §6 隐含信号，路径 C 实证）
2. **≥2 个独立场景验证**（不同上下文/不同消费者）
3. **无法机械化**（standards/templates/hooks/scripts 均无法替代）

**判据**：#019 52→11 active 证明无门槛导致膨胀；#020 M‑000 §6 修订 skill 末位。
**可验伪信号**：提案若无 ≥3 次触发记录直接退回，季度审计可复核。

## §3 命名空间 + 公私分治（回答 Q2 + Q4，P3）

**当前布局现状**（不预判 SSOT）：
- `.claude/skills/` 含 11 active skill
- `.agents/skills/` 含 16 portable skill，部分重叠
- D2 SSOT 路径待帅哥裁决（见 §5.7 D2）

### 公私分治治理范围对照

| 分类 | 范围 | 治理权限 |
|---|---|---|
| ⚫ 公共 skill（Anthropic 运行时加载） | ~17 个（PDF/DOCX/XLSX/PPTX/Frontend Design 等，WebSearch 2026-05-25） | 仅触发抑制/增强配置清单（项目级 CLAUDE.md），不可改写内容 |
| ⚪ 个人 skill（项目自创，repo‑owned） | `.claude/skills/` 或 `.agents/skills/` 中非公共者 | 完整生命周期（§4） |
| 🔄 fork 公共 skill | 经修改后纳入项目目录 | 属个人 skill，须显式声明来源与差异 |

**边界判据**：若 skill 源文件不在项目 repo 可控范围内 → 公共；repo 内存在 → 个人或 fork。
**可验伪信号**：公共 skill 治理清单是否维护在 CLAUDE.md 且季度审计时与实际加载一致；fork 声明缺失则记入偏差。

11 active skill 分类与附录见 §附录 B。

## §4 生命周期（回答 Q3 + 触发监控，含 hook 能力记录）

**状态机**：

```
提案 ─▶ active ─▶ 候选 (candidate) ─▶ 降格/归档
         ▲            │
         └── 升级 ────┘
```

**入口/出口条件**（每条可机械检查）：

| 转换 | 条件 |
|---|---|
| 提案 → active | 通过 §2.4 入库门槛 + M‑002 审议 + 至少一次异源 sign‑off |
| active → 候选 | 连续 2 季度无触发（§G.5.2）或审计 Verdict 候选 |
| 候选 → 降格/归档 | 候选 ≥1 季度仍无触发 → DOWNGRADE/DELETE |
| 升级（候选 → active） | 触发频率达标 + 误报率 < 20%（§G.2） |

**触发频率监控**：
Claude Code 提供 27 个 hook events（官方文档 2026-05），支持 skill‑scoped hooks（PreToolUse/PostToolUse 等）。可部署 PreToolUse 钩子记录 skill 触发到 `.claude/skill-audit.log`，兜底手动季度审计（git log + 会话记录）。D3 采集机制方案见 §5.7。

**判据**：52→11 重构证明无生命周期导致膨胀（#019）。
**可验伪信号**：连续 2 季度零触发即自动降格；日志缺失触发条目时审计标记缺失。

## §5 升降级流程（引用 M‑005 §G.5 + M‑003 增量）

直接引用 M‑005 §G.5.1（6 Verdict）、§G.5.2（季度审计）、§G.5.3（大规模重构 baseline）、§G.5.4（主笔消费偏向），不重复定义。

**M‑003 增量**：
- **提案模板**：动机（为何不可下沉）、trigger 条件与示例、预期消费者与频率、元规则对齐论证；模板存 `docs/templates/skill-proposal.md`，审议归 M‑002。
- **大规模重构基线角色**：参照 #019，影响 ≥10 skill 或 ≥20% active 时，需 legacy_whitelist + expires_on ≤30 天 + 同步更新 skill‑architecture.md/skill‑source‑ledger.md。
- **重叠检测机械判据**：两 skill trigger 条件关键词聚类相似度 > 70% 或触发日志高度重合 → 启动合并评估。

### §5.7 待裁决决策点（D1–D7，主笔不裁决）

**D1 命名空间隔离粒度**
- A 仅 frontmatter `category: governance|tool`
- B 物理目录 `.claude/skills/governance/` vs `tools/`
- C A+B 同时
- D 不强制
利弊：B/C 强制防同源互审（#017 Claude 自审失真），但增目录复杂度；A 灵活但无约束；D 依赖审计兜底风险高。

**D2 SSOT 路径**（严格中性）
- A `.agents/skills/` SSOT + `.claude/skills/` symlink
- B `.claude/skills/` SSOT，`.agents/` 出口
- C 双 SSOT 按类型
- D 维持现状
利弊：A 避免双份漂移（#019 发现），B 更贴合 Claude 习惯；C 维护成本高；D 保留现存不一致。

**D3 触发日志采集机制**
- A Claude Code hook 自动化写 `.claude/skill-audit.log`（WebSearch 确认：27 事件 + skill‑scoped hooks，PreToolUse 可采集）
- B 手动季度审计
- C A+B 组合
利弊：A 自动化但需维护 hook；B 低成本但可能遗漏；C 平衡，hook 优先/手动兜底。

**D4 大规模 skill 重构触发阈值**
- A ≥10 skill（§G.5.3）
- B ≥20% active
- C user‑decision‑log 显式立项
利弊：B 适应总量缩减后的动态阈值；A 固定直观；C 最灵活但可能延后。

**D5 11 active skill 6 个月豁免处理**
- A 维持豁免至 2026‑11‑25
- B M‑003 ratify 即解除
- C 仅 KEEP 维持，REWRITE 立即纳管
利弊：A 尊重历史裁决；B 尽早全面治理；C 折中。

**D6 M‑003 治理范围**（P3 关键）
- A 仅 repo‑owned skill（公共 out‑of‑scope）
- B 含公共 skill（触发抑制配置清单）
- C 分阶段：v1 仅 repo‑owned，未来扩展
利弊：B 完整性高但增加复杂度；A 简洁但需显式排除；C 渐进可行。

**D7 入库门槛阈值**
- A 重复触发 ≥3 次（M‑000 默认）
- B 阈值可配置（项目级覆盖）
- C A + 质化补充（异源验证认可）
利弊：A 固定简单；B 灵活但增加维护；C 综合但判据稍复杂。

## §6 治理规则派生映射（P2，回答 Q5）

| M‑000/M‑005 条款 | 派生为 M‑003 治理规则 |
|---|---|
| M‑000 §5 防膨胀/泄洪区定位 | skill 库容量定位（泄洪区，非元规则延伸） |
| M‑000 §6 修改须带触发场景 | 入库门槛 ≥3 次重复触发（§2.4） |
| M‑000 §8 概念单一权威 | skill 职责边界：触发条件重叠即合并信号（§5） |
| M‑000 §10 派生链预留座位 | M‑003 自身合法性（治理文档住进派生链） |
| M‑005 §G.5 升降级双轨 | M‑003 §4/§5 状态机与升降级流程直接吸收 |

**判据与可验伪信号**：每条派生均能在对应条款中找到原文依据；季度审计检查治理规则是否偏离派生源。

## §7 主笔体系隔离 + 异源审查 N≤2（P4）

- **主笔起草期间禁用清单**：主笔起草 M‑003 等元规则时，禁止使用 `.claude/skills/` 下任何 governance 类 skill（#016 自举循环破解），仅可使用工具 skill 与 standards/templates。与 M‑005 §G.5.4 及 §B.1 信号 5 双向引用。
- **异源审查终止规则（N ≤ 2）**：主笔 draft（阶 0）→ 异源 sign‑off（阶 1）→ 异源对 sign‑off 逻辑复核（阶 2）。超过 N=2 强制中断转帅哥裁决。帅哥是唯一终止节点（Antigravity 建议采纳）。

**判据**：#017 同源偏向实证；异源审查消除盲点但无限回归导致认知负荷。
**可验伪信号**：若出现阶 3 评审链未转裁决则视为违规。

## §8 与下游 M‑001/M‑002/M‑004 接口

- **M‑001**：skill 审计主笔提名继承 M‑005 §H 轮换原则；M‑003 定义审计周期与判据，M‑001 负责具体提名流程。
- **M‑002**：skill 提案审议与分歧裁决归 M‑002；M‑003 仅执行初始合规过滤（§2 判定+§2.4 入库门槛）。
- **M‑004**：可能承接 skill 触发日志操作格式与 CI hook 配置，M‑003 不定义 schema。
- **不重复定义**：M‑005 §G.5 Verdict、季度审计间隔、baseline 机制等均为底层判据，M‑003 引用而非覆写。

## §附录 B 公/私 skill 分类（WebSearch 验证）

⚫ **公共**（Anthropic 运行时加载，~17 个，可查）：PDF、DOCX、XLSX、PPTX、Frontend Design 等。
⚪ **个人**（repo‑owned）：app-description-writer、decision-closeout、dod-checklist、phase-closeout、screenshot-planner、swift-concurrency-pro、swiftdata-pro、swiftui-pro、tdd-feature、verify-audit-report、xcode-review（11 active）等。
🔄 **fork 公共**：当前无已知 fork；若出现须在 frontmatter 声明来源并归入个人治理。

## §9 自反性标注

**起草工具**：直接 API 调用，zero‑context，未使用任何 `.claude/skills/` governance skill。**WebSearch 记录**（2026‑05‑25）：Claude Code hooks 27 事件/skill‑scoped hooks 确认；公共 skill 清单 ~17 个确认。详见 §4、§3 及附录 B。

*本草案由 DeepSeek V4‑Pro 基于路径 C 全实证 + 4 条新原则（P1‑P4）与 WebSearch 验证起草。*
