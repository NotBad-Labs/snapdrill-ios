---
last_verified: 2026-05-25
layer: archive
scope: meta-audit
---

你是 SnapDrill iOS 项目元规则 M-003「技能库治理」**第二轮主笔**（v2）。

# 你的身份与上下文

- 模型：DeepSeek V4-Pro（已确认，禁止 Flash）
- 任务：路径 C Stage 7.7 — 基于 task definition v2 + 4 条新原则（P1-P4，帅哥裁决）+ v1 教训 + Expert review 3 家共识，重写 M-003 v1
- 主笔身份：DeepSeek 第 5 次主笔（前 4 次：M-005 v2 / skill-audit-final / Stage 6.2 patch / M-003 v1 均一次通过 sign-off 或 CONDITIONAL）
- 本次 v1 字数自报错误事故（自称 2480 nwc，实测 4958 nwc）已写入 v2 task definition §6 主笔验证机制 — 你必须严格执行

# Zero-context 说明

本任务 zero-context，你没有访问项目仓库的文件系统能力。所有输入已 inline。

# 你的输出

**完整的 `docs/meta/M-003-skill-library-governance.md` v2 markdown 全文**，单一 fenced code block，开始于 frontmatter `---`，结束于文档最后一行 + 在 code block 之外报告 `wc -m` 实测值。

# 硬性约束（v2 task definition §10 验收清单 15 项）

1. **P1 落地**：§1 显式区分内容正交 + 治理派生（不可压缩为单一概念）
2. **P2 落地**：必含完整派生映射表（M-000 §5/§6/§8/§10 → M-003 治理规则）
3. **P3 落地**：§3 含公私分治治理范围对照 + §2.4 含入库门槛（≥3 次重复 + ≥2 独立场景 + 无法机械化）
4. **P4 落地**：§7 含 N≤2 元层级规则
5. **字数机械验证**：frontmatter 字数声明字段必须与 `wc -m` 实测一致；总 ≤ 2500 nwc；超出必须 §J `override_rationale` 论证每段不可压缩
6. **D2 严格中性化**：§3 不得既定声明 `.agents/skills/` 或 `.claude/skills/` 任一为 SSOT（v1 §3.1 line 51-52 预裁决教训）
7. **D3 已 Claude 代查**：见下方 WebSearch 结果，主笔直接引用
8. 五问每问含判据 + 实证 + 可验伪信号
9. 八章全部覆盖
10. 决策点 D1-D7 全部列选项 + 利弊，未擅自裁决
11. §G.5 引用一致（不重复定义）
12. 自反性标注完整 + WebSearch 引用
13. 实证锚全部可追溯
14. 不预裁决决策点
15. 不越界（M-002/M-004/standards 范围事项）

# Claude 主分支代查 WebSearch 结果（2026-05-25）

## D3 hook 能力（v2 task definition §5 D3）

Claude Code 2026 hook 体系：
- **27 个 hook events**（含 SessionStart / SessionEnd / UserPromptSubmit / Stop / PreToolUse / PostToolUse / SubagentStart / SubagentStop / TaskCreated / TaskCompleted / FileChanged 等）
- **Skill scoped hooks**：skill 可在 frontmatter 定义 hooks，仅在该 skill 触发时生效
- **PreToolUse hook**：可拦截每次工具调用前执行
- **Skill 触发日志采集**：可通过 PreToolUse hook + skill scoped hook 组合实现（具体 event 名可能需主笔在 D3 选项利弊中说明实施细节）
- 官方文档：https://code.claude.com/docs/en/hooks
- 实施参考：`github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/hook-development/SKILL.md`

## 公共 skill 当前清单（v2 task definition §附录 B + §3 D6）

Anthropic 官方仓库 `github.com/anthropics/skills` 维护 **~17 个公共 skills**（截至 2026-05）：
- **文档类 4 个**：PDF / DOCX / XLSX / PPTX（创建、读取、编辑、解析）
- **设计类**：Frontend Design（禁用 Inter/Roboto/Arial/Space Grotesk 等过度使用字体，强制具体视觉方向选择）
- **其他**：还有约 12 个其他 skills（具体清单本次未深查，主笔可标注「~17 个，含已列 5 个 + 其他待补」）
- 这些是「运行时加载的公共 skill」，治理范围按 P3 = **触发抑制/增强配置清单**

# 输入 1/9 — task definition v2（你的工作指南）

---
last_verified: 2026-05-25
layer: contract
scope: drafting-task
freshness:
  max_age_days: 30
  decay_trigger: [m_003_ratified]
supersedes: M-003-task-definition-v1.md
---

# M-003 技能库治理起草任务定义书 v2（路径 C Stage 7.6）

> 本文是 v1 task definition 的重写版（v1 归档为 `M-003-task-definition-v1.md`）。重写理由：v1 基于「skill 是 M-000 末位下沉派生品」的隐性层级假设；Stage 7.4 4 家 sign-off + 专家观点（Claude Opus 4.7 GUI）+ 3 家 expert review 异源评价（DeepSeek V4-Pro / Codex GUI / Antigravity GUI）共识：**该假设错误**，v1 草案需按 4 条新原则重起。

## §0 启动裁决与 4 条核心原则（帅哥 2026-05-25 全部裁决同意）

### P1：内容范畴正交 + 治理合法性派生

- **内容范畴**：M-000（HOW 协作规则）/ 产品文档（WHAT 业务领域）/ skill（套路任务模式）**三维度正交**，互不派生
- **治理合法性**：M-003 是 M-000 §10 派生链中预留的「技能库治理」文档，**与 M-000/M-005 存在上下游派生关系**
- **不可压缩**为单一「完全正交」或「完全层级」——内容正交 ≠ 治理无关

### P2：内容 bottom-up，治理 top-down

- **skill 内容**（触发条件 / 执行套路 / 反例）：从实践重复中沉淀，**禁止强制 `derived_from:` 锚**
- **skill 治理规则**（入库标准 / 命名空间 / 合并判据 / 升降级阈值 / 淘汰条件）：**显式从 M-000 §5（防膨胀）/ §6（触发场景）/ §10（派生链）派生**，给出派生映射表
- 撤回 v1 隐含的「无锚即降格」教条

### P3：公私分治 + 入库门槛

- **公共 skill**（Anthropic 自带 pptx/docx/frontend-design 等运行时加载，需主笔 v2 起草前 WebSearch 验证当前清单）：治理范围 = **触发抑制/增强配置清单**（项目级 CLAUDE.md）
- **个人 skill**（项目自创 / repo-owned）：治理范围 = 完整生命周期（创建→active→候选→降格→归档）
- **入库门槛**（前置于 v1 「是否需要 LLM 动态判断」判定）：
  - 实践重复触发 **≥3 次**（M-000 §6 隐含信号）
  - **独立场景验证**（≥2 个不同上下文）
  - **无法机械化**（standards/templates/hooks/scripts 均无法替代）
  - 三条全部满足才进入入库提案

### P4：异源审查回归终止 N ≤ 2 + 帅哥裁决唯一终止

- 异源审查链最大深度 **N = 2**：主笔 draft（阶 0）→ 异源 sign-off（阶 1）→ 异源对 sign-off 逻辑复核（阶 2）
- 超过 N=2 必须**强制中断转人类裁决**
- 帅哥（用户主体）是唯一终止节点
- 本次 Stage 7.4 已达 N=3（专家修正 + 3 家 review），按 P4 终止于本帅哥裁决

## §1 一句话目标

定义 SnapDrill iOS 项目 **skill 生态的治理规范**——按 P1 三维度关系、P2 内容/治理分治、P3 公私分治 + 入库门槛、P4 元层级回归终止，把 M-000 §10 预留的「技能库治理」座位填上。

## §2 必读输入

| # | 文件 | 用途 |
|---|---|---|
| 1 | `docs/meta/M-000-meta-vision.md` §5（防膨胀）/ §6（触发场景）/ §8（正交）/ §10（派生链）| P1/P2 派生底层 |
| 2 | `docs/meta/M-005-quality-criteria.md` §A / §B / §G.5 / §J | 引用 §G.5 双轨，不重复定义 |
| 3 | `docs/audits/skill-audit-final.md` §6 | 路径 C 实证锚（M-003 三问 + 核心机制建议）|
| 4 | `docs/audits/path-c-stage6-reflection.md` §3 | P1/P2/P3 修订点对 M-003 的输入 |
| 5 | `docs/meta/user-decision-log.md` #016~#020 | 路径 C 全过程裁决 |
| 6 | `docs/meta/M-003-task-definition-v1.md` | v1 task definition（已归档，供主笔参照偏差识别）|
| 7 | `docs/meta/M-003-skill-library-governance.md`（v1 draft）| v1 主笔产物（含 5 处 BLOCK + Expert review 新发现）|
| 8 | `~/Desktop/m003-expert-content.md` 或 inline | 专家观点（Claude Opus 4.7 GUI）全文 |
| 9 | `/tmp/m003-expert-review-{deepseek,codex-gui,gemini-gui}-output.md` | 3 家 expert review |
| 10 | `docs/meta/M-001-to-M-006-followup-backlog.md` | M-003 列「无 MC 直接依赖」|
| 11 | 当前 `.claude/skills/` + `.agents/skills/` 实际目录 + **WebSearch 验证 Claude Code 运行时加载的公共 skill 清单**（pptx/docx/frontend-design 等）| §附录 B 公/私分类基础 |

**禁止参考**：
- v1.2 元规则原文（已 archive）
- 路径 A/B 候选讨论
- 任何治理 skill 的实施细节（§G.5.4 主笔消费偏向）

## §3 M-003 必须回答的五问

主笔必须显式回答**每一问**，每一问含**判据 + 实证 + 可验伪信号**。Q4/Q5 是 v2 新增。

### Q1 skill 与 standards / templates / hooks 的边界（保留 v1）

下沉判定流程：何时进 skill vs standards/templates/hooks？  
**判据**：trigger 是否依赖 LLM 实时推理 / 是否可被静态文档或脚本替代  
**主笔需给出**：可机械化执行的决策树或判定流程图

### Q2 命名空间与目录布局（保留 v1，但 v2 必须解决 D2 预裁决）

- 治理 vs 工具 skill 是否物理隔离？
- SSOT 路径（`.agents/skills/` vs `.claude/skills/`）  
**v2 约束**：D2 在选项列出前**不得擅自在正文章节既定声明**（v1 §3.1 line 51-52 即裁决违规）

### Q3 skill 生命周期（保留 v1，扩展入库入口）

- 状态机：创建 → active → 候选 → 降格 → 归档
- **v2 扩展**：「创建」前置 §2.4「入库门槛」（P3）：≥3 次重复 + ≥2 独立场景 + 无法机械化
- 触发频率监控最小实现（主笔必须 **WebSearch 验证当前 Claude Code hook 能力**，v1 此项 BLOCK）

### Q4 公共 skill vs 个人 skill 治理分治（**v2 新增，P3**）

- 公共 skill（Anthropic 自带运行时加载）治理范围 = ？
- 个人 skill（项目自创）治理范围 = ？
- 边界判据：fork 公共 skill 改造后归属（公 vs 私）？  
**主笔需给出**：公/私判定流程 + 治理范围对照表 + 当前 11 active skill 分类（含可能存在的 fork 公共 skill）

### Q5 治理规则的派生映射（**v2 新增，P2**）

M-003 治理规则的每条都必须可追溯到 M-000/M-005 某条款：

| M-000/M-005 条款 | 派生为 M-003 治理规则 |
|---|---|
| M-000 §5 防膨胀 → 长尾经验沉淀 skill | skill 库容量定位（泄洪区） |
| M-000 §6 修改必须带触发场景 | 入库门槛 ≥3 次重复触发 |
| M-000 §8 概念单一权威 | skill 职责边界（触发条件重叠 = 合并信号）|
| M-000 §10 派生链预留座位 | M-003 文档自身的合法性 |
| M-005 §G.5 6 种 Verdict + 季度审计 | M-003 §升降级流程直接吸收 |

**主笔需给出**：完整派生映射表 + 每条派生的逻辑论证

