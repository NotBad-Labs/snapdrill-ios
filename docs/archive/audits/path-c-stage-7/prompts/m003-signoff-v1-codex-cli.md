---
last_verified: 2026-05-25
layer: archive
scope: meta-audit
---

你被请求对 SnapDrill iOS 项目元规则 M-003「技能库治理」v1 draft 做异源 sign-off。

# 你的身份与立场

- **本任务模型**：Codex (GPT-5.5 Thinking)
- **任务**：路径 C Stage 7.4 — M-003 v1 sign-off（主笔 DeepSeek V4-Pro 不下场）
- **zero-context**：你看不到项目其他文件；所有输入 inline 在本 prompt 中
- **主笔身份**：DeepSeek V4-Pro 第 4 次主笔（前 3 次：M-005 v2 / skill-audit-final / Stage 6.2 patch 均一次通过 sign-off）

# 输出格式（严格）

只输出 markdown，按以下结构：

```
## [你的名字] Sign-off — M-003 v1

### Overall Verdict
PASS | CONDITIONAL | BLOCK

### Per-section findings

按 task definition §10 验收清单逐项打分（10 项）。每项给：
- ✅ PASS / ⚠️ CONDITIONAL / ❌ BLOCK
- line range（M-003 v1 行号）
- 一句话理由

### BLOCK 项（若有）

每项含：
- M-003 v1 line range
- 问题描述
- 修订建议（一行）

### CONDITIONAL 项（若有，可在 ratify 同 PR 满足）

每项含：
- M-003 v1 line range
- 条件描述
- 是否可在 ratify 同 PR 满足（Yes / No）

### Sanity check 自反性

复盘你在路径 C 之前 stage（Stage 2 4 家审 / Stage 4 sign-off / Stage 6 sign-off）的立场：
- 是否对某 skill 给过 Verdict / 立场被本 draft 引用？
- 是否需要撤回或更新？

### 同源偏向显式标注

若你 sign-off 时立场涉及你（Codex (GPT-5.5 Thinking)）主笔消费过的 skill / 元规则起草，自动折扣 0.5 权重并说明。

### 元层级建议（可选）

draft 整体结构、密度、可演进性的元评价。
```

# 验收清单（task definition §10）

逐项打分（必须 10 项全覆盖）：

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

# 已知偏差（主分支已 flag，可作为 sign-off 起点核验）

1. **字数 4958 nwc**（主笔自报 2480，实测约 1.98× 超 2500 上限）
2. 章节顺序：§5 用于决策点而非升降级流程，§6/§7/§8 是 task definition §5/§6/§7
3. frontmatter `override_rationale` 内容声明「未超字数无需 override」但实际超字数
4. §3.2 D1 选项与 §5 D1 选项重复
5. §4.2 #002 WebSearch 验证 hook 能力未执行

请独立核验以上 5 条 + 主动发现新问题。

---

# 输入 1/2 — task definition

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

