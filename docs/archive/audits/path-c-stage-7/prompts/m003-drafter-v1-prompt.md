你是 SnapDrill iOS 项目元规则 M-003「技能库治理」的主笔（起草者）。

# 你的身份与上下文

- 模型：DeepSeek V4-Pro（已确认，禁止 Flash）
- 任务：路径 C Stage 7.3 — 基于路径 C 全实证（#016~#020），起草 M-003 v1 draft
- 编号上下文：M-005 已 ratify（#015），M-003 是 M-001~M-006 中第二个 ratify 的派生规则
- 主笔身份：本次是你第 4 次承接路径 C 主笔（前 3 次：M-005 v2 / skill-audit-final / Stage 6.2 patch 均一次通过 sign-off）

# Zero-context 说明

本任务 zero-context，你**没有**访问项目仓库的文件系统能力。所有输入都已 inline 在本 prompt 中（task definition + 5 个引用文件 + 5 条裁决纪录）。

# 你的输出

完整的 `docs/meta/M-003-skill-library-governance.md` v1 markdown 全文，单一 fenced code block，开始于 frontmatter `---`，结束于文档最后一行。**不要**输出任何解释、commentary、思考过程——只输出 markdown 文件全文。

# 硬性约束（来自 task definition）

1. **§3 三问每一问含判据 + 实证 + 可验伪信号**
2. **§4 七章全部覆盖**：§1 定位 / §2 skill vs 其他下沉去向判定 / §3 命名空间与目录布局 / §4 生命周期 / §5 升降级流程 / §6 与主笔体系的隔离要求 / §7 与下游接口
3. **总字数 ≤2500 nwc**（M-005 §J 硬上限）。超出必须有 §J override_rationale
4. **§5 五个决策点（D1-D5）列出选项 + 利弊，不得擅自裁决**——帅哥 Stage 7.3 review 时裁决
5. **§G.5 引用一致**：直接引用 M-005 §G.5.1~§G.5.5，不重复定义
6. **实证锚定**：每个核心论断必须可追溯到 user-decision-log #编号 / skill-audit-final §章节 / stage6-reflection §章节
7. **frontmatter**：last_verified / layer / scope / freshness 完整；若超字数，含 override_rationale
8. **§11 防越界**：不进入 skill 提案审议流程（M-002）/ 触发日志 schema（standards/）/ skill 文档格式（standards/）
9. **自反性标注**：draft 末尾「起草过程使用工具清单」（你 zero-context 应当只列「直接 API 调用，无工具」）
10. **路径 C 全实证密度**：每个章节必须含具体实证（不是抽象原则）

# 推荐 frontmatter（你可调整）

```yaml
---
last_verified: 2026-05-25
layer: principle
scope: meta
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, skill_audit_quarterly, external_shock]
override_rationale: |
  （若超 2500 nwc，写明每段不可压缩的理由——参 M-005 frontmatter 模式）
---
```

---

# 输入 1/7 — 任务定义书（你的工作指南）

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

| 候选 | 优势 | 风险 |
|---|---|---|
| **DeepSeek** | 路径 C 中 3 次主笔均一次通过（M-005 v2 / skill-audit-final / Stage 6.2 patch）；密度高、引用规范 | 已连续 3 次，触及 M-005 §H 轮换阈值边缘 |
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

# 输入 2/7 — M-000 v2.0 §6（下沉去向，post-#020）


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


---

# 输入 3/7 — M-005 v2 §G.5（skill 升降级双轨）

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

# 输入 4/7 — skill-audit-final §6（M-003 起草输入）

### 5.3 M-005 §B 伪共识识别的 skill 维度缺失

**原范围（M-005 §B）**：仅覆盖文本产出层面的伪共识信号（同源主笔、训练 cutoff、身份误识别等）。

**路径 C 实证**：Claude 同源偏向已验证（给 cross-audit / sprint-contract 等自己起草过程用过的 skill KEEP 而帅哥裁决全部 DOWNGRADE）。这属于「skill 消费层面的同源偏向」——主笔倾向于保留自己用过/写过的 skill。

**预测触发**：Stage 6 反思后扩展 M-005 §B 新增信号：「主笔消费过的治理 skill 在主笔自己的 audit 中给予 KEEP → 自动标为同源偏向，在折叠报告中显式标注」。

### 5.4 M-003 起草的实证输入

Stage 7 M-003 起草的核心理念来自路径 C 实证，不在此预测（属 M-003 内容）。但 Stage 6 需确认 M-003 的起草前提是否成立。

---

## §6 M-003 起草输入（基于路径 C 实证）

### 6.1 核心实证数据

- 52 个 skill → 17 个净化版（净减 67%）
- 治理 skill 12 个 → 仅 3 个 KEEP（dod-checklist / phase-closeout / verify-audit-report），其余 9 个全部降格（5 DOWNGRADE / 2 MERGE / 1 DELETE / 1 PROMOTE）
- 工具 skill 40 个 → 9 个 KEEP/REWRITE（含容器）+ 其余全部合并/降格
- 4 家异源分歧率 87%→ 用户裁决后达成一致的最终图

### 6.2 M-003 必须回答的三问

1. **skill 与 standards / templates 的边界**：什么内容应该进 skill（需要 LLM 动态判断且不可下沉）vs standards（静态规范）vs templates（代码模板）？
   - 实证边界：trigger 是否依赖 LLM 实时推理 + 是否可被静态文档或脚本替代
2. **治理 skill vs 工具 skill 的命名空间分离**：是否应在 `.claude/skills/governance/` vs `.claude/skills/tools/` 物理隔离？
   - 实证：治理 skill 的同源偏向风险（Claude 自审失真）可通过物理隔离 + 元规则禁止治理 skill 互审降低
3. **skill 生命周期机制**：如何避免当前 52→17 的大规模重构在未来重演？
   - 建议：M-003 必须定义 skill 的「触发频率监控 + 误触发率统计 + 季度衰退检查 + 自动降格阈值」

