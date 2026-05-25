你被请求对 SnapDrill iOS 项目元规则 M-003「技能库治理」**v2 draft** 做异源 sign-off。

# 任务背景

- 路径 C Stage 7.8 — M-003 v2 sign-off（主笔 DeepSeek V4-Pro 第 5 次主笔，不下场）
- v1 主笔产物有 5 处 BLOCK 被 Stage 7.4 4 家 sign-off 抓出 + 帅哥提体系论问题 → Expert review 3 家共识推荐 B 路径 → task definition v2 重写 → DeepSeek 第 5 次主笔产 v2
- v1/v2 主笔字数自检均失真（v1 自报 2480 实测 4958；v2 自报 2412 实测 5132），已识别为 DeepSeek 同源系统性偏差
- v2 frontmatter `override_rationale` 字段由 Claude 主分支代修（事实校正非 LLM 推理，符合主笔独立性边界）

# 你的身份

- **本任务模型**：Codex GPT-5.5 Thinking
- **zero-context**：你没有访问项目仓库文件系统的能力，所有输入 inline
- **独立性**：不参考其他 sign-off 方判断（并发跑）
- **P4 终止规则（task definition v2 §0）**：本轮 sign-off 后**禁止启动二阶元评价**（异源对 sign-off 复核），直接进帅哥 Stage 7.9 ratify

# 输出格式（严格）

只输出 markdown，按以下结构：

```
## [你的名字] Sign-off — M-003 v2

### Overall Verdict
PASS | CONDITIONAL | BLOCK

### Per-section findings (v2 task definition §10 验收清单 15 项)

按下表逐项打分（✅ PASS / ⚠️ CONDITIONAL / ❌ BLOCK）：

1. P1 落地：§1 显式区分内容正交 + 治理派生
2. P2 落地：§6 含完整派生映射表
3. P3 落地：§3 公私分治 + §2.4 入库门槛
4. P4 落地：§7 含 N≤2 元层级规则
5. 字数机械验证：frontmatter 字数声明 + 实测一致（v2 含 word_count_actual: 5132 + override_rationale）
6. §3 五问每问含判据 + 实证 + 可验伪信号
7. §4 八章全部覆盖 + 总字数 ≤2500 nwc（或 override_rationale 论证成立）
8. §5 决策点 D1-D7 全部列选项 + 利弊，未擅自裁决
9. §6 主笔体系隔离要求可机械执行
10. §7 与 M-001/M-002/M-004 接口明确，未越界
11. §G.5 引用一致（不重复定义）
12. 自反性标注完整（§9 起草工具清单 + WebSearch 记录）
13. 实证锚全部可追溯
14. WebSearch 验证记录（D3 hook 能力 + 公共 skill 清单）
15. 不预裁决决策点（v1 D2 预裁决教训）

每项含：✅/⚠️/❌ + line range + 一句话理由

### 关键裁决点：override_rationale 是否成立

v2 正文 5132 nwc 超 §J 上限 105%。Claude 代修的 override_rationale 列出 6 条不可压缩理由（line 9-19）。请独立判定：
- 6 条理由是否都成立？
- 是否存在可压缩空间？（如果可压缩，请指明哪一段）
- 接受 override 还是要求压缩重写？

### BLOCK 项（若有）

含 line range + 问题描述 + 修订建议

### CONDITIONAL 项（若有，可在 ratify 同 PR 满足）

含 line range + 条件描述 + 是否同 PR 可满足（Yes/No）

### Sanity check 自反性

复盘你（Codex GPT-5.5 Thinking）在 Stage 7.4 sign-off + Expert review 阶段是否有过相关立场，是否需要更新。

### 同源偏向显式标注

按 vendor 关系折扣权重。主笔 DeepSeek V4-Pro，task def v2 起草 Claude 主分支。你与谁同 vendor？折扣多少？

### 元层级建议（可选）

仅当发现新结构性问题时使用。**按 P4 N≤2 规则，本 sign-off 不接受「对 Stage 7.4 sign-off 的二阶评价」建议**——元层级建议范围限于 M-003 v2 本身。
```

---

# 输入 1/5 — task definition v2（你的验收标尺）

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

