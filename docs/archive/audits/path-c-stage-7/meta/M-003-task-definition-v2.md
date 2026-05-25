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