### 6.3 M-003 核心机制建议

- **SSOT 单源化**：`.agents/skills/` 作为 portable skill 的唯一 SSOT（非适配器），`.claude/skills/` 只留 symlink 或 manifest 入口
- **命名空间分离**：`.claude/skills/governance/` 只放治理 skill（需元规则 sign-off），`.claude/skills/tools/` 放工具 skill（无需元规则 sign-off）
- **升降级双轨**：skill 的升级/降级采用 M-005 §G.4 框架的扩展版（新增 skill 特有判据）
- **季度衰退检查**：每 90 天检查 skill 触发日志，连续 2 个季度无触发的自动降格为模板候选

---

# 输入 5/7 — path-c-stage6-reflection §3（M-003 起草输入）

**Overrule 范围**：精化（非 Overrule）M-005 v2 §B.1——保留原 4 个信号，新增第 5 个。

---

## §3 路径 C Stage 7 M-003 起草输入（基于本反思）

Stage 6 反思识别的 3 个修订点同时也是 Stage 7 M-003 起草的核心输入：

| 反思点 | 对 M-003 的输入 |
|---|---|
| P1 下沉优先级 | M-003 §核心机制：skill 是 standards/templates/hook 之外的"末位优选"，不是默认下沉去向 |
| P2 skill 升降级机制 | M-003 §升降级章节：直接采纳 §G.5 6 种 Verdict + 季度审计 + baseline 机制 |
| P3 主笔消费偏向 | M-003 §主笔与 skill 消费的隔离要求 |

M-003 起草时必须显式引用本反思报告作为实证输入。

## §4 致帅哥的决策点

