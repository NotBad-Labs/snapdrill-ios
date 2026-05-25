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