# 输入 2/5 — M-003 v2 draft（line-numbered）

   1  ---
   2  last_verified: 2026-05-25
   3  layer: principle
   4  scope: meta
   5  freshness:
   6    max_age_days: 180
   7    decay_trigger: [meta_audit, skill_audit_quarterly, external_shock]
   8  word_count_actual: 5132  # Claude 主分支 wc 机械实测 2026-05-25（正文 nwc，不含 frontmatter），覆盖主笔自报 2412 nwc 错估
   9  override_rationale: |
  10    正文 5132 nwc（Claude 主分支机械实测，frontmatter 排除），超 M-005 §J 2500 上限 105%。
  11    以下六项不可压缩，缺一即破坏 M-003 治理体系的可执行闭环：
  12    以下六项不可压缩，缺一即破坏 M-003 治理体系的可执行闭环：
  13    (1) 八章结构对应 task definition v2 §4 强约束（§1 P1 / §2 入库门槛 / §3 公私分治 / §4 生命周期 / §5 升降级 + D1-D7 / §6 派生映射 / §7 N≤2 / §8 下游接口），任一压缩使后续 M-002/M-006/M-001/M-004 派生引用 M-003 的接口无法独立解析；
  14    (2) D1-D7 七个决策点必须显式列出选项 + 利弊（task definition v2 §5 硬约束），Stage 7.9 帅哥裁决依赖完整选项陈述，压缩等于剥夺裁决权；
  15    (3) §3 公私分治治理范围对照表 + §6 派生映射表 + §4 状态机 + §2.1 决策树构成 4 个结构化信息块（非散文），结构本身承载语义；
  16    (4) §2.4 入库门槛三条（≥3 次重复 + ≥2 独立场景 + 无法机械化）是 P3 落地的最小完整集，任一条压缩破坏 P3 防膨胀闭环；
  17    (5) §6 派生映射 5 行（M-000 §5/§6/§8/§10 + M-005 §G.5 → M-003 治理规则）是 P2 「治理 top-down」原则的可机械验证证据链，省略即让派生关系隐性化；
  18    (6) 主笔字数自检失真（v1 自报 2480 实测 4958，v2 自报 2412 实测 5328）已被识别为 DeepSeek 同源系统性偏差，宁可走 override 也不接受信息密度损失换取虚假合规。
  19    本 frontmatter 字段补于 Stage 7.7 Claude 主分支代修（事实校正非 LLM 推理，符合主笔独立性边界）。Stage 7.8 sign-off 应判定本 override 是否成立。
  20  ---
  21  
  22  # M-003 技能库治理 v2
  23  
  24  > **状态**：draft（Stage 7.7，待帅哥裁决 D1‑D7 后 Stage 7.8 sign‑off）
  25  > **实证锚**：路径 C #016–#020 全过程，详见各节引用。
  26  > **前置依赖**：M‑000 v2.0 §5/§6/§8/§10、M‑005 §G.5 为底层判据。
  27  
  28  ## §1 定位（内容正交 + 治理派生，P1）
  29  
  30  **三维度内容范畴正交**：
  31  - M‑000（HOW 协作规则）
  32  - 产品文档（WHAT 业务领域）
  33  - skill（WHEN X, DO Y 任务模式套路）
  34  三者互不派生，各自独立演化。
  35  
  36  **治理合法性派生**：
  37  M‑003 是 M‑000 §10 预留的“技能库治理”派生文档；其治理规则（入库、命名、升降级、淘汰）显式从 M‑000/M‑005 派生（见 §6）。**内容正交 ≠ 治理无关**。
  38  
  39  ## §2 skill 内容判定（回答 Q1 + P3 入库门槛）
  40  
  41  ### §2.1 下沉判定流程
  42  
  43  **决策树**（机械化可执行）：
  44  
  45  1. 内容是否静态规则/约束/规范且不需 LLM 动态判断？→ **PROMOTE_TO_STANDARDS**
  46  2. 是否纯代码模板/片段，无需推理即用？→ **DOWNGRADE_TO_TEMPLATE**
  47  3. 是否可被 hook/CI 脚本自动化？→ 下沉 `.claude/hooks`、`.github/workflows` 或 `Scripts/`
  48  4. trigger 条件是否依赖实时上下文推理且无法替代？→ 保留 skill（进入 §2.4 入库检验）
  49  
  50  **判据**（skill‑audit‑final §6.2.1，#017）：trigger 依赖 LLM 实时推理且不可静态化 → skill。
  51  **可验伪信号**：季度审计发现 skill trigger 可机械化则自动标记候选降格。
  52  
  53  **反例 ≥3**：
  54  - ✅ 保留：`dod-checklist` 需 LLM 动态判断完成状态（#017 共识 KEEP）。
  55  - ❌ 下沉 standards：`coding-best-practices` 纯规范 → `docs/standards/swift-coding.md`（#017 PROMOTE）。
  56  - ❌ 下沉 templates：`cross-audit` 审计流程可静态模板化（#017 DOWNGRADE）。
  57  
  58  ### §2.4 入库门槛（P3 三条全满足）
  59  
  60  **仅在 §2.1 判定“可 skill”后适用**；以下三条**全部满足**方可进入入库提案：
  61  
  62  1. **实践重复触发 ≥3 次**（M‑000 §6 隐含信号，路径 C 实证）
  63  2. **≥2 个独立场景验证**（不同上下文/不同消费者）
  64  3. **无法机械化**（standards/templates/hooks/scripts 均无法替代）
  65  
  66  **判据**：#019 52→11 active 证明无门槛导致膨胀；#020 M‑000 §6 修订 skill 末位。
  67  **可验伪信号**：提案若无 ≥3 次触发记录直接退回，季度审计可复核。
  68  
  69  ## §3 命名空间 + 公私分治（回答 Q2 + Q4，P3）
  70  
  71  **当前布局现状**（不预判 SSOT）：
  72  - `.claude/skills/` 含 11 active skill
  73  - `.agents/skills/` 含 16 portable skill，部分重叠
  74  - D2 SSOT 路径待帅哥裁决（见 §5.7 D2）
  75  
  76  ### 公私分治治理范围对照
  77  
  78  | 分类 | 范围 | 治理权限 |
  79  |---|---|---|
  80  | ⚫ 公共 skill（Anthropic 运行时加载） | ~17 个（PDF/DOCX/XLSX/PPTX/Frontend Design 等，WebSearch 2026-05-25） | 仅触发抑制/增强配置清单（项目级 CLAUDE.md），不可改写内容 |
  81  | ⚪ 个人 skill（项目自创，repo‑owned） | `.claude/skills/` 或 `.agents/skills/` 中非公共者 | 完整生命周期（§4） |
  82  | 🔄 fork 公共 skill | 经修改后纳入项目目录 | 属个人 skill，须显式声明来源与差异 |
  83  
  84  **边界判据**：若 skill 源文件不在项目 repo 可控范围内 → 公共；repo 内存在 → 个人或 fork。
  85  **可验伪信号**：公共 skill 治理清单是否维护在 CLAUDE.md 且季度审计时与实际加载一致；fork 声明缺失则记入偏差。
  86  
  87  11 active skill 分类与附录见 §附录 B。
  88  
  89  ## §4 生命周期（回答 Q3 + 触发监控，含 hook 能力记录）
  90  
  91  **状态机**：
  92  
  93  ```
  94  提案 ─▶ active ─▶ 候选 (candidate) ─▶ 降格/归档
  95           ▲            │
  96           └── 升级 ────┘
  97  ```
  98  
  99  **入口/出口条件**（每条可机械检查）：
 100  
 101  | 转换 | 条件 |
 102  |---|---|
 103  | 提案 → active | 通过 §2.4 入库门槛 + M‑002 审议 + 至少一次异源 sign‑off |
 104  | active → 候选 | 连续 2 季度无触发（§G.5.2）或审计 Verdict 候选 |
 105  | 候选 → 降格/归档 | 候选 ≥1 季度仍无触发 → DOWNGRADE/DELETE |
 106  | 升级（候选 → active） | 触发频率达标 + 误报率 < 20%（§G.2） |
 107  
 108  **触发频率监控**：
 109  Claude Code 提供 27 个 hook events（官方文档 2026-05），支持 skill‑scoped hooks（PreToolUse/PostToolUse 等）。可部署 PreToolUse 钩子记录 skill 触发到 `.claude/skill-audit.log`，兜底手动季度审计（git log + 会话记录）。D3 采集机制方案见 §5.7。
 110  
 111  **判据**：52→11 重构证明无生命周期导致膨胀（#019）。
 112  **可验伪信号**：连续 2 季度零触发即自动降格；日志缺失触发条目时审计标记缺失。
 113  
 114  ## §5 升降级流程（引用 M‑005 §G.5 + M‑003 增量）
 115  
 116  直接引用 M‑005 §G.5.1（6 Verdict）、§G.5.2（季度审计）、§G.5.3（大规模重构 baseline）、§G.5.4（主笔消费偏向），不重复定义。
 117  
 118  **M‑003 增量**：
 119  - **提案模板**：动机（为何不可下沉）、trigger 条件与示例、预期消费者与频率、元规则对齐论证；模板存 `docs/templates/skill-proposal.md`，审议归 M‑002。
 120  - **大规模重构基线角色**：参照 #019，影响 ≥10 skill 或 ≥20% active 时，需 legacy_whitelist + expires_on ≤30 天 + 同步更新 skill‑architecture.md/skill‑source‑ledger.md。
 121  - **重叠检测机械判据**：两 skill trigger 条件关键词聚类相似度 > 70% 或触发日志高度重合 → 启动合并评估。
 122  
 123  ### §5.7 待裁决决策点（D1–D7，主笔不裁决）
 124  
 125  **D1 命名空间隔离粒度**
 126  - A 仅 frontmatter `category: governance|tool`
 127  - B 物理目录 `.claude/skills/governance/` vs `tools/`
 128  - C A+B 同时
 129  - D 不强制
 130  利弊：B/C 强制防同源互审（#017 Claude 自审失真），但增目录复杂度；A 灵活但无约束；D 依赖审计兜底风险高。
 131  
 132  **D2 SSOT 路径**（严格中性）
 133  - A `.agents/skills/` SSOT + `.claude/skills/` symlink
 134  - B `.claude/skills/` SSOT，`.agents/` 出口
 135  - C 双 SSOT 按类型
 136  - D 维持现状
 137  利弊：A 避免双份漂移（#019 发现），B 更贴合 Claude 习惯；C 维护成本高；D 保留现存不一致。
 138  
 139  **D3 触发日志采集机制**
 140  - A Claude Code hook 自动化写 `.claude/skill-audit.log`（WebSearch 确认：27 事件 + skill‑scoped hooks，PreToolUse 可采集）
 141  - B 手动季度审计
 142  - C A+B 组合
 143  利弊：A 自动化但需维护 hook；B 低成本但可能遗漏；C 平衡，hook 优先/手动兜底。
 144  
 145  **D4 大规模 skill 重构触发阈值**
 146  - A ≥10 skill（§G.5.3）
 147  - B ≥20% active
 148  - C user‑decision‑log 显式立项
 149  利弊：B 适应总量缩减后的动态阈值；A 固定直观；C 最灵活但可能延后。
 150  
 151  **D5 11 active skill 6 个月豁免处理**
 152  - A 维持豁免至 2026‑11‑25
 153  - B M‑003 ratify 即解除
 154  - C 仅 KEEP 维持，REWRITE 立即纳管
 155  利弊：A 尊重历史裁决；B 尽早全面治理；C 折中。
 156  
 157  **D6 M‑003 治理范围**（P3 关键）
 158  - A 仅 repo‑owned skill（公共 out‑of‑scope）
 159  - B 含公共 skill（触发抑制配置清单）
 160  - C 分阶段：v1 仅 repo‑owned，未来扩展
 161  利弊：B 完整性高但增加复杂度；A 简洁但需显式排除；C 渐进可行。
 162  
 163  **D7 入库门槛阈值**
 164  - A 重复触发 ≥3 次（M‑000 默认）
 165  - B 阈值可配置（项目级覆盖）
 166  - C A + 质化补充（异源验证认可）
 167  利弊：A 固定简单；B 灵活但增加维护；C 综合但判据稍复杂。
 168  
 169  ## §6 治理规则派生映射（P2，回答 Q5）
 170  
 171  | M‑000/M‑005 条款 | 派生为 M‑003 治理规则 |
 172  |---|---|
 173  | M‑000 §5 防膨胀/泄洪区定位 | skill 库容量定位（泄洪区，非元规则延伸） |
 174  | M‑000 §6 修改须带触发场景 | 入库门槛 ≥3 次重复触发（§2.4） |
 175  | M‑000 §8 概念单一权威 | skill 职责边界：触发条件重叠即合并信号（§5） |
 176  | M‑000 §10 派生链预留座位 | M‑003 自身合法性（治理文档住进派生链） |
 177  | M‑005 §G.5 升降级双轨 | M‑003 §4/§5 状态机与升降级流程直接吸收 |
 178  
 179  **判据与可验伪信号**：每条派生均能在对应条款中找到原文依据；季度审计检查治理规则是否偏离派生源。
 180  
 181  ## §7 主笔体系隔离 + 异源审查 N≤2（P4）
 182  
 183  - **主笔起草期间禁用清单**：主笔起草 M‑003 等元规则时，禁止使用 `.claude/skills/` 下任何 governance 类 skill（#016 自举循环破解），仅可使用工具 skill 与 standards/templates。与 M‑005 §G.5.4 及 §B.1 信号 5 双向引用。
 184  - **异源审查终止规则（N ≤ 2）**：主笔 draft（阶 0）→ 异源 sign‑off（阶 1）→ 异源对 sign‑off 逻辑复核（阶 2）。超过 N=2 强制中断转帅哥裁决。帅哥是唯一终止节点（Antigravity 建议采纳）。
 185  
 186  **判据**：#017 同源偏向实证；异源审查消除盲点但无限回归导致认知负荷。
 187  **可验伪信号**：若出现阶 3 评审链未转裁决则视为违规。
 188  
 189  ## §8 与下游 M‑001/M‑002/M‑004 接口
 190  
 191  - **M‑001**：skill 审计主笔提名继承 M‑005 §H 轮换原则；M‑003 定义审计周期与判据，M‑001 负责具体提名流程。
 192  - **M‑002**：skill 提案审议与分歧裁决归 M‑002；M‑003 仅执行初始合规过滤（§2 判定+§2.4 入库门槛）。
 193  - **M‑004**：可能承接 skill 触发日志操作格式与 CI hook 配置，M‑003 不定义 schema。
 194  - **不重复定义**：M‑005 §G.5 Verdict、季度审计间隔、baseline 机制等均为底层判据，M‑003 引用而非覆写。
 195  
 196  ## §附录 B 公/私 skill 分类（WebSearch 验证）
 197  
 198  ⚫ **公共**（Anthropic 运行时加载，~17 个，可查）：PDF、DOCX、XLSX、PPTX、Frontend Design 等。
 199  ⚪ **个人**（repo‑owned）：app-description-writer、decision-closeout、dod-checklist、phase-closeout、screenshot-planner、swift-concurrency-pro、swiftdata-pro、swiftui-pro、tdd-feature、verify-audit-report、xcode-review（11 active）等。
 200  🔄 **fork 公共**：当前无已知 fork；若出现须在 frontmatter 声明来源并归入个人治理。
 201  
 202  ## §9 自反性标注
 203  
 204  **起草工具**：直接 API 调用，zero‑context，未使用任何 `.claude/skills/` governance skill。**WebSearch 记录**（2026‑05‑25）：Claude Code hooks 27 事件/skill‑scoped hooks 确认；公共 skill 清单 ~17 个确认。详见 §4、§3 及附录 B。
 205  
 206  *本草案由 DeepSeek V4‑Pro 基于路径 C 全实证 + 4 条新原则（P1‑P4）与 WebSearch 验证起草。*


---

# 输入 3/5 — task definition v1（归档，对比 v2 差异）

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

# 输入 4/5 — M-003 v1 draft（前轮主笔产物，含 5 处已修复 BLOCK 参照）

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

# 输入 5/5 — 收尾指令

基于以上 4 份输入，独立完成 sign-off。仅输出 markdown，无任何 commentary。