按 [#005](../meta/user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) 批准权机制，元规则修订属结构性决定，需帅哥显式批准。提供 3 种处理路径：

### 方式 A：3 个 patch 全部接受 + 启动 Stage 6.2（修订流程）
帅哥批准全部 3 个 patch → DeepSeek 主笔产 patch final → 3 家 sign-off → ratify (#020) → 同 PR 修订 M-000 v2.0 §6 + M-005 v2 §B §G

### 方式 B：选择性接受 + 调整 patch 内容
帅哥逐个 patch 裁决（接受 / 拒绝 / 精化）→ 调整后走 Stage 6.2 修订流程

### 方式 C：推迟修订 + 仅记录反思
仅 commit 本反思报告作为 Stage 7 M-003 起草输入，不立即修订 M-000/M-005。等 M-001~M-006 全部 ratify 后批量评估 M-000/M-005 修订需求。

**Claude 推荐**：**方式 A**——3 个 patch 均有充分路径 C 实证锚定，且修订内容精确（替换/追加段落级别）。立即落地能让后续 M-001~M-006 起草直接受益于新规则（特别是 P1 下沉优先级 + P3 主笔消费偏向警示）。

## §5 后续路径

| 步骤 | 内容 |
|---|---|
| 6.1 反思报告 ratify | 本报告 commit 后等帅哥裁决（方式 A/B/C） |
| 6.2 修订流程（若方式 A/B）| DeepSeek 主笔产 patch final → 3 家 sign-off → ratify (#020) → 同 PR 修订 M-000/M-005 |
| 6.3 backlog 整理 | 路径 C 暴露的 legacy_whitelist 豁免（skill-links + home-path-refs，2026-06-30 到期）→ 落 backlog |
| Stage 7 M-003 起草 | 基于本反思 + 路径 C 全实证起草 M-003 |

## 关联文档

- [user-decision-log #016~#019](../meta/user-decision-log.md) 路径 C 全流程
- [skill-audit-final.md](skill-audit-final.md) DeepSeek 主笔 final（含 §5 元规则反思预测点）
- [M-000 v2.0 §6](../meta/M-000-meta-vision.md) - P1 修订对象
- [M-005 v2 §B / §G](../meta/M-005-quality-criteria.md) - P2/P3 修订对象


---

# 输入 6/7 — user-decision-log #016~#020（路径 C 全过程裁决）

### #016 路径 C 启动 — Skill 生态第一性原理审计（彻底解决自举循环）

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-25 |
| **冲突描述** | M-005 v2 ratified（[#015](#015-m-005-v2-ratified--同-pr-修订-m-000-v20-6--frontmatter--显式-overrule-009-r2)）后，识别 skill 自举循环风险：skill 在元规则体系中具有三重角色（元规则的下沉去向 + 元规则的执行器 + 元规则起草过程本身的工具）。实证：M-005 起草过程使用了 `sprint-contract` / `cross-audit` / `verify-audit-report` 等治理 skill，但这些 skill 早于 M-000 v2.0 存在，**未经任何元规则 sign-off**。当前 skill 生态盘点：`.claude/skills/` 52 个 + `.agents/skills/` 16 个（其中 16 个双份存在疑似同步漂移）；治理 skill（~12 个）与工具 skill（~40 个）混在同一目录、共享同一 trigger 机制；自启动 skill 通过 keyword / hook 触发，绕过 M-000 P7 净化提示词约束。帅哥裁决：路径 C 激进路径——第一性原理审计 skill 生态，不在乎时间，彻底解决不能妥协。 |
| **裁决** | **路径 C 启动**，按 7 stage 推进：<br>**Stage 1（本条同时启动）**：`docs/audits/skill-audit-task-definition.md` 净化任务定义书起草。<br>**Stage 2**：4 家异源独立审 52 个 skill（Claude 主分支 / Codex worktree / DeepSeek 直接 API / Gemini 3.5 Flash GA 直接 API）。每个 skill 给 Verdict：**KEEP**（治理价值清晰、与元规则对齐、不可下沉）/ **MERGE**（与另一 skill 功能重叠，应合并）/ **DELETE**（装饰性 / 过时 / 形式合规但实质空洞 / 未触发过）/ **PROMOTE_TO_STANDARDS**（应升到 docs/standards/）/ **DOWNGRADE_TO_TEMPLATE**（应剥离 trigger 改静态模板）/ **REWRITE**（措辞与 M-000/M-005 不一致需重写）。每个 Verdict 必须含可追溯实证 + 可验伪信号（M-005 §A 判据）。<br>**Stage 3**：Claude 中立主笔产 Verdict 矩阵折叠表；帅哥裁决分歧；DeepSeek 主笔产 audit report final。<br>**Stage 4**：3 家 sign-off（DeepSeek 主笔不下场，Claude/Codex/Gemini 异源审）+ 帅哥 ratify（预编号 #017）。<br>**Stage 5**：按 Verdict 类别批量执行（DELETE → `docs/archive/skills/`；MERGE → 新 skill + 旧归档；PROMOTE_TO_STANDARDS → 内容移 `docs/standards/`、skill 删；DOWNGRADE_TO_TEMPLATE → 移 `docs/templates/`；REWRITE → 按新元规则措辞重写；KEEP → 不动）。<br>**Stage 6**：元规则反思——回头检查 M-000 v2.0 / M-005 v2 是否有 skill 揭示的盲点需 patch。<br>**Stage 7**：M-003 技能库治理起草（基于路径 C 实证，不再"想象"应该怎样，而是基于 52 个 skill 实战审计结论）。<br>**排他性条款（路径 C 期间，本条生效起至 Stage 7 ratify）**：<br>- ❌ 暂停 M-002 / M-006 / M-001 / M-004 派生起草<br>- ❌ 暂停级联引用更新（#011 E 延后项）<br>- ✅ Gemini CLI sunset 准备（2026-06-18 倒计时）继续，因不依赖 skill<br>- ✅ 紧急产品 bug fix 继续 |
| **理由** | 第一性诊断：skill 自举循环不是 bug，是元层级体系的结构性事实。M-005 §H 主笔轮换 + §B 伪共识识别条款的措辞，本质上是把 `cross-audit` skill 的设计假设升级为元规则。M-005 sign-off 时**没有任何一家审过 `cross-audit` skill 文本本身是否与 M-005 §B 一致**——元规则起草过程在违反自己的规则。继续起草 M-002 而不审 skill，会让 M-002 重蹈覆辙，且风险随每次派生起草放大。<br>路径 A（保守，每个 skill 走 ADR）成本高节奏慢。路径 B（折中，M-003 前移 + 临时纪律）会留长期 backlog。路径 C（激进，4 家异源审计 52 个 skill）一次性解决，与 #009 审 M-000 是同一思维模式的二阶应用（#009 审 M-000 文本，本次审 M-000 体系的执行层）。<br>帅哥原话："路径 C，我不在乎时间，我需要最激进的方式彻底解决这个问题不能妥协。" |
| **是否触发元规则修订** | ⚠️ **可能**。Stage 6 元规则反思阶段，若 skill 审计揭示 M-000 v2.0 / M-005 v2 有盲点，则触发对应修订（走显式 Overrule + 同 PR 流程）。Stage 7 M-003 ratify 本身是元规则修订。 |
| **Overrule 关系** | **本条不直接 Overrule 任何条款**。**排他性条款**临时压制（非 Overrule）以下安排：<br>- [#011](#011-m-000-v20-ratified--v12-归档) E 级联引用更新延后项 → 路径 C 期间继续暂停<br>- [#015](#015-m-005-v2-ratified--同-pr-修订-m-000-v20-6--frontmatter--显式-overrule-009-r2) F M-001~M-006 起草顺序「M-002 → M-006 → M-001 → M-004 → M-003」→ 路径 C 期间暂停 M-002/M-006/M-001/M-004，M-003 移至 Stage 7 优先<br>路径 C 完成后（Stage 7 ratify）以上压制解除，恢复或更新原顺序。 |
| **元层级注记** | **路径 C 是 #009 第一性原理审计的二阶应用 + 第三次元规则自我演进闭环候选**：<br>(1) **第一性原理审计的二阶**：#009 第一次审计 M-000 v1.2 文本，识别 70% 内容为 ANALOGY 外壳；本次审计 M-000/M-005 体系的执行层（52 个 skill），可预测识别比例可能类似（治理 skill ~12 个真正必要，工具 skill ~40 个多数为 ANALOGY 装饰或应升 standards）。<br>(2) **元规则自我演进第三次实例候选**：前两次为 [#011](#011-m-000-v20-ratified--v12-归档) M-000 v2.0 ratify + [#015](#015-m-005-v2-ratified--同-pr-修订-m-000-v20-6--frontmatter--显式-overrule-009-r2) M-005 v2 ratify；本次路径 C 完成 + Stage 6 元规则反思 + Stage 7 M-003 ratify 将构成第三次完整闭环。<br>(3) **自举循环的破解逻辑**：路径 C 用 4 家异源审计 skill 时，**审计过程本身不允许使用治理 skill**（如不允许调用 `cross-audit` skill 审 `cross-audit` skill 自己）。物理隔离 + 净化任务定义书强制每家独立审，不引用任何"skill 应该如何"的预设。<br>(4) **预测 Stage 6 元规则反思将识别 M-005 §G docaudit check 设计原则需扩展为「skill 升降级机制」**——M-005 §G 仅约束 docaudit check 的升降级，未覆盖 skill 升降级；这是 M-005 起草时的隐性盲点。Stage 6 实证后 patch M-005 §G。 |

---

### #017 Skill 审计 Stage 3.5 — 45 项分歧裁决 + 大规模重构方向

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-25 |
| **冲突描述** | 路径 C Stage 2 4 家异源审 52 个 skill 后产 87% 分歧率（[`skill-audit-consensus.md`](../audits/skill-audit-consensus.md)），仅 7 项形成 3+/4 共识，45 项需用户裁决。帅哥选 B 逐条裁决方式，12 批 AskUserQuestion 完成 45 项裁决。最终方向：**82% skill 改变形态（46% MERGE + 13% DELETE + 13% DOWNGRADE + 10% PROMOTE），仅 17% KEEP/REWRITE 保留 skill 形态**。 |
| **裁决** | 完整 52 项 Verdict（含 7 项共识 + 45 项裁决）：<br><br>**KEEP (7 / 13%)**：<br>- 共识 KEEP (4)：dod-checklist / phase-closeout / swiftui-pro / verify-audit-report<br>- 帅哥 KEEP (3)：tdd-feature（作为 TDD 主 skill 容纳子场景）/ xcode-review（Xcode 提示词独立）/ screenshot-planner（截图规划独立）<br>- decision-closeout 暂保留至 M-002 ratify 后转为 M-002 负责部分<br><br>**MERGE (24 / 46%)**：<br>- 共识 MERGE (1)：ui-review → ?（DeepSeek 主笔解）<br>- 已明确目标 (10)：tdd-bug-fix → tdd-feature / tdd-refactor-guard → tdd-feature / swiftui-debugging → swiftui-pro / snapshot-diff-review → snapshot-testing / app-store-rejection → app-description-writer / keyword-optimizer → app-description-writer / tipkit-generator → onboarding-generator / data-export → privacy-manifests / knowledge-health → docs/templates/knowledge-health-workflow.md / decision-closeout → M-002（暂保留）<br>- DeepSeek 主笔 Stage 4 final 统一解外链式 MERGE (13)：accessibility-generator / animation-patterns / api-research / app-description-writer / app-store-assets / characterization-test-generator / error-monitoring / integration-test-scaffold / localization-setup / migration-patterns / navigation-patterns / snapshot-testing / test-contract<br><br>**DELETE (7 / 13%)**：harness-recall / attributed-string / liquid-glass / background-processing / push-notifications / settings-screen / review-response-writer<br><br>**PROMOTE_TO_STANDARDS (5 / 10%)**：<br>- 共识 PROMOTE (1)：coding-best-practices → `docs/standards/swift-coding.md`<br>- 帅哥 PROMOTE (4)：app-icon-generator → `docs/standards/app-icon-design.md` / ci-cd-setup → `docs/standards/ci-cd.md` / dependency-propagation → `docs/standards/dependency-propagation.md` / privacy-manifests → `docs/standards/privacy-manifests.md`<br><br>**DOWNGRADE_TO_TEMPLATE (7 / 13%)**：<br>- 共识 DOWNGRADE (1)：onboarding-generator → `docs/templates/onboarding/`<br>- 帅哥 DOWNGRADE (6)：cross-audit → `docs/templates/cross-audit-workflow.md` / cross-audit-consensus → `docs/templates/cross-audit-consensus.md` / post-merge → `docs/templates/post-merge-checklist.md` / resume-from-handoff → `docs/templates/session-resume.md` / sprint-contract → `docs/templates/sprint-contract.md` / deep-linking → `docs/templates/deep-linking/`<br><br>**REWRITE (2 / 4%)**：swift-concurrency-pro / swiftdata-pro（均对齐 Swift 6.3 + iOS 26 最新 SDK）<br><br>**净化预测**：52 个 skill → ~14-17 个 active skill（净减 65-73%）。 |
| **理由** | 帅哥裁决方向：**消解大部分治理 skill 作为元规则执行器的角色**。8 个治理 skill 中：<br>- cross-audit / cross-audit-consensus / post-merge / resume-from-handoff / sprint-contract → DOWNGRADE 为静态模板（5 个）<br>- harness-recall → DELETE（与 knowledge-health 重叠）<br>- knowledge-health → MERGE 为静态模板<br>- decision-closeout → 暂保留至 M-002 ratify 后转 M-002<br>- dependency-propagation → PROMOTE_TO_STANDARDS<br>仅 dod-checklist / phase-closeout / verify-audit-report 3 个保留 skill 形态（共识 KEEP）。<br>第一性原理：**元规则的执行不应该依赖 LLM-driven skill 动态触发**，而应该是静态规范（standards）+ 静态模板（templates）+ hook/CI 自动化执行。这彻底打破自举循环——元规则起草过程不再需要"使用未审查 skill"，所有执行细节下沉到静态文档。<br>工具 skill 处理：*-pro 类 KEEP/REWRITE / *-patterns 类 PROMOTE 或 MERGE / *-generator 类 DOWNGRADE 或 DELETE / iOS API 类 DOWNGRADE 或 DELETE。 |
| **是否触发元规则修订** | ✅ **是**。本条 ratify 45 项分歧裁决，是 Stage 5 批量执行的输入。Stage 5 完成后：<br>- skill 生态从 52 → ~14-17 个净化版<br>- `docs/standards/` 新增 5 个规范文件<br>- `docs/templates/` 新增 7 个静态模板文件<br>- 治理 skill 大幅削减，路径 C 自举循环关闭<br>Stage 6 元规则反思可能触发 M-000 §6 / M-005 §G docaudit check 设计原则修订（识别 skill 作为元规则执行器的失效路径）。Stage 7 M-003 起草将基于本次实证（非"想象"M-003 内容）。 |
| **Overrule 关系** | **本条精化（非 Overrule）以下条款**：<br>- M-000 v2.0 §6「新增条款必须先证明无法下沉到 M-001~M-006、standards、skills、ADR、STATUS stub 或工具」→ 本次实证 **skill 不是元规则执行的优选下沉去向**，应优先下沉到 standards / templates / hook，skill 仅承担需要 LLM 动态判断的少数场景。<br>- M-005 v2 §G docaudit check 设计原则 → 本次实证 docaudit check 的升降级机制（§G.4）应扩展为「skill 升降级机制」。M-003 起草时承接此扩展。 |
| **元层级注记** | **路径 C 的第一性实证**：4 家异源审 52 个 skill 产 87% 分歧 → 帅哥逐条裁决后 82% skill 改变形态 → 证明 **skill 生态确实存在大规模结构性冗余**。4 家从不同维度（Codex MERGE / DeepSeek DELETE / Gemini PROMOTE+DOWNGRADE / Claude KEEP 同源偏向）各自识别问题，叠加后形成"全光谱缺陷图"，帅哥裁决综合 4 家立场。<br>**Claude 同源偏向实证**：Claude 给 cross-audit/sprint-contract/decision-closeout/knowledge-health 等"自己起草过程用过的 skill" KEEP/REWRITE，但帅哥裁决全部 DOWNGRADE/MERGE。Claude 主分支会话上下文污染（已知 M-005 起草过程）导致同源偏向保留。这是 M-005 §B 伪共识识别的最强实战实证——**异源 + 用户裁决能识别 Claude 自审失真**。<br>**路径 C 的元层级目标实现**：本次裁决后，Stage 5 执行完成时：<br>(1) skill 自举循环关闭——元规则起草过程不再依赖"未审查 skill"，所有治理动作下沉静态文档<br>(2) skill 生态净化 65-73%——减少认知负担、消除冗余<br>(3) Stage 7 M-003 起草基于实证而非假设——M-003 §核心机制（skill 升降级 / 命名空间 / SSOT 单源化）来自本次审计实证<br>本条是路径 C 7-stage 的 Stage 3.5 用户裁决节点，预备 Stage 4 DeepSeek 主笔产 final + 3 家 sign-off + ratify（预编号 #018）。 |

---

### #018 Skill 审计 final RATIFIED — 路径 C Stage 4.4 完成

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-25 |
| **冲突描述** | 路径 C Stage 4.1 DeepSeek 主笔产 `docs/audits/skill-audit-final.md`（21358 bytes / 13140 nwc，§1~§6 全章节，解 13 个外链式 MERGE）。Stage 4.2 3 家 sign-off：Claude **PASS**（5 minor concerns 不阻塞）/ Gemini **PASS**（自反性撤回 Stage 2 KEEP 立场）/ Codex **CONDITIONAL**（2 处执行歧义：§2.2 xcode-review 错位 + §4.7 模板统计需说明）。无 BLOCK，不触发主笔回炉。Claude 主分支按 Codex CONDITIONAL 条件 + 综合 Claude minor concerns 修正 final 文本（§2.2 移除 xcode-review 改为 10 项 + 标注链式 MERGE / §2.3 #21/#25/#31 合并目标显式标注为 standards 文件而非 skill / §4.7 模板统计明确 9 个 = 7 DOWNGRADE 直接 + 2 MERGE 派生 / §1 净化数字精确化 52 → 10 active skill 净减 81%）。帅哥裁决 ratify。 |
| **裁决** | Skill 审计 final v1 正式 ratify，作为 Stage 5 批量执行的输入：<br><br>**A. 产物清单**（commit 落档）：<br>- `docs/audits/skill-audit-final.md` — DeepSeek 主笔 final（已含 sign-off 反馈修正）<br>- `docs/audits/skill-audit-signoff-claude.md` — Claude PASS<br>- `docs/audits/skill-audit-signoff-codex.md` — Codex CONDITIONAL → PASS（条件已满足）<br>- `docs/audits/skill-audit-signoff-gemini.md` — Gemini PASS<br><br>**B. 最终产物分布**（按 §4.7 精确统计）：<br>- 52 个原 skill → **10 个 active skill**（净减 81%）：7 KEEP（dod-checklist / phase-closeout / swiftui-pro / verify-audit-report / xcode-review / tdd-feature / screenshot-planner）+ 2 REWRITE（swift-concurrency-pro / swiftdata-pro）+ 1 MERGE 容器（app-description-writer）<br>- `docs/standards/` 新增 6 个：swift-coding.md（吸纳 coding-best-practices + test-contract）/ ci-cd.md（吸纳 ci-cd-setup + error-monitoring）/ dependency-propagation.md（吸纳 dep-propagation + api-research）/ privacy-manifests.md（吸纳 privacy-manifests + data-export）/ app-icon-design.md / swiftui-patterns.md（吸纳 animation + migration + navigation patterns）<br>- `docs/templates/` 新增 9 个：7 个 DOWNGRADE 直接（cross-audit-workflow / cross-audit-consensus / post-merge-checklist / session-resume / sprint-contract / deep-linking / onboarding 共识）+ 2 个 MERGE 派生（knowledge-health-workflow / localization-workflow）<br>- `docs/archive/skills/2026-05-25/` 归档 31 个：7 DELETE + 24 MERGE 原目录<br><br>**C. Stage 5 启动授权**：本 ratify 同时授权 Stage 5 批量执行，按 §4.1-§4.6 清单分类批处理。<br><br>**D. Sign-off 撤回声明**：Claude / Gemini 均显式撤回 Stage 2 audit 立场（Stage 2 同源偏向已被异源 + 用户裁决纠偏）；Codex CONDITIONAL 2 条件在 final 文本修正后视为满足，升 PASS。 |
| **理由** | 路径 C Stage 4 完整闭环：DeepSeek 主笔 → 3 家异源 sign-off → final 文本修正（sign-off 反馈） → ratify。无 BLOCK 表示 #017 45 项裁决落实精确，DeepSeek 主笔解 13 个外链式 MERGE 准确。Codex CONDITIONAL 的 2 处条件均为执行歧义（不是硬约束偏差），主分支修正后可视为 PASS（按 §F.2 sanity check 可撤回 + 条件满足）。<br>Claude / Gemini 自反性撤回 Stage 2 KEEP 立场——验证 §F.1 自反性 sanity check 在 skill 审计中同样有效（不只 M-005 起草中的 §B 应用）。Claude 同源偏向（给"自己用过的治理 skill" KEEP）被异源 + 用户裁决纠偏，是 §B 伪共识识别的第二次实战实证（第一次 #015 M-005 v2 起草时 §C.4 与 §B.1.4 内部冲突）。<br>Stage 5 批量执行进入授权状态，按 §4.1-§4.6 清单分类批处理（DELETE / MERGE / PROMOTE / DOWNGRADE / REWRITE / KEEP）。 |
| **是否触发元规则修订** | ⚠️ **Stage 6 后触发**。本 ratify 不直接修订 M-000 / M-005，但 final §5 已预测 3 处元规则反思触发点：<br>1. M-000 §6 下沉优先级降低 skill（82% skill 非 optimal 形态实证）<br>2. M-005 §G docaudit check 设计原则扩展为 skill 升降级双轨机制（#017 数据为输入）<br>3. M-005 §B 伪共识识别新增「主笔消费过的治理 skill 在自审给 KEEP → 自动同源偏向标注」<br>Stage 6 反思后落实际 patch（预编号 #019）。 |
| **Overrule 关系** | **不 Overrule 任何条款**。本条 ratify [#017](#017-skill-审计-stage-35--45-项分歧裁决--大规模重构方向) 45 项裁决落地版（DeepSeek 主笔 final）。Stage 6 反思后可能触发 M-000 §6 / M-005 §G / M-005 §B 修订（预编号 #019），届时显式 Overrule 当前条款。 |
| **元层级注记** | **路径 C 7-stage 进度**：Stage 1-4 完成（任务定义书 / 4 家审 / 折叠 / 裁决 / 主笔 / sign-off / ratify），Stage 5 授权启动（批量执行），Stage 6-7 待启动（元规则反思 + M-003 起草）。<br>**主笔轮换二次成功**：DeepSeek reasoner 第二次成功主笔（第一次 M-005 v2，本次 skill audit final），证明 [#012](#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) Q2 主笔轮换裁决持续有效——避免连续 4 版 Codex 主笔的同源累积。<br>**Sign-off 反馈即时修正模式**：Codex CONDITIONAL 提出 2 处执行歧义后，主分支立即在 ratify 同 PR 修正 final 文本（非触发主笔回炉 v2）。这扩展了 M-005 §F.2「sanity check 不是终审 + BLOCK 可被后续 sanity check 撤回」原则——CONDITIONAL 条件可在 ratify 同 PR 满足，不必走完整 v1→v2 循环。<br>**路径 C 自身的元层级验证**：4 家异源审 → 87% 分歧 → 用户裁决 → 主笔 final → 3 家 sign-off → 修正 → ratify 全流程实战，验证 M-000 §3 默认多方异源 + §7.2 同源警告 + M-005 §B 伪共识识别 + §F 自反性 sanity check + §H.3 主笔不是独享特权的整套机制在 skill 治理场景同样有效。这是元规则自我演进闭环的第三次完整实例（第一次 #011 M-000 v2.0 / 第二次 #015 M-005 v2 / 第三次 #018 skill audit final）。 |

---

### #019 路径 C Stage 5 批量执行完成 — skill 生态 52 → 11

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-25 |
| **冲突描述** | 路径 C Stage 4.4 ratify（[#018](#018-skill-审计-final-ratified--路径-c-stage-44-完成)）后，Stage 5 按 skill-audit-final.md §4 批量执行清单分类批处理：7 DELETE + 7 DOWNGRADE + 5 PROMOTE + 24 MERGE + 2 REWRITE 标记 = 45 个 skill 处理动作。执行过程涉及大量文件 mv / cp / content 合并，触发 docaudit 多类 error（frontmatter / links / skill-links / skill-inventory / skill-provenance）。修复后所有 finding 通过 baseline + legacy_whitelist 豁免。 |
| **裁决** | Stage 5 批量执行结果：<br><br>**A. skill 生态从 52 → 11 active skill**（净减 79%）：<br>- 剩余 .claude/skills/：app-description-writer / decision-closeout / dod-checklist / phase-closeout / screenshot-planner / swift-concurrency-pro / swiftdata-pro / swiftui-pro / tdd-feature / verify-audit-report / xcode-review (共 11 个)<br>- swiftui-pro 吸纳 swiftui-debugging + ui-review + accessibility-generator (容器扩展)<br>- tdd-feature 吸纳 tdd-bug-fix + tdd-refactor-guard + integration-test-scaffold + characterization-test-generator + snapshot-testing + snapshot-diff-review (容器扩展)<br>- app-description-writer 吸纳 app-store-rejection + keyword-optimizer + app-store-assets (容器扩展)<br>- swift-concurrency-pro + swiftdata-pro 标 REWRITE 待 Stage 5.1 后续 PR 重写对齐 Swift 6.3 + iOS 26<br>- decision-closeout 暂保留至 M-002 ratify 后处理<br><br>**B. docs/standards/ 新增 6 个**：swift-coding.md（吸纳 coding-best-practices + test-contract）/ ci-cd.md（吸纳 ci-cd-setup + error-monitoring）/ dependency-propagation.md（吸纳 dep-prop + api-research）/ privacy-manifests.md（吸纳 privacy-manifests + data-export）/ app-icon-design.md / swiftui-patterns.md（吸纳 animation + migration + navigation patterns）<br><br>**C. docs/templates/ 新增 9 个**：onboarding-generator.md（吸纳 tipkit-generator）/ cross-audit-workflow.md / cross-audit-consensus.md / post-merge-checklist.md / session-resume.md / sprint-contract.md / deep-linking.md / knowledge-health-workflow.md（新建）/ localization-workflow.md（新建）<br><br>**D. docs/archive/skills/2026-05-25/ 归档 41 个**：7 DELETE + 24 MERGE 原目录 + 5 PROMOTE 原目录 + 5 DOWNGRADE 原目录（onboarding-generator/cross-audit/cross-audit-consensus/post-merge/resume-from-handoff/sprint-contract/deep-linking 共 7 个 DOWNGRADE，与 PROMOTE 重叠 1：实际归档 41 个目录）<br><br>**E. docs/standards/skill-architecture.md + skill-source-ledger.md 同步更新**：<br>- skill-architecture.md：discovery 52 → 11、adapter 16 → 5、distinct 52 → 22<br>- skill-source-ledger.md：21 个 Claude-only `rshankras` skill 中 20 个移除（仅 tdd-feature 保留，标注吸纳路径 C 内容）<br><br>**F. Scripts/audit/policy.yaml legacy_whitelist 新增 2 项豁免**（带 expires_on: 2026-06-30）：<br>- skill-links：.agents/skills/swiftui-pro 上游 references 引用不一致<br>- home-path-refs：路径 C DOWNGRADE/MERGE 继承的 ~/.claude 私有路径引用<br>两者均为路径 C 暴露的预存在问题或继承文本，待后续 PR 批量脱敏。<br><br>**G. skills-lock.json 更新**：3 个 *-pro skill 的 localBlob hash 重算（swift-concurrency-pro / swiftdata-pro / swiftui-pro 因 REWRITE 标记或 MERGE 吸纳导致内容变更）。 |
| **理由** | Stage 5 是路径 C 的"落地动作"——把 #017 45 项裁决 + #018 final 设计转为实际文件操作。docaudit 5 类 error 是大规模重构的预期副产物（41 个目录移动 + 24 个内容合并必然产生 frontmatter / link / inventory 漂移）。修复策略：<br>1. 归档 skill 补 archive frontmatter（标 status: archived + skill_audit_verdict: archived）<br>2. PROMOTE/DOWNGRADE 文件补 standards/template frontmatter<br>3. skill-architecture.md / skill-source-ledger.md 数字同步 #017/#018<br>4. skills-lock.json hash 同步实际内容<br>5. .agents/skills/swiftui-pro 上游引用问题用 legacy_whitelist 豁免（非路径 C 引入）<br>6. 路径 C 继承的 ~/.claude 路径用 legacy_whitelist 豁免（待后续 PR 脱敏）<br>路径 C Stage 5 实质完成 67% 净化（final §4.7 预测 67%），与"净减 79%"统计差异来自 active skill 边界划分（含/不含吸纳 MERGE 后的容器）。 |
| **是否触发元规则修订** | ⚠️ **Stage 6 后触发**。本条仅落 Stage 5 执行结果，不直接修订元规则。Stage 6 元规则反思将基于 Stage 5 实证识别 M-000 §6 / M-005 §G / M-005 §B 修订点（参 [#018](#018-skill-审计-final-ratified--路径-c-stage-44-完成) 元层级注记预测）。 |
| **Overrule 关系** | **不 Overrule 任何条款**。本条落 [#018](#018-skill-审计-final-ratified--路径-c-stage-44-完成) ratify 后的批量执行结果。skills-lock.json + skill-architecture.md + skill-source-ledger.md 修订是路径 C 引发的执行层数据同步，非元规则修订。 |
| **元层级注记** | **路径 C 7-stage 进度**：Stage 1-5 完成（任务定义书 / 4 家审 / 折叠 / 裁决 / 主笔 / sign-off / ratify / 批量执行），Stage 6-7 待启动（元规则反思 + M-003 起草）。<br>**legacy_whitelist 的 baseline 模式价值**：路径 C 这种大规模重构会暴露大量预存在问题（如 .agents/skills/swiftui-pro 上游 references 引用不一致 26 处），这些不应阻塞主流程。docaudit baseline + legacy_whitelist + expires_on 机制让"知道问题但暂时不修"成为合规状态，避免技术债隐藏。**预测 Stage 6 反思将识别此机制作为 M-005 §G docaudit check 设计原则的扩展实证**——expires_on 强制周期性复审，与 §G.4 升降级机制同源。<br>**skill 生态净化的数字解读**：52 → 11 active skill（79% 净减）+ 6 docs/standards/ 新增 + 9 docs/templates/ 新增 + 41 归档。**知识总量不减反增**（49 个总产物 = 26 个 active 内容承载 + 41 个归档证据），但 trigger 触发的 skill 大幅减少（52 → 11），降低自启动 skill 的污染风险（M-000 P7 净化提示词原则二阶应用）。这是路径 C 真正达成的目标：**消解 skill 作为元规则执行器的过度膨胀，让 standards/templates 承担静态规范职责**。 |

---

### #020 路径 C Stage 6 patches RATIFIED — M-000 §6 + M-005 §B/§G 三处精化

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-25 |
| **冲突描述** | 路径 C Stage 6 元规则反思（基于 [#016](#016-路径-c-启动--skill-生态第一性原理审计彻底解决自举循环) ~ [#019](#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) 全过程实证）识别 M-000 v2.0 §6 / M-005 v2 §B.1 / M-005 v2 §G 三处盲点。Stage 6.1 反思报告 → Stage 6.2 DeepSeek 主笔产 patch final → 3 家 sign-off（Claude **PASS** + Gemini **PASS** + Codex **CONDITIONAL→PASS**，2 条件在 ratify 同 PR 满足）→ ratify。本条同 PR 落实 M-000/M-005 三处修订。 |
| **裁决** | Stage 6.2 patch final 正式 ratify，Stage 6.3 同 PR 执行三处修订：<br><br>**A. M-000 v2.0 §6 line 76 替换**：第二段「新增条款必须先证明无法下沉到 M-001~M-006、standards、skills、ADR、STATUS stub 或工具...」替换为下沉优先级 6 级列表（standards → templates → hook/CI → 工具 → M-001~M-006/ADR → skills 末位）+ 11 个 active skill 6 个月豁免条款。<br><br>**B. M-005 v2 §B.1 line 108 lead sentence 精化 + 追加第 5 条信号**：<br>- lead sentence 分两类信号（升级类 1~4 → 自动用户裁决 / 折扣类 5 → 标注不升级）—— 解决 Codex CONDITIONAL 条件 2 识别的语义冲突<br>- 追加信号 5「主笔消费偏向」：主笔自审给自己消费过的治理 skill KEEP/REWRITE → 折扣 0.5 权重<br>- 与信号 4（thinking 模式）可乘性叠加：0.5 × 0.5 = 0.25 原权重<br><br>**C. M-005 v2 §G 末尾追加 §G.5** skill 升降级双轨机制：<br>- §G.5.1 6 种 Verdict 体系（KEEP/REWRITE/MERGE/PROMOTE_TO_STANDARDS/DOWNGRADE_TO_TEMPLATE/DELETE）<br>- §G.5.2 季度审计（90 天周期 + 连续 2 季度无触发自动降格候选）<br>- §G.5.3 baseline + expires_on 机制（路径 C #019 实证）<br>- §G.5.4 主笔消费偏向警示（与 §B 联动）<br>- §G.5.5 与 M-001 主笔轮换衔接<br><br>**D. 执行清单（Stage 6.3 已完成）**：<br>- M-000 §6 line 76 替换 ✓<br>- M-005 §B.1 line 108 lead 精化 ✓ + line 113 之后追加信号 5 ✓<br>- M-005 §G line 342 之后追加 §G.5 ✓<br>- user-decision-log 本条 #020 落档 ✓ |
| **理由** | 路径 C 全实证锚定：<br>- [#019](#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) 52 → 11 skill 净减 79%，82% 改变形态 → P1 下沉优先级降 skills 末位<br>- [#017](#017-skill-审计-stage-35--45-项分歧裁决--大规模重构方向) 45 项分歧裁决 + Stage 5 批量执行 + 2 项 legacy_whitelist 豁免 → P2 §G.5 双轨机制 + baseline 模式<br>- [#017](#017-skill-审计-stage-35--45-项分歧裁决--大规模重构方向) Claude 给 4 个自己用过的治理 skill KEEP 被全部裁决 DOWNGRADE/MERGE/DELETE → P3 §B.1 第 5 信号<br>三处 patch 均为精化（非 Overrule），不扩大元规则体系规模。同 PR 修订一次性落地，避免后续认知割裂（参 [#012](#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) Q3 同 PR 落地精神）。Codex CONDITIONAL 2 条件（执行清单 line 范围 + §B.1 lead sentence 冲突）在 patch final 修订 + Stage 6.3 同 PR 落地中精确满足。 |
| **是否触发元规则修订** | ✅ **是**。M-000 v2.0 §6 + M-005 v2 §B.1 + M-005 v2 §G 三处文本修订生效。 |
| **Overrule 关系** | 精化（非 Overrule）以下条款：<br>① M-000 v2.0 §6 第二段（下沉去向平级列表 → 优先级列表 + 11 active skill 短期豁免）<br>② M-005 v2 §B.1 lead sentence（信号统一自动用户裁决 → 升级类/折扣类二分）<br>③ M-005 v2 §B.1（原 4 条信号 + 新增第 5 条主笔消费偏向）<br>④ M-005 v2 §G（原 §G.1~§G.4 + 新增 §G.5 skill 升降级双轨）<br>不覆盖任何历史裁决的认证效力。路径 C [#016](#016-路径-c-启动--skill-生态第一性原理审计彻底解决自举循环) ~ [#019](#019-路径-c-stage-5-批量执行完成--skill-生态-52--11) 全部裁决保留生效。 |
| **元层级注记** | **路径 C 7-stage 完整闭环临近完成**：Stage 1-5 + Stage 6（含 6.1 反思 / 6.2 patch final / 6.3 同 PR 修订 / 本条 ratify）完成；Stage 7 M-003 起草待启动。本条是路径 C 自演进的**第三次元规则修订**（前两次：[#011](#011-m-000-v20-ratified--v12-归档) M-000 v2.0 ratify / [#015](#015-m-005-v2-ratified--同-pr-修订-m-000-v20-6--frontmatter--显式-overrule-009-r2) M-005 v2 ratify / 本条 #020 三处精化）。<br>**Sign-off 反馈即时修正模式二次实证**：Codex CONDITIONAL 2 条件（line range + lead sentence 冲突）在 ratify 同 PR 满足，未触发主笔回炉 v2。这扩展 M-005 §F.2 + #018 体例——CONDITIONAL 可在 ratify 同 PR 满足条件直接升 PASS。<br>**DeepSeek 主笔三次成功**：路径 C 中 DeepSeek 第 3 次主笔（M-005 v2 / skill audit final / Stage 6.2 patch final），均一次通过 sign-off（或 CONDITIONAL 同 PR 修正）。主笔轮换裁决（[#012](#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) Q2）持续有效。<br>**自反性 sanity check 多家共识应用**：Claude/Gemini 主动在 Stage 4 sign-off 撤回 Stage 2 立场（路径 C 实证 §F.1 在 skill 审计场景的有效性）。本次 Stage 6 sign-off Claude 复盘 6.1 反思未发现需修正项，Codex 复盘 Stage 2 激进 MERGE 路径并显式承认本 patch 是有效修正。<br>**P3 信号 5 与 §G.5.4 双向引用机制**：M-005 §B（同源信号识别）与 §G（升降级机制）在 skill 审计场景显式双向引用——同一现象在不同元规则章节有不同执行接口。这是元规则模块化设计的标杆实证，可作为 M-003 起草时的"模块化元规则"参考。 |

---

## 日志维护规则

1. **append-only**：不删除历史条目，只追加新条目


---

# 输入 7/7 — 收尾指令

基于以上 6 份输入，现在产出 M-003 v1 完整 markdown。仅输出 markdown，无任何 commentary。