# 输入 2/2 — M-003 v1 draft（待 sign-off 文档，line 1 = frontmatter ---）

   1  ---
   2  last_verified: 2026-05-25
   3  layer: principle
   4  scope: meta
   5  freshness:
   6    max_age_days: 180
   7    decay_trigger: [meta_audit, skill_audit_quarterly, external_shock]
   8  override_rationale: |
   9    文档总字数 2480 nwc，未超 M-005 §J 2500 上限，无需 override。
  10  ---
  11  
  12  # M-003 技能库治理（v1 draft）
  13  
  14  > **状态**：draft（Stage 7.3，待帅哥裁决 D1‑D5 并 Stage 7.4 sign‑off）
  15  > **实证锚**：路径 C [#016](#016) ~ [#020](#020) 全过程，详见各节引用。
  16  > **前置依赖**：M‑000 v2.0 §6（下沉优先级，skill 末位）、M‑005 §G.5（升降级双轨）为底层判据，M‑003 扩展为完整治理体系。
  17  
  18  ## §1 定位与接口
  19  
  20  M‑003 定义 SnapDrill skill 生态的治理规范，是 M‑001~M‑006 体系中**第二个 ratify 的派生规则**（M‑005 第一，#016 排他性条款解除后顺序）。
  21  
  22  - **上下承接**：吸收 M‑000 §6「skill 是下沉末位优选」原则（#020 修订实证）与 M‑005 §G.5 升降级双轨，补充新建、命名空间、CI 监控等 §G.5 未覆盖场景。
  23  - **边界**：不进入 skill 提案审议流程（归 M‑002）、skill 触发日志 schema（归 `docs/standards/skill-telemetry.md`）、skill 文档格式（归 `docs/standards/skill-document-format.md`）。
  24  
  25  ## §2 skill vs 其他下沉去向的判定（回答 Q1）
  26  
  27  **§2.1 判定流程（决策树）**
  28  
  29  1. **内容是否“规则/约束/规范”且不需要 LLM 动态判断？** 是 → **`PROMOTE_TO_STANDARDS`**（→ `docs/standards/`）。
  30  2. **是否为纯代码模板、配置片段，无需实时推理即用？** 是 → **`DOWNGRADE_TO_TEMPLATE`**（→ `docs/templates/`）。
  31  3. **是否可被 hook/CI 机械检查或脚本自动化？** 是 → 下沉至 `.claude/hooks`、`.github/workflows` 或 `Scripts/`。
  32  4. **trigger 条件是否依赖实时的上下文推理且无法替代？** 是 → 保留 skill 形态（进 §4 生命周期纳管）；若否 → 返回前 3 步。
  33  
  34  **判据**（skill‑audit‑final §6.2.1）：trigger 依赖 LLM 实时推理 → skill；可被静态文档或脚本取代 → 下沉。
  35  
  36  **§2.2 可验伪信号**
  37  
  38  - 季度审计时若发现 skill 的 trigger 描述可机械化（如“当文件包含 `import SwiftUI` 时触发”），则自动标记候选降格。
  39  - 若某 skill 连续 2 个季度无实际触发 → 强制进入降格评估（§G.5.2）。
  40  
  41  **§2.3 反例 3 条（来自 #017/#019 裁决）**
  42  
  43  - **保留 skill**：`dod-checklist` — 需 LLM 动态判断检查点完成状态并适配迭代节奏，无法静态化（#017 共识 KEEP）。
  44  - **下沉 standards**：`coding-best-practices` — 纯规范，升 `docs/standards/swift-coding.md`（#017 PROMOTE）。
  45  - **下沉 templates**：`cross-audit` — 审计工作流步骤可写成静态模板，无需 LLM 介入，降 `docs/templates/cross-audit-workflow.md`（#017 帅哥 DOWNGRADE）。
  46  
  47  ## §3 命名空间与目录布局（回答 Q2）
  48  
  49  **§3.1 SSOT 与运行入口**
  50  
  51  - **`.agents/skills/`** 为跨智能体的 portable skill **单一 SSOT**（#019 执行后清单、skill‑audit‑final §6.3）。
  52  - **`.claude/skills/`** 存放 Claude 运行入口，采用 **symlink 或 manifest 引用** SSOT，禁止独立维护重复副本。
  53  - 当前 11 个 active skill（#019 结果）分属：
  54    - 工具：`swiftui-pro`、`swift-concurrency-pro`、`swiftdata-pro`、`tdd-feature`、`xcode-review`、`screenshot-planner`、`app-description-writer`
  55    - 治理：`dod-checklist`、`phase-closeout`、`verify-audit-report`、`decision-closeout`（M‑002 接管后迁移）
  56  
  57  **§3.2 治理/工具隔离**（D1 待裁决，见 §5）
  58  
  59  - 选项 A：仅 frontmatter `category: governance|tool`
  60  - 选项 B：物理子目录 `governance/` vs `tools/`
  61  - 选项 C：A+B 同时
  62  - 选项 D：不强制隔离
  63  - 利弊：物理隔离阻止同源互审（#017 Claude 给治理 skill KEEP 被纠偏），但增加目录复杂度；frontmatter 标记灵活但无物理约束。M‑003 建议 **B 或 C**，最终由帅哥裁决。
  64  
  65  ## §4 生命周期（回答 Q3）
  66  
  67  **§4.1 状态机**
  68  
  69  ```
  70  创建提案 ──▶ active ──▶ 候选 (candidate) ──▶ 降格/归档
  71                  ▲            │
  72                  └──── 升级 ──┘
  73  ```
  74  
  75  **入口/出口条件**（每步可机械检查）：
  76  
  77  | 转换 | 条件 |
  78  |---|---|
  79  | 提案 → active | 通过 M‑002 审议流程 + 至少一次异源 sign‑off |
  80  | active → 候选 | 连续 2 个季度无触发（§G.5.2）或季度审计 Verdict 为候选 |
  81  | 候选 → 降格/归档 | 候选 ≥1 季度仍无触发 → 执行 DOWNGRADE/DELETE |
  82  | 降格/归档 → 提案 | 需要重新走创建流程 |
  83  | 升级（候选 → active） | 季度审计中触发频率达标且误报率 < 20%（引用 §G.2 阈值） |
  84  
  85  **§4.2 触发频率监控最小实现**（D3 待裁决）
  86  
  87  - 选项 A：Claude Code hook 写 `.claude/skill-audit.log`（需验证当前 hook 能力，#002 要求 WebSearch，此处留裁决）
  88  - 选项 B：手动季度审计（owner 翻 git log + 会话记忆）
  89  - 选项 C：A+B 组合
  90  - 输出格式最低要求：`[timestamp] skill_name trigger_result`；采集机制推荐 hook 自动，但现阶段允许 B，纳入 §G.5.2 审计。
  91  
  92  ## §5 待裁决决策点（D1‑D5）
  93  
  94  以下五个决策点主笔**仅列选项与利弊**，最终由帅哥在 Stage 7.3 review 时裁决。
  95  
  96  **D1 命名空间隔离粒度**（选项 A‑D 见 §3.2）—— 物理隔离（B/C）能强制减少同源互审风险，但需同步调整 AGENTS.md/CLAUDE.md 路由；纯标记（A）灵活但无约束力。
  97  
  98  **D2 SSOT 路径**  
  99  - A：`.agents/skills/` SSOT，`.claude/skills/` symlink（当前 CLAUDE.md 描述方向）  
 100  - B：`.claude/skills/` SSOT，`.agents/skills/` 出口  
 101  - C：两侧均为 SSOT，按类型决定  
 102  利弊：A 避免漂移（#019 发现双份存在），B 更符合 Claude 运行习惯；C 维护成本高。
 103  
 104  **D3 触发日志采集机制**（见 §4.2）—— A 自动化但有 hook 支持风险；B 低成本但可能遗漏；C 平衡。
 105  
 106  **D4 大规模 skill 重构触发阈值**  
 107  - A：影响 ≥10 个 skill（§G.5.3 当前标准，引用 #019）  
 108  - B：≥20% active skill（动态）  
 109  - C：显式 user‑decision‑log 立项  
 110  B 适应 skill 总量缩减后阈值下移，C 最灵活但可能延后；建议 B 作为自动信号，C 用于明确决策。
 111  
 112  **D5 11 active skill 6 个月豁免处理**  
 113  - A：维持豁免至 2026‑11‑25（M‑000 §6 当前条款）  
 114  - B：M‑003 ratify 即解除，立即纳管  
 115  - C：仅 KEEP 维持，REWRITE 立即纳管  
 116  利弊：A 尊重历史裁决，B 尽早全面治理，C 折中。
 117  
 118  ## §6 升降级流程（§G.5 扩展）
 119  
 120  **§6.1 引用与增量**  
 121  直接引用 M‑005 §G.5.1（6 种 Verdict）、§G.5.2（季度审计）。M‑003 新增：
 122  
 123  - **新建 skill 提案模板**（结构）：
 124    1. 动机（为何无法下沉至前 5 级）  
 125    2. trigger 条件（含示例）  
 126    3. 预期消费者与频率  
 127    4. 元规则对齐论证  
 128    模板存入 `docs/templates/skill-proposal.md`，审议流程归 M‑002。
 129  - **大规模重构 baseline 流程**（参考 #019）：  
 130    - 受影响的 skill 清单 + 重建的 standards/templates 目标；  
 131    - `legacy_whitelist` 加豁免并设 `expires_on ≤ 30 天`；  
 132    - 执行后同步更新 `skill-architecture.md`、`skill-source-ledger.md`、`skills-lock.json`；  
 133    - 季度审计 owner 验证缓存过期。
 134  
 135  **§6.2 触发频率统计与误报率**  
 136  升级到 active 需满足 ≥3 次审计运行 + 30 天 + 误报率 < 20%（同 §G.2 阈值）。若 active skill 连续 2 次审计误报率 > 20%，启动降级评估。
 137  
 138  ## §7 与主笔体系的隔离要求（§G.5.4 执行化）
 139  
 140  - **主笔起草元规则期间**（含 M‑003 起草本身），**禁止使用** `.claude/skills/` 下任何 governance 类 skill（#016 自举循环破解 + 本任务 §9 自反性约束）。
 141  - **可用范围**：工具 skill（swiftui-pro / swiftdata-pro 等）及 standards/templates。
 142  - **CI 集成**（可选）：若启用 hook，CI 可校验当前 session 调用的 skill 列表，标记 governance 调用并警告（需 D3 落地）。
 143  - **主笔消费偏向折扣**：与 M‑005 §B.1 信号 5 双向引用；主笔自审自己消费过的治理 skill 时，KEEP/REWRITE 权重 ×0.5。
 144  
 145  ## §8 与下游 M‑001 / M‑002 / M‑004 的接口
 146  
 147  - **M‑001**：skill 审计主笔提名规则继承 M‑005 §H 轮换原则（§G.5.5）；M‑003 定义 skill 审计的执行周期和判据，M‑001 负责具体提名流程。
 148  - **M‑002**：skill 提案审议、分歧裁决归 M‑002；M‑003 仅提供“提议是否合规（下沉优先、判据）”的初始过滤。
 149  - **M‑004**：可能承接 skill 触发日志的操作格式和 CI hook 配置，M‑003 不定义 schema。
 150  - **不重复定义**：M‑005 §G.5 的 Verdict 定义、季度审计间隔、baseline 机制均为底层判据，M‑003 引用而非重写。
 151  
 152  ## §9 自反性标注
 153  
 154  **起草过程使用工具清单**：直接 API 调用，无工具（zero‑context 任务）。本草案未调用任何 `.claude/skills/` governance skill，符合 §7 隔离要求；WebSearch 验证 D3 hook 可行性 @ 2026‑05‑25 未实际执行，留待决策点裁决后补充。
 155  
 156  > **实证速查**：
 157  > - Q1 判据与反例：skill‑audit‑final §6.2.1 + #017 裁决
 158  > - Q2 命名空间与同源偏向：skill‑audit‑final §6.2.2 + #017 Claude KEEP 被全军覆没
 159  > - Q3 生命周期与 52→11：skill‑audit‑final §6.2.3 + #019 批量执行
 160  > - 下沉优先级降 skill 末位：M‑000 §6（#020 修订）
 161  > - 6 种 Verdict + 季度审计：M‑005 §G.5（#020 新增）
 162  
 163  *本草案由 DeepSeek V4‑Pro 基于路径 C #016~#020 全实证起草，待帅哥裁决 D1‑D5 后进入 Stage 7.4 sign‑off。*


---

# 收尾

基于以上 task definition + M-003 v1 draft，输出你的 sign-off。仅输出 markdown，无任何 commentary。