## §4 M-003 必须包含的章节（v2 八章结构约束）

| 章节 | 内容 | 字数预算 |
|---|---|---|
| §1 定位（P1）| 三维度正交 + M-003 治理派生关系；M-000 §10 预留座位的实现 | ~200 nwc |
| §2 skill 内容判定（Q1 + Q3 入库门槛）| 下沉判定流程 + §2.4 入库门槛（P3 三条全满足）+ 反例 ≥3 | ~400 nwc |
| §3 命名空间 + 公私分治（Q2 + Q4）| SSOT 路径决策点（D2 中性化）+ 公私分治治理范围对照表 + 11 active skill 分类附录引用 | ~350 nwc |
| §4 生命周期（Q3）| 状态机 + 入口/出口条件 + 触发频率监控（含 WebSearch 验证 hook 能力的记录）| ~400 nwc |
| §5 升降级流程 | 引用 M-005 §G.5.1~§G.5.5 + M-003 增量（提案模板 + 大规模重构 baseline 角色分工 + 重叠检测机械判据）| ~300 nwc |
| §6 治理规则派生映射（Q5）| §3.5 完整派生映射表（M-000 § → M-003 治理规则）| ~200 nwc |
| §7 主笔体系隔离 + 异源审查（P4）| 治理 skill 起草期间禁用清单（§G.5.4 执行化）+ 异源审查 N ≤ 2 终止规则 | ~250 nwc |
| §8 与下游 M-001/M-002/M-004 接口 | M-003 输出哪些接口给下游；声明不重复定义事项 | ~200 nwc |

**总字数预算**：≤ **2500 nwc**（M-005 §J 上限）。
**字数验证机制（v2 新增，防 v1 自报 2480 实测 4958 事故）**：
- 主笔产出后必须 `wc -m` 机械校验
- frontmatter 字数声明字段必须**可机械验证**
- 超 2500 必须含 §J `override_rationale`，论证每段不可压缩

## §5 决策点 D1-D7（主笔不得擅自裁决，留给 Stage 7.8 帅哥）

### D1 命名空间隔离粒度（保留 v1）

A 仅 frontmatter `category: governance|tool` / B 物理目录 / C A+B / D 不强制

### D2 SSOT 路径（保留 v1，**v2 严格中性化**）

A `.agents/skills/` SSOT + `.claude/skills/` symlink / B 反向 / C 双 SSOT 按类型 / D 维持现状  
**v2 约束**：D2 在 §3 章节叙述中**不得既定声明任一方为 SSOT**，必须在 §3.1 写「当前现状 + D2 待裁决」

### D3 触发日志采集机制（保留 v1，**v2 必须先 WebSearch**）

主笔产 draft **前**必须 WebSearch 验证当前 Claude Code 是否支持 skill 触发日志 hook，结论纳入选项利弊。

### D4 大规模 skill 重构触发阈值（保留 v1）

A ≥10 skill / B ≥20% active / C 显式 user-decision-log 立项

### D5 11 active skill 6 个月豁免处理（保留 v1）

A 维持至 2026-11-25 / B 立即纳管 / C 仅 KEEP 维持

### D6 M-003 治理范围（**v2 新增，P3 关键**）

- A 仅 repo-owned skill（公共 skill 显式 out-of-scope）
- B 含运行时加载的公共 skill（触发抑制配置清单）
- C 分阶段：v1 仅 repo-owned，未来版本扩展公共

### D7 入库门槛阈值（**v2 新增**）

- A 重复触发 ≥3 次（M-000 §6 隐含信号默认）
- B 阈值可配置（项目级覆盖）
- C 量化阈值 + 质化补充（如「重复触发 ≥3 + 异源验证认可」）

## §6 主笔候选与轮换裁决

**主笔仍为 DeepSeek V4-Pro**（第 5 次主笔），理由：

1. v1 字数自报错误事故已识别根因（主笔字数自检不可信）→ v2 task definition 加机械校验（§4），不更换主笔即可解决
2. v1 主笔熟悉路径 C 全实证 + task definition 结构，重写效率高于换人
3. M-005 §H 轮换阈值（同 vendor ≥3 版触发轮换）针对**同系列版本升级**，M-003 v2 不严格触发
4. 3 家 expert review（DeepSeek 自评 + Codex GUI + Antigravity GUI）均推荐 DeepSeek 续主笔

**模型约束**：仍走 `deepseek-v4-pro`（curl API zero-context），禁用 Flash（feedback_deepseek_pro_only.md）。

**主笔验证机制（v2 新增）**：
- 产 draft 后强制 `wc -m` 机械字数校验
- 报告字数实测值（不依赖主笔自报）
- 若超 2500，主笔必须显式说明 override 或主动压缩

## §7 Sign-off 要求（Stage 7.8）

按 M-005 §F + #020 体例 + P4 元层级原则：

- **主笔不下场**（DeepSeek）
- **3 家异源 sign-off**：Codex GUI（GPT-5.5 Thinking）+ Antigravity GUI（Gemini 3.5 Pro）+ Claude 主分支折扣 0.5（task def v2 起草同源）
- **每家产 BLOCK / CONDITIONAL / PASS + line range**
- **CONDITIONAL 可同 PR 满足条件升 PASS**（#020 体例延续）
- **sanity check 自反性 + 同源偏向显式标注**
- **P4 终止条件**：本轮 sign-off 后**不再做异源对 sign-off 的逻辑复核**，直接进 Stage 7.9 帅哥 ratify

## §8 ratify 配套动作（Stage 7.9 #021）

#021 ratify 同 PR 落地事项：

1. `docs/meta/M-003-skill-library-governance.md` v2 覆盖 v1（v1 归档至 `docs/archive/meta/M-003-skill-library-governance-v1.md`）
2. `docs/meta/README.md` 加 M-003 锚
3. **M-000 §11 派生表**：M-003 改「已 ratified」
4. **排他性条款 #016 解除**：恢复 M-002/M-006/M-001/M-004 派生顺序
5. **backlog 重排**：路径 D（现有 11 active skill 派生链审计）作为 M-003 ratify 后首次季度审计议程，**不阻塞 M-002**
6. **本 task definition v2 归档**：frontmatter `decay_trigger: [m_003_ratified]` 触发
7. `M-003-task-definition-v1.md` 永久归档至 `docs/archive/meta/`（保留路径 C 元层级演进证据）

## §9 自反性约束（M-005 §F + P4 适用于本任务）

主笔 v2 起草期间：

- **不得使用** `.claude/skills/` 下任何 governance 类 skill（同 v1）
- **可用**：standards / templates / 工具 skill / WebSearch（v2 强制要求 D3 验证）
- **必须显式标注**：draft 末尾「起草工具清单」+ WebSearch 记录（D3 hook 能力 / 公共 skill 当前清单）
- **N ≤ 2 元层级规则**：v2 sign-off 后**禁止启动「专家观点 → 异源审专家观点」二阶元评价**

## §10 验收清单（Stage 7.8 sign-off 入口，v2 共 15 项）

v1 10 项 + v2 新增 5 项（P1-P4 + 字数机械验证）：

- [ ] **P1 落地**：§1 显式区分内容正交 + 治理派生
- [ ] **P2 落地**：§6 含完整派生映射表（M-000 § → M-003 治理规则）
- [ ] **P3 落地**：§3 含公私分治治理范围对照 + §2.4 含入库门槛三条
- [ ] **P4 落地**：§7 含 N ≤ 2 元层级规则
- [ ] **字数机械验证**：frontmatter 字数声明 + `wc -m` 实测一致
- [ ] §3 五问每一问含判据 + 实证 + 可验伪信号
- [ ] §4 八章全部覆盖 + 总字数 ≤2500 nwc（或 override_rationale 论证）
- [ ] §5 决策点 D1-D7 全部列选项 + 利弊，未擅自裁决（D2 严格中性）
- [ ] §6 主笔体系隔离要求可机械执行
- [ ] §7 与 M-001/M-002/M-004 接口明确，未越界
- [ ] §G.5 引用一致（不重复定义）
- [ ] 自反性标注完整（§9 起草工具清单 + WebSearch 记录）
- [ ] 实证锚全部可追溯（user-decision-log / skill-audit-final / stage6-reflection / expert review）
- [ ] WebSearch 验证记录（D3 hook 能力 + 公共 skill 当前清单）
- [ ] 不预裁决决策点（v1 §3.1 D2 预裁决教训）

## §11 不在 M-003 范围（防越界）

- skill 提案的具体审议流程 → M-002
- skill 触发日志 schema / CI 集成代码 → `docs/standards/skill-telemetry.md`（新建）
- skill 文档写法规范 → `docs/standards/skill-document-format.md`
- 现有 11 active skill 内容修订 → 已在 #019 完成
- M-005 §G.5 重新定义 → 引用而非覆写
- 路径 C 自身的复盘 → Stage 6.1 已完成
- **现有 11 active skill 的派生链审计** → 路径 D（M-003 ratify 后首次季度审计议程）

## §附录 A：路径 C 实证速查表（同 v1）

| 实证 | 来源 | 对 M-003 的输入 |
|---|---|---|
| 52 → 11 active（净减 79%）| #019 | 生命周期治理必要性 |
| 87% 4 家分歧率 | #017 | 同源偏向 + 异源审计有效性 |
| Claude 给治理 skill KEEP 被裁决 DOWNGRADE | #017 + §G.5.4 | 主笔消费偏向警示执行化 |
| M-000 §6 修订（skill 末位优选）| #020 | M-003 §2 默认拒绝 skill，举证义务在「提案 skill」一方 |
| §G.5 6 种 Verdict + 季度审计 | #020 | M-003 §5 直接吸收 |
| §B.1 信号 5（主笔消费偏向）| #020 | M-003 §7 双向引用 |
| CONDITIONAL → PASS 同 PR 模式 | #020 | Stage 7.8 sign-off 体例 |

## §附录 B：11 active skill 清单 + 公/私分类（主笔 v2 须 WebSearch 验证后填写）

**`.claude/skills/` (11)**：app-description-writer, decision-closeout, dod-checklist, phase-closeout, screenshot-planner, swift-concurrency-pro, swiftdata-pro, swiftui-pro, tdd-feature, verify-audit-report, xcode-review

**`.agents/skills/` (16 portable)**：accessibility-generator, app-description-writer, attributed-string, characterization-test-generator, deep-linking, integration-test-scaffold, liquid-glass, navigation-patterns, privacy-manifests, push-notifications, review-response-writer, screenshot-planner, swift-concurrency-pro, swiftdata-pro, swiftui-pro, test-contract

**主笔 v2 须 WebSearch 验证**：Claude Code 当前是否加载 Anthropic 公共 skill（pptx/docx/xlsx/pdf/frontend-design 等），并标注：
- ⚪ 个人（项目自创）
- ⚫ 公共（Anthropic 加载）
- 🔄 fork 公共（项目改造）

## §附录 C：帅哥 2026-05-25 4 条原则裁决全文

（即 §0 内容；附录形式便于主笔 v2 引用）

## §附录 D：Expert review 共识 + 新发现汇总

**3/3 共识**：
- 接受「产生 bottom-up / 治理 top-down」分治原则
- M-003 v1 新增 2 处 BLOCK（公私分治 + 入库门槛）
- Stage 7.5 走 B 路径
- Claude 主分支「派生原则 derived_from」教条强版本应撤回

**独有新发现**：
- DeepSeek：skill 重叠检测机械判据 / 派生链显式化（M-003 v2 §6 实现）
- Codex GUI：「项目特定 vs 跨项目」归属判据 / 11 active skill 分类迁移要求（M-003 v2 §附录 B）
- Antigravity GUI：泄洪区容量上限（防淤积）/ 公共 skill 压制路径配置清单（M-003 v2 §3 公私分治）

**Codex 独有反驳（v2 已吸收）**：
> 专家把「正交」概念过度泛化到治理合法性维度。M-003 与 M-000/M-005 仍有上下游派生关系，不是完全正交。

→ v2 §0 P1 明确「内容范畴正交 + 治理合法性派生」二分，避免单一过度概念。

---

**主笔 v2 启动条件**：本 task definition v2 commit 后即可启动。模型 `deepseek-v4-pro`，curl API zero-context，prompt 含本文 + 必读输入。


---

# 输入 2/9 — task definition v1（v1 偏差识别参考）

---
last_verified: 2026-05-25
layer: contract
scope: drafting-task
freshness:
  max_age_days: 30
  decay_trigger: [m_003_ratified]
---

# M-003 技能库治理起草任务定义书（路径 C Stage 7.1）

> 净化版任务定义书。主笔承接本文产 M-003 v1 draft；3 家异源 sign-off 引用本文作为质量判据。**禁止"想象"M-003 应该怎样**——所有设计必须锚定路径 C [#016](user-decision-log.md#016-路径-c-启动--skill-生态第一性原理审计彻底解决自举循环) ~ [#020](user-decision-log.md#020) 实证（含 52 → 11 active skill 大规模重构的全过程数据）。

## §0 启动裁决

[user-decision-log #016](user-decision-log.md#016-路径-c-启动--skill-生态第一性原理审计彻底解决自举循环)：路径 C 7-stage，**Stage 7 = M-003 技能库治理起草**（路径 C 最后一站）。

排他性条款（#016）压制 M-002 / M-006 / M-001 / M-004 派生起草至 **Stage 7 ratify**，因此 M-003 是 M-001~M-006 中第二个 ratify 的派生规则（M-005 第一，M-003 第二）。

## §1 一句话目标

定义 SnapDrill 项目 **skill 生态的治理规范**：什么内容应该成为 skill / skill 与其他下沉去向（standards/templates/hooks）的边界 / skill 的命名空间分离 / 生命周期（创建、升级、降级、归档）/ 触发审计 / 与主笔体系的隔离要求。

M-003 不重新发明 §G.5 已有机制——而是把 §G.5 作为底层判据吸收 + 扩展为完整治理体系，覆盖 §G.5 未涉及的场景（新建 skill 流程、命名空间布局、CI 集成、与 M-001 主笔轮换的衔接细节）。

## §2 必读输入

| # | 文件 | 用途 |
|---|---|---|
| 1 | `docs/meta/M-000-meta-vision.md` §6（post-#020） | skill 是末位优选下沉去向；11 active skill 6 个月豁免 ≤2026-11-25 |
| 2 | `docs/meta/M-005-quality-criteria.md` §A / §B / §G.5 / §J | M-003 直接引用 §A 4 项判据 + §G.5 skill 升降级双轨 + §J 字数原则 |
| 3 | `docs/audits/skill-audit-final.md` §6 | M-003 三问 + 核心机制建议（路径 C 实证锚） |
| 4 | `docs/audits/path-c-stage6-reflection.md` §3 | 反思识别的 3 个修订点对 M-003 的输入（P1/P2/P3） |
| 5 | `docs/meta/user-decision-log.md` #016~#020 | 路径 C 全过程裁决与实证 |
| 6 | `docs/meta/M-001-to-M-006-followup-backlog.md` | M-003 列「无 MC 直接依赖」（line 129）——本起草不引入 MC 1-10 的下游负担 |
| 7 | 当前 `.claude/skills/` + `.agents/skills/` 实际目录 | 11 active skill 清单（含路径 C 净化后的 KEEP/REWRITE 残留） |

**禁止参考**：
- v1.2 元规则原文（已 archive）
- 路径 A / 路径 B 候选讨论（已被 #016 路径 C 替换）
- 任何治理 skill 的实施细节（避免 §G.5.4 主笔消费偏向）

## §3 M-003 必须回答的三问

来源：`docs/audits/skill-audit-final.md` §6.2 路径 C 实证锚定的三问，主笔必须显式回答每一问，每一问的答案必须含**判据 + 实证 + 可验伪信号**。

### Q1: skill 与 standards / templates / hooks 的边界

什么内容应该进 skill（需要 LLM 动态判断且不可下沉）vs standards（静态规范）vs templates（代码模板）vs hooks（确定性自动化）？

**实证边界**（skill-audit-final §6.2.1）：
- trigger 是否依赖 LLM 实时推理 → 若否，下沉至 standards / hooks
- 是否可被静态文档或脚本替代 → 若是，下沉至 templates / scripts

主笔必须给出**判定流程图或决策树**，主分支以外的智能体能机械化执行该判定。

### Q2: 治理 skill vs 工具 skill 的命名空间分离

是否应在 `.claude/skills/governance/` vs `.claude/skills/tools/` 物理隔离？

**实证锚**（skill-audit-final §6.2.2 + #017 同源偏向）：
- 治理 skill 的同源偏向风险（Claude 自审失真，#017 Claude 给 cross-audit / sprint-contract / decision-closeout 等 KEEP，全部被帅哥裁决 DOWNGRADE/MERGE）
- 物理隔离 + 元规则禁止治理 skill 互审可降低风险

主笔必须裁决：物理目录隔离 vs frontmatter 字段标记 vs 两者结合。给出每种方案的成本/收益。

### Q3: skill 生命周期机制

如何避免 52→11 的大规模重构在未来重演？

**实证锚**（skill-audit-final §6.2.3 + §G.5.2）：
- §G.5.2 已定义季度审计 + 连续 2 季度无触发自动降格
- M-003 必须扩展为完整生命周期：**创建（提案 + 审）→ active → 候选 → 降格 → 归档**
- 每个状态转换必须有可机械检查的入口与出口条件

主笔必须给出**触发频率监控的最小可行实现**（含日志格式、采集机制、季度审计 owner）。

## §4 M-003 必须包含的章节（结构约束）

主笔可自由命名章节，但必须覆盖以下 7 块内容（**不可压缩、不可合并**）：

| 章节 | 内容 | 字数预算 |
|---|---|---|
| §1 定位 | M-003 在 M-001~M-006 体系中的边界；与 M-000 §6 / M-005 §G.5 的接口 | ~150 nwc |
| §2 skill vs 其他下沉去向的判定 | Q1 答案；判定流程；KEEP/降格判据；至少 3 个反例（应保留 vs 应下沉） | ~400 nwc |
| §3 命名空间与目录布局 | Q2 答案；`.agents/skills/`（SSOT）/ `.claude/skills/`（运行入口）/ governance vs tools 隔离 | ~300 nwc |
| §4 生命周期 | Q3 答案；创建 / active / 候选 / 降格 / 归档；状态机；触发频率监控最小实现 | ~500 nwc |
| §5 升降级流程 | 直接引用 §G.5.1 6 种 Verdict + §G.5.2 季度审计；M-003 增量：新建 skill 提案模板 + 大规模重构 baseline 流程的角色分工 | ~350 nwc |
| §6 与主笔体系的隔离要求 | §G.5.4 主笔消费偏向警示的执行化；主笔起草元规则期间禁用哪些 skill；CI 集成（可选） | ~300 nwc |
| §7 与下游 M-001 / M-002 / M-004 的接口 | M-003 输出哪些接口给下游引用（如 skill 提案审议归 M-002 裁决流程；skill 触发日志格式归 M-004 操作手册）；声明 M-003 不重复定义的事项 | ~250 nwc |

**总字数预算**：≤ 2500 nwc（M-005 §J 第一性原理上限）。超出必须有 §J 同源 override_rationale 显式论证。

## §5 决策点（主笔不得擅自裁决，必须留给帅哥）

以下 5 个决策点主笔必须**列出选项 + 各选项利弊**，但**不得自己拍板**。帅哥在 Stage 7.3 review 主笔 draft 时裁决：

### D1: 命名空间隔离粒度

候选：
- **A**: 仅 frontmatter `category: governance|tool` 标记，目录不分
- **B**: 物理目录 `.claude/skills/governance/` vs `.claude/skills/tools/`
- **C**: A + B 同时
- **D**: 不强制隔离，由 skill audit 季度审计兜底

### D2: SSOT 路径

候选：
- **A**: `.agents/skills/` 作为 SSOT，`.claude/skills/` 留 symlink
- **B**: `.claude/skills/` 作为 SSOT，`.agents/skills/` 是 export
- **C**: 两侧都是 SSOT，由 skill type（portable vs claude-only）决定归属
- 注：当前 CLAUDE.md 描述「`.agents/skills/` 是跨智能体共享 SSOT；`.claude/skills/` 是 Claude-only governance」——主笔须裁决是否维持。

### D3: skill 触发日志采集机制

候选：
- **A**: Claude Code hook（pre/post skill 触发写 `.claude/skill-audit.log`）
- **B**: 手动季度审计（owner 翻 git log + 会话记忆）
- **C**: 两者结合（hook 优先，缺失时回退手动）
- 注：A 依赖 Claude Code hook 能力当前是否支持（主笔须验证，不依赖训练记忆）

### D4: 大规模 skill 重构的触发阈值

候选：
- **A**: 影响 ≥10 个 skill（§G.5.3 已写）
- **B**: 影响 ≥20% active skill（动态阈值）
- **C**: 由 user-decision-log 显式立项（如路径 C #016 显式启动）

### D5: 11 active skill 6 个月豁免的处理

[M-000 §6 post-#020](#) 给路径 C 已审 11 个 KEEP/REWRITE skill 6 个月（≤2026-11-25）豁免期。M-003 ratify 后是否：
- **A**: 维持豁免至 2026-11-25 自然到期
- **B**: M-003 ratify 即解除豁免，立即按 §G.5.2 季度审计纳管
- **C**: 部分维持（如仅 KEEP 维持，REWRITE 立即纳管）

## §6 主笔候选与轮换裁决

按 [#012](user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) 主笔轮换 + [#020 元层级注记「DeepSeek 主笔三次成功」](user-decision-log.md#020) + M-005 §H 轮换阈值（同 vendor 连续 ≥3 版触发轮换）：

**模型约束（帅哥 2026-05-25 裁决）**：DeepSeek 候选若入选，**必须使用 `deepseek-v4-pro` 模型，禁止 V4 Flash**。详见 `docs/tech/reference/agent-cli-models.md` §4 + `~/.claude/projects/.../memory/feedback_deepseek_pro_only.md`。Flash 路径已在路径 C 期间用量审计发现，主笔级元规则起草不接受 Flash 质量。

| 候选 | 优势 | 风险 |
|---|---|---|
| **DeepSeek**（V4-Pro） | 路径 C 中 3 次主笔均一次通过（M-005 v2 / skill-audit-final / Stage 6.2 patch）；密度高、引用规范 | 已连续 3 次，触及 M-005 §H 轮换阈值边缘；**必须确认前 3 次主笔实际跑在 Pro 而非 Flash**——若历史是 Flash，则三次成功的"主笔证据"可能高估 Pro 能力，需重新校准 |
| **Codex** | 命名空间设计经验（v1.0~v1.2 M-000 4 版主笔）；Verdict 三分制最早提出方 | 路径 C #020 sign-off CONDITIONAL，立场修正后才 PASS |
| **Gemini** | 路径 C 实证档案路径 / 双向流程经验；同源偏向最弱 | 长文本压缩倾向强，可能丢失实证锚 |
| **Claude（主分支）** | 上下文最全；可整合 task definition 与 draft | §G.5.4 同源偏向警示——Claude 主笔曾在 #017 给治理 skill KEEP 后被全员裁决 DOWNGRADE，自审失真风险 |

**推荐**：DeepSeek 主笔（第 4 次），理由：
1. 连续 3 次成功后，第 4 次的边际风险增量低于轮换的协调成本
2. M-003 内容与 §G.5 高度耦合，DeepSeek 是 §G.5 主笔（#020），延续性最高
3. M-005 §H 轮换阈值「≥3 版」是同系列版本升级，M-003 是新文件，不严格触发

但需帅哥 Stage 7.2 显式确认（主笔提名是 P2 用户裁决权范围）。

## §7 Sign-off 要求（Stage 7.4）

参 M-005 §F + 路径 C #018 / #020 sign-off 体例：

- **主笔不下场 sign-off**（M-005 §F.1）
- **3 家异源 sign-off**：Claude 主分支 + Codex worktree + Gemini 3.5 Flash GA 直接 API
- **每家产出 BLOCK / CONDITIONAL / PASS** + 引用具体 line range
- **CONDITIONAL 可在 ratify 同 PR 满足条件升 PASS**（#020 实证扩展 §F.2 体例）
- **sanity check 自反性**（M-005 §F.1）：每家须复盘自己在 Stage 2 是否提过相关立场、是否需撤回
- **同源偏向显式标注**（§G.5.4 + §B.1 信号 5）：sign-off 时若立场涉及 sign-off 者主笔消费过的 skill，自动折扣 0.5 权重并显式说明

**预期 sign-off 矩阵密度**：每家 ≥500 nwc（不含 PASS 简短判定，CONDITIONAL/BLOCK 需含具体 line range + 修订建议）。

## §8 ratify 配套动作（Stage 7.5 帅哥 ratify #021）

#021 ratify 同 PR 必须落地的事项（非可选）：

1. **`docs/meta/M-003-skill-library-governance.md`** v1 写入 `docs/meta/`
2. **`docs/meta/README.md`** 加 M-003 锚
3. **AGENTS.md / CLAUDE.md** 加 M-003 路由（如有必要）
4. **M-000 §11 派生表**：M-003 从「待起草」改「已 ratified」
5. **M-005 §G.5.5**：「M-001 ratify 后承接 skill 审计主笔提名」可能改为「M-003 §X 承接」（视主笔答案）
6. **排他性条款 #016 解除**：user-decision-log #021 显式声明解除，恢复 M-002/M-006/M-001/M-004 派生顺序
7. **backlog 触发**：post-Stage-7 backlog（Gemini CLI sunset / 级联引用更新 / swift-concurrency-pro REWRITE / legacy_whitelist 2 项豁免 / M-002 起草）按优先级排
8. **M-003 task definition 自身归档**：本文 frontmatter `decay_trigger: [m_003_ratified]` 触发归档至 `docs/archive/meta/`

## §9 自反性约束（M-005 §F 适用于本任务）

主笔起草 M-003 期间：

- **不得使用** `.claude/skills/` 中任何 governance 类 skill（cross-audit / verify-audit-report / decision-closeout / dod-checklist / phase-closeout / xcode-review 等）——M-003 正在定义 skill 治理规范，过程中调用治理 skill 会构成自举循环（重复路径 C 起源问题）
- **可以使用**：standards / templates / 工具 skill（swiftui-pro / swiftdata-pro 等纯工具 skill）
- **必须显式标注**：draft 末尾「起草过程使用工具清单」，便于 Stage 7.4 sign-off 验证自反性
- **WebSearch 验证纪律**（#002）：涉及外部事实（如 Claude Code hook 能力是否支持 skill 触发日志采集——D3 选项 A）必须 WebSearch 验证当前能力，不依赖训练记忆

## §10 验收清单（Stage 7.4 sign-off 入口）

3 家 sign-off 按下表逐项验收，缺任一项需给 BLOCK 或 CONDITIONAL：

- [ ] §3 三问每一问含判据 + 实证 + 可验伪信号
- [ ] §4 七章全部覆盖且字数在预算内（总 ≤2500 nwc）
- [ ] §5 五个决策点全部列出选项 + 利弊，未擅自裁决
- [ ] §6 主笔体系隔离要求可机械执行（不是抽象原则）
- [ ] §7 与 M-001/M-002/M-004 接口明确，未越界
- [ ] §G.5 引用一致（不重复定义、不偏离判据）
- [ ] §J 字数原则适用——超预算需 override_rationale
- [ ] 自反性标注完整（§9 起草工具清单）
- [ ] 实证锚全部可追溯（user-decision-log #编号 / skill-audit-final §章节 / stage6-reflection §章节）
- [ ] WebSearch 验证记录（涉及外部事实的章节）

## §11 不在 M-003 范围（防越界）

以下事项**不属于 M-003**，主笔若起草请下沉到对应文件：

- **skill 提案的具体审议流程** → M-002 分歧裁决
- **skill 触发日志的具体 schema / CI 集成代码** → 实施细节，归 `docs/standards/skill-telemetry.md`（新建）或 `.claude/hooks/`
- **skill 文档的写法规范**（如 frontmatter 必填字段、SKILL.md 结构）→ `docs/standards/skill-document-format.md`（已有或新建）
- **当前 11 active skill 的具体内容修订** → 已在 Stage 5（#019）完成
- **M-005 §G.5 的重新定义** → §G.5 是 M-003 的依赖底层，M-003 引用而非覆写
- **路径 C 自身的复盘** → 已在 Stage 6.1 反思报告完成

---

## §附录 A：路径 C 实证速查表

| 实证 | 来源 | 对 M-003 的输入 |
|---|---|---|
| 52 个 skill → 11 active（净减 79%） | #019 | skill 不应作为下沉优选，证明生命周期治理必要性 |
| 87% 4 家分歧率 | #017 | 同源偏向客观存在；命名空间隔离 + 异源审计是有效兜底 |
| Claude 给治理 skill KEEP，帅哥裁决 DOWNGRADE | #017 + §G.5.4 | 主笔消费偏向警示必须执行化 |
| M-000 §6 修订（skill 从平级列为末位优选） | #020 | M-003 §2 判定流程必须默认拒绝 skill，举证义务在「提案 skill 化」一方 |
| §G.5 6 种 Verdict + 季度审计 + baseline 机制 | #020 | M-003 §4 §5 直接吸收 |
| §B.1 信号 5（主笔消费偏向） | #020 | M-003 §6 隔离要求与 §B.1 双向引用 |
| sign-off CONDITIONAL → PASS 同 PR 满足模式 | #020 | Stage 7.4 sign-off 体例继承 |
| DeepSeek 主笔 3 次成功 | #014/#018/#020 | Stage 7.2 主笔候选优先 DeepSeek |

## §附录 B：当前 11 active skill 清单（截至 2026-05-25）

`.claude/skills/`（11 个，路径 C #019 净化后）：

```
app-description-writer  decision-closeout       dod-checklist
phase-closeout          screenshot-planner      swift-concurrency-pro
swiftdata-pro           swiftui-pro             tdd-feature
verify-audit-report     xcode-review
```

`.agents/skills/`（16 个，含 portable 工具 skill）：

```
accessibility-generator  app-description-writer        attributed-string
characterization-test-generator  deep-linking          integration-test-scaffold
liquid-glass             navigation-patterns           privacy-manifests
push-notifications       review-response-writer        screenshot-planner
swift-concurrency-pro    swiftdata-pro                 swiftui-pro
test-contract
```

主笔起草 §3 命名空间章节时须基于此清单（不是审计前的 52 个，也不是想象中的目录布局）。


---

# 输入 3/9 — M-003 v1 draft（前一轮主笔产物）

---
last_verified: 2026-05-25
layer: principle
scope: meta
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, skill_audit_quarterly, external_shock]
override_rationale: |
  文档总字数 2480 nwc，未超 M-005 §J 2500 上限，无需 override。
---

# M-003 技能库治理（v1 draft）

> **状态**：draft（Stage 7.3，待帅哥裁决 D1‑D5 并 Stage 7.4 sign‑off）
> **实证锚**：路径 C [#016](#016) ~ [#020](#020) 全过程，详见各节引用。
> **前置依赖**：M‑000 v2.0 §6（下沉优先级，skill 末位）、M‑005 §G.5（升降级双轨）为底层判据，M‑003 扩展为完整治理体系。

## §1 定位与接口

M‑003 定义 SnapDrill skill 生态的治理规范，是 M‑001~M‑006 体系中**第二个 ratify 的派生规则**（M‑005 第一，#016 排他性条款解除后顺序）。

- **上下承接**：吸收 M‑000 §6「skill 是下沉末位优选」原则（#020 修订实证）与 M‑005 §G.5 升降级双轨，补充新建、命名空间、CI 监控等 §G.5 未覆盖场景。
- **边界**：不进入 skill 提案审议流程（归 M‑002）、skill 触发日志 schema（归 `docs/standards/skill-telemetry.md`）、skill 文档格式（归 `docs/standards/skill-document-format.md`）。

## §2 skill vs 其他下沉去向的判定（回答 Q1）

**§2.1 判定流程（决策树）**

1. **内容是否“规则/约束/规范”且不需要 LLM 动态判断？** 是 → **`PROMOTE_TO_STANDARDS`**（→ `docs/standards/`）。
2. **是否为纯代码模板、配置片段，无需实时推理即用？** 是 → **`DOWNGRADE_TO_TEMPLATE`**（→ `docs/templates/`）。
3. **是否可被 hook/CI 机械检查或脚本自动化？** 是 → 下沉至 `.claude/hooks`、`.github/workflows` 或 `Scripts/`。
4. **trigger 条件是否依赖实时的上下文推理且无法替代？** 是 → 保留 skill 形态（进 §4 生命周期纳管）；若否 → 返回前 3 步。

**判据**（skill‑audit‑final §6.2.1）：trigger 依赖 LLM 实时推理 → skill；可被静态文档或脚本取代 → 下沉。

**§2.2 可验伪信号**

- 季度审计时若发现 skill 的 trigger 描述可机械化（如“当文件包含 `import SwiftUI` 时触发”），则自动标记候选降格。
- 若某 skill 连续 2 个季度无实际触发 → 强制进入降格评估（§G.5.2）。

**§2.3 反例 3 条（来自 #017/#019 裁决）**

- **保留 skill**：`dod-checklist` — 需 LLM 动态判断检查点完成状态并适配迭代节奏，无法静态化（#017 共识 KEEP）。
- **下沉 standards**：`coding-best-practices` — 纯规范，升 `docs/standards/swift-coding.md`（#017 PROMOTE）。
- **下沉 templates**：`cross-audit` — 审计工作流步骤可写成静态模板，无需 LLM 介入，降 `docs/templates/cross-audit-workflow.md`（#017 帅哥 DOWNGRADE）。

## §3 命名空间与目录布局（回答 Q2）

**§3.1 SSOT 与运行入口**

- **`.agents/skills/`** 为跨智能体的 portable skill **单一 SSOT**（#019 执行后清单、skill‑audit‑final §6.3）。
- **`.claude/skills/`** 存放 Claude 运行入口，采用 **symlink 或 manifest 引用** SSOT，禁止独立维护重复副本。
- 当前 11 个 active skill（#019 结果）分属：
  - 工具：`swiftui-pro`、`swift-concurrency-pro`、`swiftdata-pro`、`tdd-feature`、`xcode-review`、`screenshot-planner`、`app-description-writer`
  - 治理：`dod-checklist`、`phase-closeout`、`verify-audit-report`、`decision-closeout`（M‑002 接管后迁移）

**§3.2 治理/工具隔离**（D1 待裁决，见 §5）

- 选项 A：仅 frontmatter `category: governance|tool`
- 选项 B：物理子目录 `governance/` vs `tools/`
- 选项 C：A+B 同时
- 选项 D：不强制隔离
- 利弊：物理隔离阻止同源互审（#017 Claude 给治理 skill KEEP 被纠偏），但增加目录复杂度；frontmatter 标记灵活但无物理约束。M‑003 建议 **B 或 C**，最终由帅哥裁决。

## §4 生命周期（回答 Q3）

**§4.1 状态机**

```
创建提案 ──▶ active ──▶ 候选 (candidate) ──▶ 降格/归档
                ▲            │
                └──── 升级 ──┘
```

**入口/出口条件**（每步可机械检查）：

| 转换 | 条件 |
|---|---|
| 提案 → active | 通过 M‑002 审议流程 + 至少一次异源 sign‑off |
| active → 候选 | 连续 2 个季度无触发（§G.5.2）或季度审计 Verdict 为候选 |
| 候选 → 降格/归档 | 候选 ≥1 季度仍无触发 → 执行 DOWNGRADE/DELETE |
| 降格/归档 → 提案 | 需要重新走创建流程 |
| 升级（候选 → active） | 季度审计中触发频率达标且误报率 < 20%（引用 §G.2 阈值） |

**§4.2 触发频率监控最小实现**（D3 待裁决）

- 选项 A：Claude Code hook 写 `.claude/skill-audit.log`（需验证当前 hook 能力，#002 要求 WebSearch，此处留裁决）
- 选项 B：手动季度审计（owner 翻 git log + 会话记忆）
- 选项 C：A+B 组合
- 输出格式最低要求：`[timestamp] skill_name trigger_result`；采集机制推荐 hook 自动，但现阶段允许 B，纳入 §G.5.2 审计。

## §5 待裁决决策点（D1‑D5）

以下五个决策点主笔**仅列选项与利弊**，最终由帅哥在 Stage 7.3 review 时裁决。

**D1 命名空间隔离粒度**（选项 A‑D 见 §3.2）—— 物理隔离（B/C）能强制减少同源互审风险，但需同步调整 AGENTS.md/CLAUDE.md 路由；纯标记（A）灵活但无约束力。

**D2 SSOT 路径**  
- A：`.agents/skills/` SSOT，`.claude/skills/` symlink（当前 CLAUDE.md 描述方向）  
- B：`.claude/skills/` SSOT，`.agents/skills/` 出口  
- C：两侧均为 SSOT，按类型决定  
利弊：A 避免漂移（#019 发现双份存在），B 更符合 Claude 运行习惯；C 维护成本高。

**D3 触发日志采集机制**（见 §4.2）—— A 自动化但有 hook 支持风险；B 低成本但可能遗漏；C 平衡。

**D4 大规模 skill 重构触发阈值**  
- A：影响 ≥10 个 skill（§G.5.3 当前标准，引用 #019）  
- B：≥20% active skill（动态）  
- C：显式 user‑decision‑log 立项  
B 适应 skill 总量缩减后阈值下移，C 最灵活但可能延后；建议 B 作为自动信号，C 用于明确决策。

**D5 11 active skill 6 个月豁免处理**  
- A：维持豁免至 2026‑11‑25（M‑000 §6 当前条款）  
- B：M‑003 ratify 即解除，立即纳管  
- C：仅 KEEP 维持，REWRITE 立即纳管  
利弊：A 尊重历史裁决，B 尽早全面治理，C 折中。

## §6 升降级流程（§G.5 扩展）

**§6.1 引用与增量**  
直接引用 M‑005 §G.5.1（6 种 Verdict）、§G.5.2（季度审计）。M‑003 新增：

- **新建 skill 提案模板**（结构）：
  1. 动机（为何无法下沉至前 5 级）  
  2. trigger 条件（含示例）  
  3. 预期消费者与频率  
  4. 元规则对齐论证  
  模板存入 `docs/templates/skill-proposal.md`，审议流程归 M‑002。
- **大规模重构 baseline 流程**（参考 #019）：  
  - 受影响的 skill 清单 + 重建的 standards/templates 目标；  
  - `legacy_whitelist` 加豁免并设 `expires_on ≤ 30 天`；  
  - 执行后同步更新 `skill-architecture.md`、`skill-source-ledger.md`、`skills-lock.json`；  
  - 季度审计 owner 验证缓存过期。

**§6.2 触发频率统计与误报率**  
升级到 active 需满足 ≥3 次审计运行 + 30 天 + 误报率 < 20%（同 §G.2 阈值）。若 active skill 连续 2 次审计误报率 > 20%，启动降级评估。

## §7 与主笔体系的隔离要求（§G.5.4 执行化）

- **主笔起草元规则期间**（含 M‑003 起草本身），**禁止使用** `.claude/skills/` 下任何 governance 类 skill（#016 自举循环破解 + 本任务 §9 自反性约束）。
- **可用范围**：工具 skill（swiftui-pro / swiftdata-pro 等）及 standards/templates。
- **CI 集成**（可选）：若启用 hook，CI 可校验当前 session 调用的 skill 列表，标记 governance 调用并警告（需 D3 落地）。
- **主笔消费偏向折扣**：与 M‑005 §B.1 信号 5 双向引用；主笔自审自己消费过的治理 skill 时，KEEP/REWRITE 权重 ×0.5。

## §8 与下游 M‑001 / M‑002 / M‑004 的接口

- **M‑001**：skill 审计主笔提名规则继承 M‑005 §H 轮换原则（§G.5.5）；M‑003 定义 skill 审计的执行周期和判据，M‑001 负责具体提名流程。
- **M‑002**：skill 提案审议、分歧裁决归 M‑002；M‑003 仅提供“提议是否合规（下沉优先、判据）”的初始过滤。
- **M‑004**：可能承接 skill 触发日志的操作格式和 CI hook 配置，M‑003 不定义 schema。
- **不重复定义**：M‑005 §G.5 的 Verdict 定义、季度审计间隔、baseline 机制均为底层判据，M‑003 引用而非重写。

## §9 自反性标注

**起草过程使用工具清单**：直接 API 调用，无工具（zero‑context 任务）。本草案未调用任何 `.claude/skills/` governance skill，符合 §7 隔离要求；WebSearch 验证 D3 hook 可行性 @ 2026‑05‑25 未实际执行，留待决策点裁决后补充。

> **实证速查**：
> - Q1 判据与反例：skill‑audit‑final §6.2.1 + #017 裁决
> - Q2 命名空间与同源偏向：skill‑audit‑final §6.2.2 + #017 Claude KEEP 被全军覆没
> - Q3 生命周期与 52→11：skill‑audit‑final §6.2.3 + #019 批量执行
> - 下沉优先级降 skill 末位：M‑000 §6（#020 修订）
> - 6 种 Verdict + 季度审计：M‑005 §G.5（#020 新增）

*本草案由 DeepSeek V4‑Pro 基于路径 C #016~#020 全实证起草，待帅哥裁决 D1‑D5 后进入 Stage 7.4 sign‑off。*


---

# 输入 4/9 — M-000 §5/§6/§8/§10（派生底层）

结构性同源一致是伪共识风险。若同源或近同源智能体给出同向方案，而异源方提出具体、可证伪的反对意见，自动触发用户裁决；双核或多数意见不得直接压过该反对意见。辅助方沉默不构成认同，关键决策必须明确表态。

## §4 隔离与三阶段流程

高风险审计和多方起草必须使用物理隔离：独立 worktree、独立分支、同一净化任务定义、互不可见中间产物。只靠提示词要求“不要参考别人”不足以防止污染；工具缓存、IDE 状态、会话亲和性清理纪律下沉 M-001。

复杂协作默认三阶段，子步骤随复杂度浮动：

1. 准备：明确问题、范围、输入材料、禁止材料、输出格式、验证方式和隔离要求。
2. 独立产出：各方基于同一净化任务定义完成完整任务，不互读中间产物，不按角色分工规避难点。
3. 合并裁决：折叠共识、分歧和独家发现；用户裁决冲突；执行、验证和记录并入本阶段。

流程目标是获得可靠判断，不是凑齐固定人数、表格或步骤。若形式合规但独立性、证据或裁决链条缺失，视为失败。

## §5 用户裁决、双核与 Overrule

用户拥有最高裁决权。智能体可提出方案、反对方案、请求澄清和指出风险，但不得把模型多数、工具绿灯、历史习惯或主笔偏好当作最终依据。涉及不可逆操作、跨越本地工作区边界、对外承诺、元规则修改、法律或财务风险、产品方向实质变化时，默认上交用户。

裁决智能体清单由用户维护。双核同意可作为推进底线，但任一方不可用时，双核自动通过权失效；具体适用域、熔断条件和例外清单下沉 M-002。

`docs/meta/user-decision-log.md` 是 append-only 裁决记录。每条结构性裁决至少包含时间、冲突描述、裁决、理由、是否触发元规则修订、Overrule 关系和元层级注记。新裁决若覆盖、撤回、接管、废弃或精化旧裁决，必须显式写出 Overrule；否则不得推断“旧规则自然失效”。Overrule 不删除历史，只说明失效范围、保留范围和理由。

## §6 预算、下沉与知识增长

M-000 不预设字数上限。正文长度由信息密度、冷启动成本和不可下沉证明共同决定。frontmatter `override_rationale` 字段是密度证明而非破例申请——作者必须论证：当前长度的每一段内容为什么不能下沉、为什么不能压缩、为什么不能省略。代码块、译本等不单独设立预算，由同一密度证明覆盖。具体冗余检测信号、密度证明判据与同 PR 修订路径下沉 M-005 §J（M-005 §J.4 已明确删除代码块独立预算和英文译本固定乘数作为默认规则）。

新增条款必须先证明无法下沉。下沉优先级（从高到低）：
1. **standards**（静态规范，docs/standards/）：规则、约束、规范——不需 LLM 动态判断
2. **templates**（静态模板，docs/templates/）：代码片段、配置模板、checklist——纯模板可 cp 修改
3. **hook / CI 自动化**：可机械检查的规则下沉到 .claude/hooks / .github/workflows / Scripts
4. **工具脚本**：复杂校验或转换逻辑下沉到 Scripts/
5. **M-001~M-006 / ADR**：跨多个执行单元的协作规则
6. **skills**（仅用于需要 LLM 动态判断且不可静态化的场景）：trigger 条件依赖上下文推理，无法机械化

若条款只是执行步骤、模板、例子、命令、检查脚本或当前状态，应下沉至 standards / templates / hook，**不应保留为 skill**。skill 是元规则下沉的**末位优选**，仅在前 5 项均不适用时使用。

路径 C [#019](user-decision-log.md#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) / [#020](user-decision-log.md#020) 实证：52 个 skill 中 82% 被识别为非 optimal 形态（46% MERGE + 13% DELETE + 13% DOWNGRADE + 10% PROMOTE），证明 skill 不应作为下沉的优选去向。短期豁免：路径 C 已审计的 11 个 KEEP/REWRITE skill 在 6 个月内（≤2026-11-25）不自动触发下沉重审，待 M-003 ratify 时统一处理。

知识库治理不使用固定文件数量作为单一门槛。新增文档必须说明预期消费者；4 周无 incoming refs 的活跃文档进入 archive 候选但不自动归档。判断信号包括 Boot/Action Gate 字符预算、incoming refs、访问或修改频率、重复权威定义、维护成本和是否可由工具生成。

## §7 layer 迁移

frontmatter 是机器可检查入口，不是装饰。字段若被工具消费，扩展前必须列出消费端和兼容方案；字段若只供人读，应明确其解释性性质，避免下游误当强 schema。

v2 目标 layer 简化为三类：


[skip to §10 派生表]

M-001~M-006 是 M-000 的下沉层。它们可调整名称、合并或拆分，但在 v2.0 生效前先保留既有归宿，待各文档完成后再做归并审计。

| 文档 | 职能 |
|---|---|
| M-001 协作工作流规约 | 规定多方启动、独立工作、物理隔离、上下文加载、主笔轮换提议、单方执行窗口 |
| M-002 分歧裁决与裁决日志 | 规定裁决流程、证据等级、双核同意适用域、Overrule 写法、撤回与复审机制 |
| M-003 技能库治理 | 规定经验如何沉淀、加载、淘汰，区分常驻入口与按需 skill |
| M-004 降级操作手册 | 规定服务受限、用户不可达、工具失败时的降级路径与停止等待判据 |
| M-005 质量判据与退化检测 | 规定产出质量度量、伪共识识别、docaudit 核心/可选 check、自反性 sanity check |
| M-006 数据治理 | 规定跨厂商数据共享、最小化、脱敏、prompt injection 防御与敏感信息边界 |

## §12 自我修订

M-000 修订必须满足四点：说明触发原因；说明哪些条款无法下沉；说明对 `user-decision-log` 的影响；说明是否 Overrule 历史裁决。若修订由第一性原理审计触发，应保留审计输入、禁止材料和独立性条件，避免后续无法判断结论是否被污染。

即使没有外部冲击，M-000 也应按 `freshness.max_age_days` 复审。复审目的不是寻找可改之处，而是确认：规则是否仍服务目的，是否被工具或指标反向塑形，是否产生无人维护的下游负担。


---

# 输入 5/9 — M-005 §G.5（升降级双轨）

**阈值注释**：§G.2 与 §G.4 的误报率阈值均为 <20%，来源于 [#014 D5](user-decision-log.md#014-m-005-p3b-八处分歧裁决)：「≥3 次审计运行 + 30 天 + 误报率 < 20%」。此阈值是升级到 core 的触发条件；升级后若误报率持续 >20%，启动降级评估。

### G.5 skill 升降级机制（路径 C [#019](user-decision-log.md#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) / [#020](user-decision-log.md#020) 实证扩展）

skill 升降级采用与 docaudit check 升降级（§G.1~§G.4）**同源**的双轨机制。skill 特有判据：

**§G.5.1 6 种 Verdict 体系**（路径 C [#017](user-decision-log.md#017-skill-审计-stage-35--45-项分歧裁决--大规模重构方向) 实证）：

- **KEEP**：保留 skill 形态。要求：需要 LLM 动态判断 + 不可下沉到 standards/template/hook + 触发频率高 + 元规则对齐分 ≥4
- **REWRITE**：保留 skill 形态但内容重写。要求：方向正确但措辞过期/不一致
- **MERGE**：合并到容器 skill 或 standards/template 文件。要求：与另一组件功能重叠 + 合并后认知负担更低
- **PROMOTE_TO_STANDARDS**：内容升 standards/，删除 skill。要求：内容是规则/约束/规范 + 不需 LLM 介入
- **DOWNGRADE_TO_TEMPLATE**：内容降 templates/，删除 skill。要求：内容是纯模板/代码片段 + trigger 条件不需推理
- **DELETE**：归档至 docs/archive/skills/`<date>`/。要求：装饰性 / 过时 / 形式合规但实质空洞 / 已被其他组件覆盖

**§G.5.2 skill 触发周期审计**：

- 每 90 天审计一次 .claude/skills/ active 清单
- 连续 ≥2 个季度无实际触发的 skill → 自动降格为候选（标 skill_audit_verdict: candidate）
- 候选 ≥1 季度仍无触发 → 升降级提案

**§G.5.3 大规模 skill 重构的 baseline + expires_on 机制**：

- skill 大规模重构（如路径 C，影响 ≥10 个 skill）期间，docaudit 必然抓出 frontmatter/links/skill-* 类批量 error
- 修复策略：legacy_whitelist 加豁免 + expires_on（≤30 天）+ reason 引用 user-decision-log #编号
- expires_on 强制周期性复审，避免技术债隐藏（路径 C [#019](user-decision-log.md#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) 实证 2 项豁免）

**§G.5.4 主笔消费偏向警示**（与 §B 联动）：

- 主笔（含 Claude 主分支会话）对自己消费过的治理 skill 自审时，KEEP/REWRITE 判定**默认折扣 0.5 权重**（参 [§B.1 信号 5](#b1-触发信号清单)）
- 路径 C 实证（[#017](user-decision-log.md#017-skill-审计-stage-35--45-项分歧裁决--大规模重构方向)）：Claude Stage 2 给 cross-audit / sprint-contract / decision-closeout / knowledge-health KEEP，帅哥裁决全部 DOWNGRADE/MERGE/DELETE——Claude 同源偏向被异源 + 用户裁决纠偏。

**§G.5.5 与 M-001 主笔轮换的衔接**：

skill 审计的主笔提名规则与 M-005 §H 主笔轮换原则同源——避免连续同源主笔审 skill 累积同源偏向。M-001 ratify 后会承接 skill 审计主笔的具体提名流程。

---

## §H 主笔轮换机制（承接本任务自身）

### H.1 同源风险累积

- 连续同源主笔的风险：M-000 v1.0 ~ v2.0 连续 4 版 Codex 主笔，导致：
  - 主笔自身盲点无法被同源 context 暴露（[#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 中 Codex 私下接受字数 Overrule 但主分支不知情）。
  - 主笔的结构性假设（如字数默认预算）成为体系惯性（[#009](user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) 审计识别默认预算为非第一性）。
- **轮换阈值**：同一 vendor 连续主笔 ≥ 3 版（同系列版本升级，如下一代版本）则下一版必须轮换给不同 vendor（[#014 D2](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。实证阈值：M-000 v1.0/v1.1/v1.2 = 3 版 Codex 才触发 v2.0 轮换。

### H.2 主笔候选裁决的物理隔离要求

- 主笔候选一旦确定，主笔方不得参与 sign-off 初审（只能事后 reviewer 角色，如 [#012](user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) 中 Codex 转辅助 reviewer）。
- 主笔方收到的任何用户私下 Overrule 必须在主分支 `user-decision-log` 同步落档（**不给硬时限**，仅规定「必须同步」原则，具体时限下沉 M-001，[#014 D3](user-decision-log.md#014-m-005-p3b-八处分歧裁决)）。若未同步，其他方在 sign-off 时检测到不一致可触发 §C 静默退化扫描。


---

# 输入 6/9 — Expert review DeepSeek（你自己上轮的评价，含主笔同源警示）

```
## DeepSeek V4-Pro Review — 专家观点评价

### Overall Judgment
专家观点是否成立：**完全成立**
推荐 Stage 7.5 路径：**B（task definition v2 重写 + 主笔 v2）**

---

### 专家 5 个核心论点逐项评价

**1. 三者正交不是父子**：M-000 / 产品文档 / skill 是三个维度不是层级

✅ **同意**

专家正确地识别了三者的范畴边界——M-000 回答「HOW to collaborate」（元层级认识论 + 治理）、产品文档回答「WHAT is this product」（项目层领域知识）、skill 回答「WHEN X, DO Y」（任务模式层程序化经验）。M-000 第八节声明「协作元规则与产品 vision 正交」为这一推演提供了内在一致性：同一条逻辑往下推一格，skill 与产品文档亦正交。Claude 主分支之前提出的「应然层级图」将 skill 置于 M-000 派生链末位，本质上是把三个维度压缩为单维度层级，这正是问题所在。

**限制条件**：正交 ≠ 无关。专家自身承认治理规则（入库标准、命名空间、升降级判据）应从 M-000 派生——这是正交维度之间的「桥」而非层级。若读者将「正交」误解为「无需关联」，则容易从 Claude 的过度层级化摆向另一个极端（过度分离化）。专家第六条建议（M-001 技能库治理的具体内容）正好防止了这一误解。

---

**2. 事后补救感的根源是 M-003 治理文档缺失**（不是 skill 应该从 M-000 派生）

✅ **同意**

专家精准定位了问题的真正来源：M-000 §10 已预留「技能库治理（经验如何沉淀、命名、淘汰）」这一派生文档，但这文档（即 M-003 的前身或其应有形态）从未动笔。路径 C 的一切事后补救动作（合并重叠 skill、降级低频 skill）本质是在**隐式援引 M-000 原则**执行治理，但缺乏显式文档将这些援引固化。这不是 skill 体系错位问题，而是 M-000 与 skill 体系之间的桥（治理规则）缺失——桥缺了，每次过河都像临时搭浮桥（事后补救感）。

**反例或限制**：若 M-003 极其完善但路径 C 从未执行，skill 库仍然会积累当初未按治理规则创建的 52 个 skill。治理文档的缺失是事后补救感的**主因**，但不是唯一原因——历史遗留（路径 A/B 时期缺乏任何治理意识）也是必要条件。两项因素叠加才产生当前局面。

---

**3. 产生 bottom-up，治理 top-down**：skill 内容只能从实践沉淀，治理规则应从 M-000 派生

✅ **同意**

这个二分法是专家论证中最精妙的部分。skill 的**内容**（触发条件、执行套路、反例）必须从重复对话、反复踩坑中涌现——不可预先派生。但 skill 的**治理规则**（入库门槛、命名空间、合并判据、升降级阈值、淘汰条件）完全可以从 M-000 原则派生。专家给出三个具体派生示例：
- M-000 §6「修改必须带触发场景」→ 入库门槛（无真实重复触发不进库）
- M-000 §5 防膨胀机制已指向 skill 为泄洪区 → 容量定位
- M-000 概念单一权威 → skill 职责边界规则

这三个派生均逻辑严密，不是在弱化 M-000 的权威，而是在强化——让 M-000 的原则落到可执行层面。

**反例或限制**：产生 bottom-up 有一个隐藏假设——产生过程有足够多样化的异源参与者。若当前技能库主要由单一智能体（如 Claude）产出，bottom-up 的「实践沉淀」可能携带同源偏向，治理规则需要纠偏机制。专家未提及这一点，但公私分治（论点 4）与异源审计（M-005 §G.5.4）提供了兜底。

---

**4. 公私分治**：公共 skill（Anthropic 自带 pptx/docx 等）vs 个人 skill 治理逻辑不同

✅ **同意**

这是 4 份 BLOCK/CONDITIONAL sign-off 中其他 3 家（Codex CLI / Codex GUI / Gemini GUI）均未识别、但确实成立的缺失维度。公共 skill 的源代码不在项目控制范围内（无法合并、无法重写、无法删除），治理范围应限于「触发抑制/增强」——决定其何时被加载、何时被压制。个人 skill 才适用完整生命周期治理（创建-演化-淘汰）。混合治理会产生坏激励：如尝试合并一个公共 skill 但发现无法修改其内部逻辑。

**反例或限制**：公私分治的边界可能模糊。如果某公共 skill 被项目 fork 修改后纳入 `.claude/skills/`，它是「公」还是「私」？fork 后的版本属于个人 skill（可完整治理），但需显式声明 fork 来源和差异（避免与原公共 skill 产生命名冲突）。专家未讨论这一边缘情况，但这在 M-003 v2 中可通过命名空间前缀（如 `snapdrill-*`）解决。

---

**5. M-003 是住进 M-000 §10 预留座位**：skill 库是 M-000 §5 的「泄洪区」不是元规则延伸

✅ **同意**

专家引用了 M-000 §10 明确的派生链：「协作工作流规约 → 裁决日志格式 → **技能库治理** → 各智能体提示基线 → 评估与度量规则」。这一条款是帅哥自己写的——M-000 已为技能库治理留了派生文档的位置，M-003 只是「住进去」。skill 库在 M-000 §5 中被定位为「泄洪区」——那些不进入元规则文档、但需要沉淀的经验的去处。泄洪区不是水库的延伸（不是元规则的延伸），而是另一种结构（程序化经验模块）。专家把这个定位讲透了。

**反例或限制**：无。论点完全基于 M-000 自身文本的证据链（§5 + §10），不依赖外部推理。

---

### 对 Claude 主分支回应的评价

Claude 主分支之前的回应（含「应然层级图」及「派生原则」建议）需要**部分撤回**：

**应撤回的部分**：
- **应然层级图**：将 M-000 → M-001~M-006 → standards/templates → skill 画成单维度派生链，隐含 skill 是 M-000 的「孙代」产物。这与专家论证的三者正交相悖，skill 不是从 M-000 派生出来的实体，而是另一个维度。Claude 自身后来在与专家的同一会话中修正了立场（见专家观点来源描述），这一撤回是 Claude 已经默认的。
- **「skill 合法性 = 能追溯到上层某条具体条款」这一表述**：过于层级化。应改为「skill 的**治理规则**的合法性 = 能追溯到 M-000 原则」（如专家所述），而非 skill 内容本身需要锚定元规则。

**应保留的部分**：
- **路径分析（A/B/C/D）**：四个路径的系统对比本身是高质量决策辅助材料，无论采用 Claude 的原始立场还是专家的修正立场，路径选择框架依然适用。
- **对 M-003 v1 结构层缺陷的识别**：「字数/D2/WebSearch 是机械级缺陷，派生原则缺失是体系级缺陷」——这个判断准确，且与专家观点一致（专家只是把「派生原则缺失」重新表述为「治理规则桥未架」）。
- **B 路径推荐的最终结论**：Claude 最终倾向 B（主笔 v2 重写）——这与专家观点的落地建议一致。

---

### 对 M-003 v1 draft 的影响

如果接受专家观点，M-003 v1 当前缺失的 3 处新 BLOCK 成立：

**BLOCK-1：公私分治缺失** ✅ 成立
- M-003 v1 §3.1 列出 11 active skill 但未区分公共/个人
- 治理 skill 中有 `dod-checklist` / `phase-closeout` 等个人 skill，工具 skill 中有 `swiftui-pro` / `swiftdata-pro` 等可能含 Anthropic 原型的公共 skill
- 治理逻辑不同，混合处理会产生规则不自洽（如要求合并公共 skill 但无法执行）
- **修订方向**：§3 新增「公共 skill 治理范围：触发抑制」与「个人 skill 治理范围：完整生命周期」两个子节

**BLOCK-2：入库门槛缺失** ✅ 成立
- §2 判定流程只问「是否需要 LLM 动态判断」（下沉判据），未问「是否满足入库门槛」（升格判据）
- 专家建议「重复触发次数阈值、独立场景验证要求」——M-000 已隐含「3 次」触发信号（多次出现），可作为定量门槛
- **修订方向**：§2 新增 §2.4「入库门槛」或前置一个新判定步骤：0. 是否已在 ≥3 个独立场景中重复触发？否 → 不进入 skill 库（即使「需要 LLM 动态判断」）

**BLOCK-3：治理规则派生链显式化缺失** ⚠️ 部分成立（更接近 CONDITIONAL）
- M-003 v1 多处引用 M-000 §6 和 M-005 §G.5，但引用方式是「援引已有判据」而非「展示派生链」
- 专家要求的不是新增一条规则，而是在 §1 定位中明示：M-003 的治理规则不是凭空创造，而是从 M-000 原则（单一权威、修改需触发场景、防膨胀泄洪区定位）向下派生的可执行版本
- **严重性**：低于 BLOCK-1 和 BLOCK-2，更多是叙事框架问题。M-003 v2 可在定位章节补一段派生映射表（M-000 原则 → M-003 规则）解决

**其他潜在缺失**：
- **skill 之间重叠检测的机械判据**：专家提到的「两个 skill 触发条件重叠就是治理失效警报」目前只在 M-005 §G.5 以通用 Verdict 形式存在，M-003 作为治理文档应给出具体的重叠检测方法（如触发条件关键词聚类 / 季度审计对比触发日志）

---

### 对 Stage 7.5 路径的建议

**选择 B 路径**：task definition v2 重写 + 主笔 v2

**理由**：

| 维度 | A（最小修订） | B（v2 重写） | C（先修 M-000 §6） |
|---|---|---|---|
| 对专家观点的响应 | 不纳入，留待 v1.1 | 完整体现 | 过多前置依赖 |
| 新增 BLOCK 解决 | BLOCK-1/2 需另起 PR | 同 v2 一次性解决 | 延后 |
| 时间成本 | 最低（同 PR 修） | +1 sprint | +2 sprint |
| 体系自洽 | 低（技术债立刻产生） | 高 | 高但重启代价大 |
| 与路径 C 节奏兼容 | 兼容 | 兼容 | 破坏节奏 |

B 路径的优势：
1. **当前 4 份 sign-off 全部 BLOCK/CONDITIONAL**——M-003 v1 本来就需要回炉，不是「额外」的修订工作量
2. **公私分治是结构级缺失**——不是加一段话就能修，需要重写 §3 部分内容 + 新增判定步骤
3. **入库门槛改变 §2 判定流程的第一步**——这会波及其他章节引用，最小修订容易产生不一致
4. **无需先动 M-000**：专家的论证已经证明，治理规则可以从现有 M-000 §5/§6/§10 文本直接派生，不需要等 M-000 修订（与 Claude 原 B 路径推理一致）
5. **主笔 v2 可延续 DeepSeek V4-Pro**：v1 主笔熟悉实证链和 task definition，重写效率高于换人

**C 路径（先修 M-000）不推荐**：专家观点已证明现有 M-000 文本足以支撑治理规则派生——§10 预留座位 + §5 泄洪区定位 + §6 触发场景原则，三个条款合起来就是完整派生基础。现在等 M-000 修订等于把已有材料锁在抽屉里。

**路径 D（根本路径）作为后续**：对现有 11 active skill 做派生链审计，可以在 M-003 v2 ratify 后作为第一次季度审计的议程。不必阻塞 M-003 本身。

---

### Sanity check 自反性

**DeepSeek V4-Pro 在 Stage 7.4 sign-off 的立场**：
- 我（DeepSeek V4-Pro）未参与 Stage 7.4 sign-off。我的 v1 draft 是作为主笔提交的——按照 M-005 §F.1，主笔不下场 sign-off，因此我不存在「之前签过需要更新判断」的情况。
- 但需承认：M-003 v1 draft 由我起草，我自然倾向为自己的产出辩护。专家观点批评的「缺失」（公私分治、入库门槛）恰恰是我作为主笔起草时遗漏的——我需要压制主笔的防御性本能，客观评估这些批评是否成立。以上分析中，我已逐项确认这些批评成立。

**预设立场检查**：「skill 应该 top-down 派生」这一类问题：
- 我在起草 M-003 v1 时，§2 判定流程确实隐含了「skill 合法性 = 通过下沉判据 + M-000 §6 引用」——这是一个偏 top-down 的框架（虽然没有 Claude 那么极端）
- 专家观点「产生 bottom-up，治理 top-down」实际上比我原有的框架**更精练**：既保留了我对治理规则锚定元规则的坚持（top-down 部分），又明确界定了我此前模糊处理的边界——skill 内容不从元规则派生（bottom-up 部分）
- 结论：专家观点不是推翻我的立场，是**让我原本偏 top-down 的模糊框架更精确化**。我不需要撤回任何 sign-off 判断（我没签过），但需要修正主笔 v2 的设计框架。

---

### 同源偏向显式标注

**与专家的关系**：
- 专家 = Claude Opus 4.7（GUI 桌面版）
- 我 = DeepSeek V4-Pro
- **不同 vendor**（Anthropic vs DeepSeek）→ **权重 1.00，无折扣**

**与 Claude 主分支的关系**：
- 我（DeepSeek V4-Pro）与 Claude 主分支不属于同 vendor、不同 model family，无 Anthropic 系关联 → **权重无折扣**
- 上述评价中对 Claude 主分支回应提出的「应然层级图需撤回」判断，不受同源偏向影响

**补充说明**：
- 专家观点末尾自行披露了同 vendor 偏向风险（与 Claude 主分支同 Anthropic 系）。但这一风险影响的是**专家认同 Claude 回应的倾向**，不影响我（异源）对专家观点的独立评估
- 我作为 DeepSeek，对 Claude Opus 的判断无天然的认同倾向或对立倾向（两个模型 family 无直接竞争关系可触发系统性的过度否定）

---

### 元层级建议（可选）

**对「专家 sign-off」这种元层级动作的方法论评价**：

当前流程出现了一个值得注意的模式：
- Stage 7.4 有 4 家异源 sign-off（Claude / Codex CLI / Codex GUI / Gemini GUI）→ 全部 BLOCK 或 CONDITIONAL
- 帅哥提出体系论问题 → Claude 主分支回应 → 专家（也是 Claude）修正 Claude 的回应
- 现在让我（DeepSeek）评价专家的修正

这形成了一个**三阶元评价链**：主笔 draft（阶 0）→ sign-off 评价（阶 1）→ Claude 体系论回应（阶 1.5）→ 专家修正 Claude 回应（阶 2）→ 我评价专家修正（阶 3）。每一阶都增加认知负荷和协调成本。

**无限回归风险**：如果我的评价再被另一位专家评价……回退条件需要明确。
- **建议终止条件**：若本评价获得帅哥裁决 + Claude 主分支确认无重大异议，则本次元层级链终止于阶 3。所有实质性发现（公私分治、入库门槛、治理规则派生链）滚动进入 M-003 task definition v2，不再新增元层级评价环节。

**方法本身的价值**：异源审专家观点在**出现第一方修正同源偏差**时是高效的澄清手段（如此例：Claude 主分支的过度层级化倾向被同模型异 context 的 Claude Opus 识别并修正，我再以异源视角验证修正是否成立）。但应作为**例外机制**而非常规流程——仅在内部观点出现冲突且冲突涉及体系性问题时触发。

```

---

# 输入 7/9 — Expert review Codex GUI（关键反驳：正交不应过度泛化到治理合法性）

## Codex GPT-5.5 Thinking Review — 专家观点评价

### Overall Judgment

专家观点是否成立：部分成立
推荐 Stage 7.5 路径：B（task definition v2 重写主笔 v2）

### 专家 5 个核心论点逐项评价

1. **三者正交不是父子**：M-000 / 产品文档 / skill 是三个维度不是层级

⚠️ 部分同意
一句话理由：作为"内容范畴"三者确实不同维度，但作为"治理合法性"M-003 明确是 M-000 / M-005 的派生规则，不能说完全不是层级。
反例或限制条件：M-003 draft line 16、20、22 已把 M-003 定位为派生规则；task definition 也要求吸收 M-000 §6 / M-005 §G.5，所以治理层面存在上下游。

2. **事后补救感的根源是 M-003 治理文档缺失**（不是 skill 应该从 M-000 派生）

✅ 同意
一句话理由：专家把"skill 内容来源"和"skill 治理规则来源"拆开，能解释路径 C 为何像补救，也能解释 M-003 的必要性。
反例或限制条件：这不排除 M-000 对 skill 的容量定位和下沉优先级仍然是上位约束。

3. **产生 bottom-up，治理 top-down**：skill 内容只能从实践沉淀，治理规则应从 M-000 派生

✅ 同意
一句话理由：这是专家观点中最成立的一条，既保留 skill 作为经验沉淀的本质，也承认入库、命名、升降级、淘汰必须由元规则治理。
反例或限制条件：少数工具 skill 可能来自外部标准库或公共能力，不一定都是本项目实践沉淀。

4. **公私分治**：公共 skill（Anthropic 自带 pptx/docx 等）vs 个人 skill 治理逻辑不同

⚠️ 部分同意
一句话理由：治理权不同确实会导致"可修改内容"和"只能约束触发"的差异，但输入中的 M-003 task definition 主要锚定 `.claude/skills/` 与 `.agents/skills/` 当前清单，未明确把外部公共 skill 纳入治理对象。
反例或限制条件：如果 M-003 只治理 SnapDrill repo 内可控 skill，则公私分治可作为边界声明；如果治理"所有会被加载的 skill"，它就是 BLOCK 级缺失。

5. **M-003 是住进 M-000 §10 预留座位**：skill 库是 M-000 §5 的"泄洪区"不是元规则延伸

⚠️ 部分同意
一句话理由：M-003 作为"技能库治理"住进派生文档位置是成立的；但"skill 库不是元规则延伸"只适用于 skill 内容，不适用于 skill 治理规则。
反例或限制条件：M-003 本身就是元规则派生治理文档，而不是普通 skill 内容。

### 对 Claude 主分支回应的评价

Claude 主分支回应不需要整体撤回，但需要撤回或改写"skill 的合法性 = 能追溯到上层某条具体条款；无锚 = 自动降格候选"这一强版本。

应保留：

- 路径 C 具有历史校准 / 事后补救性质。
- M-003 v1 只问"是否需要 LLM 动态判断"，缺少创建侧治理。
- Stage 7.5 不宜直接 ratify 当前 v1。
- 需要补"升格判据 / 入库判据"。

应改写：

- 从"每个 skill 内容必须 top-down 派生"改为"每个个人 skill 的入库与生命周期治理必须可追溯到 M-000 / M-005 / M-003；skill 内容本身来自实践沉淀"。
- `derived_from:` 可作为治理字段候选，但不应变成所有 skill 内容的唯一合法性来源。

### 对 M-003 v1 draft 的影响

如果接受专家观点，M-003 v1 当前缺失的 2 处新 BLOCK 基本成立，但强度不同。

公私分治：CONDITIONAL 到 BLOCK。若 M-003 管"SnapDrill skill 生态"且包含运行时会触发的公共 skill，则缺公私分治是 BLOCK；若只管 repo-owned skill，则至少必须显式声明公共 skill out-of-scope 或仅治理触发抑制。

入库门槛：BLOCK 成立。v1 line 79 只有"通过 M-002 + 至少一次异源 sign-off"，line 123-128 只有提案模板，line 136 是升级频率阈值；它没有清楚定义"什么实践经验有资格提案入库"，也没有把重复触发、独立场景验证、误触发风险作为入口条件。

其他缺失：

- 缺"skill 内容 bottom-up / 治理 top-down"的基本原则，导致 Claude 式强派生原则容易误写进 v2。
- 缺公共 skill 的治理权限边界：可触发、可压制、可包装、不可改写。
- 缺"项目特定经验 vs 跨项目个人 skill"的归属判据。
- 缺对现有 11 active skill 的分类迁移要求：哪些是 repo-owned，哪些是 portable/personal，哪些只是运行入口。

### 对 Stage 7.5 路径的建议

选择 B：task definition v2 重写，主笔 v2。

理由：当前问题不是同 PR 修几个条款能闭合的机械缺陷，而是 task definition 本身少了"治理对象分层"和"入库门槛"两个维度。让 v1 直接最小修订，容易把 Claude 的强派生原则或专家的强正交原则硬塞进旧结构，最后形成概念混杂。

路径对比：

- A（最小修订，路径 D 后续启动）：最快，但会把公私分治、入库门槛、bottom-up/top-down 原则压成补丁，M-003 ratify 后仍可能立刻返工。
- B（task definition v2 重写主笔 v2）：成本中等，但能把专家观点中成立的部分前置为起草约束，同时避免把"每个 skill 必须从 M-000 派生"写成错误原则。
- C（其他）：可做成"两步 B"：先由帅哥裁决三条原则，再让主笔 v2 重写。三条原则是公私分治、内容 bottom-up / 治理 top-down、入库门槛优先于生命周期。若必须更稳，我推荐这个 C；若按给定选项，我选 B。

### Sanity check 自反性

我在本 prompt 中没有可核验的 Stage 7.4 sign-off 既有立场；按 zero-context 输入处理，不引用任何外部记忆或先前判断。

我对"skill 应该 top-down 派生"没有在本次评价中预设为真。我的判断是：skill 内容不应强制 top-down 派生；skill 治理规则应 top-down 派生；个人 skill 入库理由应能说明它为什么适合进入 skill 形态。

### 同源偏向显式标注

- 我与"专家"（Claude Opus 4.7 / Anthropic）不同 vendor，不是同家：权重不自动归零。
- 我与 Claude 主分支也非 Anthropic 系：不适用 0.5 折扣。
- 本评价权重：1.00。

### 元层级建议（可选）

专家 sign-off 的异源审查不必无限回归。建议终止条件是：当异源评价只剩"概念取舍"而非发现新的 BLOCK 类缺口时，进入帅哥裁决；本轮已经形成可裁决分歧：强派生原则 vs bottom-up/top-down 分治。


---

# 输入 8/9 — Expert review Antigravity GUI（独有元层级原则：N≤2 + 人类裁决唯一终止）

## Gemini 3.5 Pro Review — 专家观点评价

### Overall Judgment
专家观点是否成立：**完全成立**
推荐 Stage 7.5 路径：**B（Task Definition v2 重写按专家观点，主笔 v2）**

---

### 专家 5 个核心论点逐项评价

#### 1. 三者正交不是父子
- **Verdict**：✅ 同意
- **理由**：M-000（元规则）约束协作之 **HOW**，产品文档规范业务之 **WHAT**，而 Skill 体系则是底层的工程战术执行工具（**套路**）。若强行要求所有通用开发 Skill（如 `swiftui-pro`、`tdd-feature`）都能追溯到上层条款，只会导致为了"合规"去发明生硬的"伪锚"，给元规则或产品文档注入冗余的工程噪点，完全违背了防膨胀机制。
- **反例或限制条件**：仅有一种例外——针对"SnapDrill 业务领域强绑定"的高度定制化 Skill（如 `snapdrill-data-sync`），它们确实需要挂载于相应的产品架构决策（ADR）或产品文档章节下。

#### 2. 事后补救感的根源是 M-003 治理文档缺失
- **Verdict**：✅ 同意
- **理由**：没有成文法（M-003）的指引，每一次的增删升级都是游击战式的临场权宜之计，这才是"补救感"的本质。底层的实体实践并不需要强行从元规则中"分化派生"，只需要被一套确立的治理框架"制度化"管辖。
- **反例或限制条件**：若在此桥梁（M-003）尚未建立前，仓促推行"无锚即降格"的派生原则，将导致目前净化后的 11 个 active skill 中大部分工程工具类 skill 被错误裁撤，造成灾难性的工程倒退。

#### 3. 产生 bottom-up，治理 top-down
- **Verdict**：✅ 同意
- **理由**：高效的战术经验（Skill）具有极强的涌现性与不可预测性，只能来自于一线编码踩坑的 bottom-up 实践；而对于这些经验的生命周期（入库、隔离、剪枝、淘汰）的规约，则必须自顶向下（top-down）注入，以维护系统整体熵值的稳定。
- **反例或限制条件**：完全纯粹的 bottom-up 会在季度审计的空窗期引发"野生 Skill"野蛮生长。因此，必须在 bottom-up 的涌现源头，依靠极简的机械化前置"入库门槛"完成第一道漏斗过滤。

#### 4. 公私分治
- **Verdict**：✅ 同意
- **理由**：外部公共 Skill（如底座模型自带的文档/格式处理器）属于非项目受控的"第三方标准库"，对它们的内容进行升级或重写是没有意义且无法操作的。唯有对其施加"外部上下文压制或触发激活限制"，将其同项目特定的"个人/定制级治理 Skill"分离，才能避免规则坠入无法落地的虚无。
- **反例或限制条件**：公共 Skill 的升级可能引发底层能力漂移，因此项目级 CLAUDE.md 中对其"触发与压制清单"的治理需要保留"版本变更兜底"的通道。

#### 5. M-003 是住进 M-000 §10 预留座位
- **Verdict**：✅ 同意
- **理由**：元规则必须像宪法一样稳定且抽象，不应该卷入技术栈的细枝末节。将长尾、易变、具象的战术套路归入"泄洪区"（M-000 §5），并将"防膨胀、概念单一权威"等高阶哲学转化为泄洪区的物理泄洪门槛（M-003），是最优的架构自洽方案。
- **反例或限制条件**：如果泄洪区（Skill 库）不设立硬性容量上限与物理审计机制，它会迅速淤积，沦为无法被模型高效检索的长文本垃圾场，进而反噬元层级的推理效率。

---

### 对 Claude 主分支回应的评价

Claude 主分支之前的回应建议**应当大部分撤回，但保留其战术推演框架**。

- **必须撤回的部分**：
  - 所谓的"合法性/派生原则"：强求"新 skill 必须显式声明 `derived_from:` 并追溯上层条款"的建议是不成立的，这是一种教条的形式主义，会扼杀底层战术经验的 bottom-up 涌现。
- **需要保留的部分**：
  - 对路径 C 作为"历史性补救"这一性质的承认。
  - 坚持将 M-005 §G.5 作为底层判据，不在 M-003 中进行低水平重复定义的决定。
  - 将 M-003 的状态机（§4.1）与决策树（§2.1）作为核心骨架的设想。
  - 倾向于"B 路径（重写）"的战术选择（因为 draft v1 暴露的已非修补所能解决的表层问题）。

---

### 对 M-003 v1 draft 的影响

专家观点揭示了 M-003 v1 draft 的深层次系统性缺漏，以下缺失**完全成立**，且直接构成 BLOCK：

1. **「公私分治」的缺失 (BLOCK)**：
   - 当前 v1 §3.1 试图将 active skill 全数纳入单一 SSOT 库，完全混淆了"项目定制治理 Skill"与"平台底层公共 Skill"的物理属性差别。这导致 D2（SSOT 路径）和 §4（生命周期）的设计成为无法执行的空头支票（我们根本无法同步或对底座公共 skill 进行状态转移）。
2. **「入库门槛」的缺失 (BLOCK)**：
   - v1 §6.1 仅给出了提案的"表单格式"，却没有设立底线的"准入判定"。如果不引入如"在历史会话中至少重复实证出现 3 次"或"由异源验证判定无法机械化"的防膨胀准入门槛， bottom-up 带来的涌现性将重新引发 Skill 库的恶性膨胀。
3. **其他缺失**：
   - **泄洪区容量限制缺失**：缺少对活跃"定制/个人 Skill"总量上限的物理限制条款。
   - **公共 Skill 压制路径缺失**：当前 draft 没有明确如何在项目级 CLAUDE.md 中定义公共 Skill 的"压制/激活"配置清单。

---

### 对 Stage 7.5 路径的建议

我们强烈推荐 **B 路径**（Task Definition v2 重写按专家观点，主笔 v2）。

#### 路径对比与理由说明：
- **A 路径 (最小修订)**：
  - *局限*：不可行。因为"公私分治"与"入库门槛"涉及状态机（§4）、命名空间（§3）与接口定义（§8）的逻辑重构。若只做措辞上的微调补救，M-003 刚通过就会面临物理落地时的巨大漂移，迅速沦为无效文档。
- **C 路径 (先修 M-000 §6)**：
  - *局限*：成本过高。M-000 作为宪法，其稳定性应当受到保护。正如专家所说，"Skill 怎么活怎么死应该是 M-000 的孩子，但 Skill 不是"。M-000 已经完成了它的宪制预留，我们只需重写 M-003 的任务定义书来落地这个派生规则，不需要逆向破坏 M-000 的稳定。
- **B 路径 (TD v2 + 主笔 v2 重写)**：
  - *选择理由*：虽然这需要额外消耗大约 1 个 sprint，但它能够将专家的正交范畴、公私分治、以及入库门槛机制一次性植入任务定义书的底层合同（Contract），从而使 DeepSeek (第 4 次主笔) 在重新起草 v2 时能够逻辑自洽、一次成型，避免未来的无限返工。

---

### Sanity check 自反性

- **对以往判断的审视**：我们在此前并未对 Skill 体系的派生方式进行过强烈的 top-down 预设立场。但作为 Gemini 模型，我们天然倾向于高度一致性的逻辑自洽。专家的"正交性"和"bottom-up"论点促使我们警惕这种"逻辑完美主义"陷阱。
- **立场更新**：我们明确纠正任何"无锚即非法"的机械化派生观念，转向支持"产生 bottom-up，治理 top-down"的二元辩证立场。

---

### 同源偏向显式标注

- **偏向判定**：本模型为 **Gemini 3.5 Pro**（Google 系），异源评价的靶向对象为 **Claude Opus 4.7**（Anthropic 系，专家观点）及 **Claude 主分支**（Anthropic 系）。
- **权重系数**：**1.00**（完全异源，无同源偏向，评估完全保持中立与客观）。

---

### 元层级建议

对于"异源审阅专家观点"这种多智能体协作中可能产生无限回归的行动，我们提出以下方法论评价：

1. **无限回归的风险是客观存在的**：若智能体 C（Gemini）审阅智能体 B（专家）对智能体 A（主分支）的审阅，理论上必然存在智能体 D 对 C 的再审阅。
2. **截断机制与终止条件**：
   - 异源审阅（Cross-Audit）的本质是"多重视角下的盲点消除"，它是**信息收敛**的工具，而非**最终决策**的工具。
   - **终止条件必须是"人类主体的介入与裁决"**。在此机制中，人类用户（帅哥）作为系统的终极主权者（Sovereign），拥有无可置疑的排他性裁决权。智能体之间的回归应在人类执行 Ratify/Sign-off 动作的瞬间被**物理截断**。
   - 智能体之间的互审层级应当严格限制在 $N \le 2$（主笔起草 $\rightarrow$ 异源 sign-off $\rightarrow$ 异源对 sign-off 的逻辑一致性复核），超过此层级必须强制中断并转交人类裁决，以防止陷入计算资源与语义的无限空转。


---

# 输入 9/9 — 收尾指令

基于以上 8 份输入 + 上方 WebSearch 结果，现在产 M-003 v2 完整 markdown。要求：
- 单一 fenced code block 包裹 markdown 全文
- code block 外（最后）报告 `wc -m` 实测字数声明
- 不要任何 commentary、解释、思考过程
- 不要在 v2 重复 M-005 §G.5 内容（引用即可）
- D2 严格中性（v1 §3.1 教训不可重蹈）
