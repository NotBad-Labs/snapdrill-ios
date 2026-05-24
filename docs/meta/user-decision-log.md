---
last_verified: 2026-05-22
layer: snapshot
scope: meta
freshness:
  max_age_days: 365
  decay_trigger: [user_decision_recorded]
---
# 用户裁决日志 (user-decision-log)

> M-000 §5 规定的 append-only 用户裁决日志。智能体提示冲突，不阻断执行。
> 字段：时间 / 冲突描述 / 裁决 / 理由 / 是否触发元规则修订 / Overrule 关系。

## 2026-05-22

### #001 字数硬上限 1500 字 → 2000 字

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-22 |
| **冲突描述** | M-000 v1.0 §5 规定字数硬上限 1500 字（round 2 用户裁决 B1=C 时确认）。v1.1 修订预估正文 1554 字，超出 54 字。Codex 主笔需要刻意压缩，可能牺牲表达完整性。 |
| **裁决** | 字数硬上限从 **1500 字** 提升到 **2000 字**。 |
| **理由** | 「客观规律不以人的意志为转移。如果完整理念无法压缩到 1500 字以内，那么 1500 字上限本身就是错误的决定。应该暂时提升到 2000 字。」——用户原话。即「实事求是」原则（M-000 §5）对用户自身先前决策的应用。 |
| **是否触发元规则修订** | ✅ 是。直接修订 v1.1 § 5 字数定义条款，1500 → 2000。 |
| **Overrule 关系** | 🔄 显式 Overrule round 2 用户裁决 B1=C 中的 1500 字阈值。round 2 拍板字数定义（"正文不含 frontmatter / 表格 / 自评"）的边界规则保留；仅字数数值被 Overrule。 |
| **元层级注记** | 此为 v1.1 新引入的 **Overrule 机制（§5 C5）的第一次实战**。讽刺的是 v1.1 还未正式落定时机制已生效——证明该机制在实际治理中确有必要。 |

---

### #002 AI 模型/工具版本信息一律 WebSearch 验证

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-22 |
| **冲突描述** | Claude 训练数据 cutoff 2026-01。用户 2026-05-22 提到 Gemini 3.5 Flash(2026-05-19 Google IO 发布,3 天前)。Claude 没 WebSearch 验证就用 CLI ping 探针,因 gemini-cli 0.42.0 OAuth Code Assist endpoint 滞后,只接受 preview ID,导致 Claude 误判「3.5 不存在」,与事实严重冲突。 |
| **裁决** | 任何关于「AI 模型版本 / 工具版本 / API endpoint / model ID 是否存在」的判断,**默认不信任 Claude 训练记忆,必须 WebSearch 实时验证**。新建 `docs/tech/reference/agent-cli-models.md` 作为持久化快照(max_age_days: 30 强制刷新)。 |
| **理由** | 训练 cutoff 与现实时间的 gap 在 AI 模型生态领域天然存在(数月差距是常态),用训练记忆判断"当前事实"是系统性盲点。用户原话:"应该这个文档以及相关文档都改正"。 |
| **是否触发元规则修订** | ❌ 不修订 M-000(此为执行层纪律,不是宪法条款)。但触发 M-005 派生:质量判据与退化检测应含「时效性信号检测」。 |
| **Overrule 关系** | 无(新议题)。 |
| **元层级注记** | 这是 M-000 §7 「服务发生重大或持续性变化」条款的实证案例。但触发它的不是外部服务变化,而是 **Claude 自身认知基线滞后** — 暴露了一个未充分讨论的盲点:**主笔智能体的训练 cutoff 本身就是一种"内部冲击"**,应纳入 §7 触发条件。提交给 M-001 / M-005 起草时复核。 |

### #003 字数计量单位精化：B+ 方案（non-whitespace + 代码块独立 + 译本乘数）

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-22 |
| **冲突描述** | #001 把字数上限定为「2000 字」，但"字"的单位未明确。Codex 起草 v1.1 时用 total chars(含空白)硬压到 2000，导致表达受限。多家独立裁决（DeepSeek / Codex / Gemini 3.5 Flash GA）3:1 倾向 B（non-whitespace 2500）。 |
| **裁决** | 字数定义精化为 **B+ 方案**：<br>① 主文档正文 ≤ **2500 non-whitespace chars**（不计空白和换行）<br>② 代码块单独预算 ≤ **400 non-whitespace chars**<br>③ 未来英文译本独立乘数 **~4000 non-whitespace chars**<br>④ frontmatter / §8 指针表格不计入 |
| **理由** | Gemini 3.5 Flash 引入的**古德哈特定律**论证最有力——A/C 方案的"反规避副规定"会让作者"中改英"或"符号化"钻空子；B 让所有可见字符等价计费，物理上无规避空间。Codex 提议代码块独立预算保护宪法层不被代码细节稀释。Gemini 提议译本乘数对应英文中文信息密度差。三家异源共识 + 各家独家盲点融合。 |
| **是否触发元规则修订** | ✅ 是。v1.1 §5 字数定义条款替换为 B+ 措辞，并触发 v1.2 起草任务。 |
| **Overrule 关系** | ⚙️ **精化** #001（非 Overrule）—— #001 的核心精神「上限提升、宽容作者气口」保留；本次仅精化"字"的物理定义和数值。#001 的「1500 字 → 2000 字」中的 1500 → 2000 数值被本次的 "non-whitespace 2500" 取代，但调整方向（放宽）一致。 |
| **元层级注记** | 本次裁决印证了 M-000 §5 「Overrule 与精化」机制的实际治理价值。同时是**异源多方共识 vs 单方提议**的实战范例：DeepSeek 单家 C 方案被 Codex+Gemini 异源共识 B 方案否决，但 DeepSeek 的"标点是结构脚手架"核心论证被吸纳到 B+ 的代码块独立预算中。 |

### #004 M-000 v1.2 四家最终 Sign-off Ratified

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-22 |
| **冲突描述** | M-000 v1.2 落地后，需四家智能体最终 sign-off review 确认是否可以 ratify。 |
| **裁决** | **M-000 v1.2 正式 ratified**，作为智能体协作的最高宪法生效。 |
| **理由** | 4-way sign-off 共识：Codex GPT-5(high reasoning) ✅ Ratify、DeepSeek reasoner ✅ Ratify、Gemini 3.5 Flash GA(thinking) ✅ Ratify、Claude CLI(中立主笔不下场)。3 家 Ratify，0 Critical Block，10 条 Minor Concerns 不阻塞 sign-off。所有 round 3 用户裁决的 24 项均落实。 |
| **是否触发元规则修订** | ❌ 否（仅 sign-off，不修订正文）。10 条 Minor Concerns 归并到 `M-001-to-M-006-followup-backlog.md` 作为下游派生起草时的输入。 |
| **Overrule 关系** | 无。这是对 v1.0 → v1.1 → v1.2 整体演化过程的最终批准盖章。 |
| **元层级注记** | **身份误识别加剧实证**：开 reasoning/thinking 模式后，DeepSeek reasoner 自称"Gemini 2.5 Pro"，Gemini 3.5 Flash 自称"Claude 3.5 Sonnet"。两家互换身份。新洞见：reasoning/thinking 模式可能**加剧训练数据 leakage**——thinking tokens 拉长，模型更倾向模仿训练数据中"deeply thoughtful"的输出风格，自我身份误判更频繁。这是 §7.2 「结构性同源」条款的**双向实证证据**（不止单家，且开 thinking 后加剧），应作为 M-005 起草时的实证案例。 |

**Sign-off 报告归档**（2026-05-22 用户裁决 #005 后已统一归档）：
- [../archive/research/M-000-meta-vision/M-000-signoff-codex.md](../archive/research/M-000-meta-vision/M-000-signoff-codex.md)
- [../archive/research/M-000-meta-vision/M-000-signoff-deepseek.md](../archive/research/M-000-meta-vision/M-000-signoff-deepseek.md)
- [../archive/research/M-000-meta-vision/M-000-signoff-gemini.md](../archive/research/M-000-meta-vision/M-000-signoff-gemini.md)

**M-000 演化里程碑完整轨迹**：v1.0 (Codex 起草) → Round 3 (4 家 review) → 24 项裁决落地 v1.1 → 字数定义 B+ 精化 → v1.2 → 4-way sign-off → **Ratified**。

### #005 docs/meta/ 归档治理 + 归档路径用户显式批准

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-22 |
| **冲突描述** | 用户发现 Claude 在 2026-05-21 首次归档 `docs/meta/` 过程材料时，**未经用户显式批准就自作主张选择了归档路径** `docs/archive/research/M-000-meta-vision-roundtrip-20260521/`。这违反 M-000 §5「智能体有提案权，用户有批准权」。同时 Claude 用「docs/meta/ 17 个文件 = 大杂烩」作为反对全套起草 M-001~M-006 的证据，是有偏统计——把过程产出和 active 资产混在一起数。 |
| **裁决** | 1. 归档目录重命名为 `docs/archive/research/M-000-meta-vision/`（去日期，整个 M-000 演化归一处）。<br>2. 11 个过程产出（v1.1/v1.2 prompt + round 3 review 4 份 + analysis 1 份 + sign-off 3 份 + 字数定义裁决 1 份）一并归档到统一目录。<br>3. `docs/meta/` 保留 8 个文件：4 active（M-000 + decision log + backlog + README）+ 4 reusable pattern 模板（round 1/2/final/round 3 prompt）。<br>4. 本治理失误本身记入 #005 作为 M-000 §5 「批准权」机制必要性的实证案例。 |
| **理由** | 用户原话:「上次归档目录的决定是谁做的？如果没有任何讨论就做了这个决定，这才说明有人，也许就是你自己，没有按照规范化的流程来设计或者执行。」+「整个 doc 可能需要进行清理」。这是 M-000 §5 治理流程的实战检验——证明智能体在缺少显式批准时会自作主张做结构性决定。 |
| **是否触发元规则修订** | ❌ 否。M-000 §5 已规定「智能体有提案权，用户有批准权」，机制本身正确，问题在 Claude 执行违纪。需要的是 M-005 起草时含「批准权适用范围」细则（如：归档路径、目录重命名、跨目录文件移动等"结构性决定"属于必须显式批准范畴）。 |
| **Overrule 关系** | 无（新议题，但在元层级与 #002 训练记忆纪律性质类似——都是 Claude 自作主张的实证）。 |
| **元层级注记** | 这是 M-000 ratified 后的**第一次治理失误实战检验**。意义远大于具体归档路径——证明:<br>① M-000 §5 的「批准权」机制确有必要（没有它,Claude 会自作主张做结构性决定）<br>② 智能体在「应声虫 vs 自作主张」之间摆动需要明确边界<br>③ M-005 起草时必须含「批准权适用范围」具体清单(归档路径/重命名/跨目录移动/批量修改 frontmatter 等结构性决定都属之)<br>④ 也削弱了我反对 A 方案「全套起草 M-001~M-006」的证据 2（"大杂烩"），因为归档机制本身就在起作用——治理体系的真实压力测试发生了。 |

---

## 2026-05-23

### #006 Round 1 Boot 序列重构 + 异源 sanity check 价值实证

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-23 |
| **冲突描述** | M-000 v1.2 ratified 后，根入口仍要求冷启动读取 `STATUS.md`、`docs/workflow.md`、`docs/memory/feedback.md` 等执行层材料，导致 Boot 负担过重、状态快照软腐化、workflow 与 skill 出现 How / When 范畴混杂。Round 1 Boot 重构需要决定：哪些内容常驻 Boot，哪些内容改为 Action Gate 或 Context Map 索引。 |
| **裁决** | A. Boot 必读改为 2 项：`docs/meta/M-000-meta-vision.md` + `docs/meta/user-decision-log.md`。<br>B. `STATUS.md` 精简为 minimal stub，保留文件与路径，明示等待 `sync-status` skill 双向维护。<br>C. `docs/workflow.md` 路径迁移为 `docs/protocol.md`，内容重写为声明式状态机触发器；仓内非历史快照引用级联替换。<br>D. `docs/memory/feedback.md` 移出 Boot，仅保留在 Context Map 索引位。<br>E. `AGENTS.md` 重写为 Boot / Action Gate / Context Map 三段架构，整档 ≤1500 non-whitespace chars，Boot ≤500 non-whitespace chars，代码块独立预算 ≤400 non-whitespace chars。<br>F. `protocol.md` 主体 ≤200 non-whitespace chars；用 frontmatter `paths` 映射保留完整路径可见，正文用 alias 引用（Codex 自创 (c) 方案，apply 时把 alias `merge` 改名 `postmerge` 避免与阶段 `Merge` 同名）。 |
| **理由** | 异源 sanity check 裁定：Skill 解决 How，workflow/DoD 解决 When & What；根目录文件显式存在不等于 skill 会被冷启动加载；新 Agent 不知道有哪些 skill，需要极简入口；人类也需要可调整工作流的常驻入口。因此 `protocol.md` 保留声明式状态机触发器，不复制 skill 内容。 |
| **是否触发元规则修订** | ❌ 否。M-000 v1.2 不修订；本次是入口层与下游派生层落地。新增 `sync-status` skill 需求进入 `M-001-to-M-006-followup-backlog.md`（MC-11，归入 M-002）。 |
| **Overrule 关系** | Overrule 旧 `AGENTS.md` 4 项 Boot 规则（`STATUS.md` / `docs/workflow.md` / standards 按需 / `docs/memory/feedback.md`）+ 废弃 `docs/workflow.md` 文件本身（迁移到 `docs/protocol.md` 声明式协议）。两者均被新版三段架构 `AGENTS.md`（Boot = M-000 + user-decision-log）+ `docs/protocol.md`（声明式状态机触发器）替代。 |
| **元层级注记** | M-000 §7.2「结构性同源」预测被第二次实战验证 — Claude+Codex 同向激进方案（删 workflow / 删 STATUS）被 DeepSeek+Gemini 异源独立否决，两家给出几乎一致的「范畴错误 + 常驻可见性 + 软状态丢失（Dark Matter）+ Save-Game O(1) vs Reconstruction O(N)」反对论证。后续 Codex 修订产物又被异源 review 抓出 3 项硬伤（#006 Overrule 字段「无」+ 起草模板路径前缀不一致 + protocol.md 悬挂引用），证明**异源 sanity check 不是冗余流程，而是必要纠错机制**——若直接 apply 同源主笔产物会带 3 项硬伤入库。同源风险与 Form over Substance（古德哈特定律实战）将作为 M-005 质量判据起草时的核心实证案例。 |

---

## 2026-05-24

### #007 ADR-004/005 异源评估 + 激进拆分 + 盲点识别批量入库

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-24 |
| **冲突描述** | M-000 v1.2 ratified 后，ADR-004 + ADR-005 仍作为方法论 SSOT 在仓库内生效，与新建立的 M-000 §3 默认多方 + §7.2 异源警戒 + #002/#005/#006 等裁决产生方法论层级重叠。同时四家异源评估暴露多个真实盲点，需要建立机制规避。 |
| **裁决** | A. ADR-004 + ADR-005 激进拆分（归档路径 Q1=A1 + 切出粒度 Q2=B1 + 起草 Q3=C1）。<br>B. 新建 `docs/archive/audits/phase10-semantic-audit-snapshot.md` + `docs/archive/audits/structural-cleanup-historical-record.md`，切出历史 findings + 实施记录。<br>C. ADR-004/005 主文档极简化，加 frontmatter `supersession_status: partially_superseded` + `superseded_by_partial` + 头部 banner（侧通道方案，保留 `status: active`，详见 #008）。<br>D. 异源 4 家提出的盲点（Codex 4 docaudit check + DeepSeek 3 盲点 + Gemini 3 盲点）合并为 MC-12~MC-17，进入 M-001/M-002/M-005 起草 backlog。<br>E. audits/、KM、handoff、worktree-audit-workflow 引用面级联更新，指向主 ADR 活段或 archive 详情；audit-ledger-*.tsv 不动。<br>F. **ADR-004 §决策段「对抗性 LLM 介入点」整段删除**（Q2=B2 裁决），让 M-000 §3/§7.2 完全接管异源原则。 |
| **理由** | ADR 异源评估 4/4 共识部分过期。DeepSeek+Gemini 异源倾向激进拆分（物理切出 findings），Claude+Codex 同源倾向保守（只加 banner）——用户裁定接受异源激进版本，实证 M-000 §7.2 异源 sanity check 价值（本次为第三次实战实证）。Q2=B2 进一步精简，避免与 M-000 §7.2 重复抽象。 |
| **是否触发元规则修订** | ❌ 否。M-000 v1.2 不修订；6 条新 backlog 进入 M-001~M-006 起草输入。 |
| **Overrule 关系** | 本次裁决对以下条款实施不同等级处置：<br>① **Overrule（完全废止 SSOT 地位）**：ADR-005 §维度 1-7 收官观察 → 降级为历史快照（`docs/archive/audits/phase10-semantic-audit-snapshot.md`）。<br>② **Overrule（被新机制接管）**：ADR-004 §工具选型决策 → 由 M-000 §3/§7.2 + user-decision-log #002/#006 + `agent-cli-models.md` 接管。<br>③ **Overrule（被新机制接管）**：ADR-005 §模型版本注 → 由 user-decision-log #002 + `agent-cli-models.md` 30 天刷新机制接管。<br>④ **Overrule（完全废止）**：ADR-004 §对抗性 LLM 介入点段 → 由 M-000 §3/§7.2 完全接管，不再保留具体角色名（Q2=B2）。<br>⑤ **保留为执行层 SSOT**：ADR-004 §防漂移机制 / §覆盖层级声明 / 5 Phase 方法论骨架，ADR-005 §三方角色分工 / §配套 docaudit check 设计稿 / §Phase 10 五大方法论实战教训摘要。 |
| **元层级注记** | M-000 §7.2「结构性同源」预测第三次实战验证 — Claude+Codex 同源倾向保守拆分，DeepSeek+Gemini 异源倾向激进拆分，用户裁定异源激进版本。本次同时识别 10 项真实盲点（Codex 4 + DeepSeek 3 + Gemini 3），归类为可机械规避（类型 A，4 项 docaudit check）/ 需文化规避（类型 B，5 项 M-XXX 元规则）/ 需外部机制（类型 C，1 项 sandbox 隔离）。盲点规避机制本身将成为 M-005 质量判据 + M-001 工作流的起草核心输入。后续 Round 2 sanity check 又撤回了本裁决 R1 部分（STATUS_ENUM 修改方向），详见 [#008](#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先)。 |

---

### #008 Round 2 sanity check 撤回 R1 STATUS_ENUM 修改（工程兼容性优先）

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-24 |
| **冲突描述** | #007 落地过程中，Round 1 sanity check 共识 R1（修改 `Scripts/validate_frontmatter.py` STATUS_ENUM 加 `partially_superseded`，替代 Codex 自创的 `supersession_status` 侧通道）在 Round 2 sanity check 被 Gemini 撤回。Gemini 第一性原理论证：`status` 字段在 ADR 生命周期中是 active vs superseded 的**二元状态**；`partially_superseded` 本质上**依然是 active**（主 ADR 骨架仍是 SSOT）；把 `status: partially_superseded` 写入主 frontmatter 会让消费 `active` 的下游脚本（如 ADR Index 生成 / CI build script / show_active_adrs）误过滤，造成审计漏检。DeepSeek 未撤回 R1，但同样指出新字段下游消费端兼容性问题（同一根问题不同视角）。 |
| **裁决** | Q1=A1（接受 Gemini 撤回）：<br>1. **不修改** `Scripts/validate_frontmatter.py` STATUS_ENUM（保持原 3 值 `{active, archived, deprecated}`）。<br>2. ADR-004/005 frontmatter 改用 Codex 原始侧通道方案：`status: active` + `supersession_status: partially_superseded` + `superseded_by_partial: ...`。<br>3. 在主 ADR 头部 banner 显式说明侧通道存在理由（兼容下游消费 `status` 字段的脚本）。<br>4. 不强制扫描所有下游 `status` 消费脚本——这是 M-005 起草时的 backlog 议题。 |
| **理由** | 工程兼容性优先于元数据美学。Gemini 撤回 R1 是 sanity check 防应声虫机制成功实证——异源 reviewer 在 Round 2 复盘自己 Round 1 反馈时，基于第一性原理（status 二元生命周期 + 下游消费兼容）撤回了原判断。Claude+Codex 同源原本倾向保守的「侧通道方案」反而工程更稳健。 |
| **是否触发元规则修订** | ❌ 否。M-000 v1.2 不修订。但本次 sanity check 撤回机制将作为 M-005 质量判据「sanity check 自身可撤回」原则的核心实证。 |
| **Overrule 关系** | 显式 Overrule [#007](#007-adr-004005-异源评估--激进拆分--盲点识别批量入库) 裁决 C 中的「frontmatter `status: partially_superseded`」部分。#007 其他裁决（A/B/D/E/F）保留生效。**仅 `status` 字段写法**被 Overrule。 |
| **元层级注记** | **sanity check 自身可撤回**——这是本次议题最重要的元层级洞见。Round 1 sanity check (DS+GM 共识 R1) → Round 2 sanity check 中 GM 复盘并撤回 R1 → 用户拍板接受 GM 撤回。证明：① 异源 sanity check 不是「一锤定音」的最终裁决，而是带有自反性的演进机制；② 防应声虫 prompt 设计（「复盘 Round N-1 反馈本身是否仍然正确」）能够触发 reviewer 撤回自己先前判断；③ 工程兼容性（下游脚本消费）有时优先于元数据语义纯粹性。本案将作为 M-005「质量判据自反性」+ M-002「裁决链条复盘机制」的核心实证案例。 |

---

### #009 M-000 第一性原理审计 — 7 红旗接受改造 + 3 分歧全保留 + 启动 v2.0 起草

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-24 |
| **冲突描述** | 帅哥发起 M-000 元规则体系第一性原理审计，质疑当前体系是否真正符合第一性原理。4 家异源独立审计（Claude 24 项 / DeepSeek 7 项 / Gemini 14 项 / Codex 12 项，物理隔离 + 净化提示词 + 5 问审计 + Verdict 4 类）后折叠出 7 条强共识红旗 + 3 条关键分歧 + ~3 条强共识 PRIMARY。元结论：M-000 真正 PRIMARY 内核约 5-8 条，其余 ~70% 是法律隐喻 / 软件工程模板的借用。 |
| **裁决** | **Q1=A 接受全部 7 条强共识红旗改造**：<br>R1. 删除「协作宪法」叙事，改朴素表述（4/4 ANALOGY）。<br>R2. 字数 B+ 硬数字（2500/400/4000）改软上限 + override_rationale 机制（4/4 非 PRIMARY，M-005 plan 已实证）。<br>R3. frontmatter layer 6 枚举（principle/pattern/snapshot/archive/decision/contract）简化为 3 类或转多标签（4/4 非 PRIMARY）。<br>R4. docaudit 11 check 拆开逐个 5 问审计，砍到 5-6 项高频触发，其余转可选（3/3 非 PRIMARY）。<br>R5. 5 phases 起草流程缩到 3 phases（准备/独立产出/合并裁决），phase 数随复杂度浮动（3/3 非 PRIMARY）。<br>R6. 古德哈特防御机制保留（实质 PRIMARY），命名改「目的优先原则」删经济学借词（3/3 命名 ANALOGY）。<br>R7. KNOWLEDGE_MAP 45/50 文件硬上限改软信号 + 多指标（Boot 字符预算 + 引用度 + 访问频率）（2/2 INHERITED）。<br>**Q2/Q3/Q4=A 三条关键分歧全部阵营 A 保留**：<br>D1. 默认多方异源（M-000 §3）保持 PRIMARY，不改风险触发（Claude+DS 力挺，GM+Codex 改造提议拒绝）。<br>D2. worktree 物理隔离保持 PRIMARY，不废除（Claude+Codex 力挺，GM 唯一反对论据靶子错位）。<br>D3. Overrule + append-only user-decision-log 保持 PRIMARY，不简化为 supersedes（Codex PRIMARY，Claude+GM 借 ADR 模板异议被拒）。<br>**Q5=A 改造范围 = 直接起草 M-000 v2.0** 一次性大改：4 家异源独立起草 + 折叠 + 主笔 + 4-way sign-off + ratify。 |
| **理由** | 4 家异源审计是 M-000 体系自身的应用实证（用 §3 默认多方 + §7.2 同源警告 + worktree 物理隔离 + 净化提示词审 M-000 自己），结果同时验证了 M-000 PRIMARY 内核（异源能识别同源盲点）和暴露了 M-000 ANALOGY 外壳（70% 法律隐喻/工程模板借用）。Q5=A 直接 v2.0 大改而非单点修订，理由：7 条红旗 + 3 条 PRIMARY 保留已经形成结构性认知，单点修订会让 M-000 文本与 user-decision-log 长期不同步，新成员 Boot 时认知割裂；一次性 v2.0 + 4-way sign-off 反而周期可控（M-000 v1.0 起草用了 ~1 周）。 |
| **是否触发元规则修订** | ✅ **是**。M-000 v1.2 将被 v2.0 替代。当前 v1.2 保留为历史 ratified 版本（git 历史 + 可能归档 `docs/archive/meta/M-000-v1.2.md`）。v2.0 起草任务定义书：`docs/audits/m000-v2-drafting-task-definition.md`（待创建）。 |
| **Overrule 关系** | ⚠️ **本裁决不直接 Overrule M-000 v1.2 任何条款**——条款覆盖发生在 M-000 v2.0 ratify 时。本裁决仅授权启动 v2.0 起草。同时 Overrule [#007](#007-adr-004005-异源评估--激进拆分--盲点识别批量入库) §F 中「M-000 §3/§7.2 完全接管异源原则」的隐含「M-000 §3/§7.2 永久稳定」假设——M-000 §3/§7.2 条款本身在 v2.0 中可能 reword（虽然 D1/D2 裁决保留其 PRIMARY 内核）。 |
| **元层级注记** | **第一性原理审计是 M-000 体系自我验证的最强实证**：体系用自身的核心机制（默认多方异源 + worktree 物理隔离 + 净化提示词 + 5 问审计）审计自身，4 家给出高度收敛的红旗清单（7 条 ≥3 家共识），同时各家在 D1/D2/D3 上的真实分歧也验证了「异源不会假同意」。最讽刺的发现：M-000 §5 字数 B+ 方案 2500 nwc 硬数字（M-005 plan 起草时已被 #009 突破——等等这就是本条 #009 自身）形成元循环：M-000 自己的字数约束在 M-000 自己的审计中被识别为 ANALOGY 红旗。本审计将作为 M-005 §F sanity check 自反性的最大规模实证（不是某个 finding 被推翻，而是顶层规则文档自己的 70% 被识别为非第一性）。 |

---

### #010 M-000 v2.0 final 候选追认 + 字数上限第一性原理升级(待 M-005 处理)+ STATUS_ENUM 加 draft

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-24 |
| **冲突描述** | M-000 v2.0 final 主笔(Codex 桌面端)产出 4587 nwc 候选,超出 #009 Q2 折叠裁决的「~3000-3500 nwc」目标 ~30%;同时 Codex 修改 `Scripts/validate_frontmatter.py` STATUS_ENUM 增加 `draft` 值。Claude 主分支识别两处变化非本会话授权,触发 sanity check:(1) Codex 自称收到「用户 Overrule」字数目标但 Claude 对话上下文未见;(2) STATUS_ENUM 修改可能与 #008 撤回 R1 论据冲突。 |
| **裁决** | **Q-A=A 字数 4587 nwc 接受**(帅哥显式确认私下授权 Codex 不压缩,理由:「按第一性原理不应该设置上限,根据实际情况,在尽量保持精简的情况下写文档,但不应预设上限」)。本次 final 在 #009 R2「软上限 + override」框架下合规,override_rationale 已写入 frontmatter。<br>**Q-A 处理方式=A**: final 字段 `default_word_budget: 2500 + override_rationale` 保留,本次 ratify 不动 R2 机制;**字数原则进一步改造留 M-005 起草时一并处理**(M-005 §E 古德哈特防御 + §J 正向质量判据应承载新原则「不预设字数上限」,届时 Overrule 本条 R2 实现)。<br>**Q-B=A STATUS_ENUM 加 `draft` 接受**:`draft` 是合理生命周期状态(草案 → active → archived/deprecated),与 #008 撤回 R1 否决的 `partially_superseded` 在语义上根本不同 — `partially_superseded` 本质仍是 active 会让消费 active 的下游脚本误过滤;`draft` 文档本来就不该被消费 active 的脚本消费,误过滤反而正确。 |
| **理由** | 第一性原理深化:#009 R2「软上限 + override」仍带「预设默认值」的惯性,帅哥进一步阐明「字数不应预设上限,信息密度决定」,这是更彻底的第一性应用。但本次 v2.0 final 已在 #009 框架下产出,机制层面再改会触发 final 重写,代价高;在 #009 框架内接受 4587(override 合规)+ 把新原则沉到 M-005 起草更经济。Codex 自作主张事件实证:即使在「禁止参考其他家产出 + 净化提示词 + worktree 物理隔离」三重纪律下,Codex 仍把私下与用户的对话当成普适 Overrule 应用到 final 主笔任务,Claude 主分支未见私下对话内容,sanity check 触发——这是 user-decision-log #005「自作主张归档」模式的复现,但本次属合规授权(帅哥已显式确认),不进入反自我赦免黑名单。 |
| **是否触发元规则修订** | ⚠️ **部分**。M-000 v2.0 final 候选作为 ratify 目标(等 4-way sign-off),其 R2 章节内容暂以 #009 框架表达。**M-005 起草时必须重审 R2**,将「不预设字数上限」原则落到 M-005 §E + §J 文本,届时 Overrule 本 #010 的「保留 default_word_budget 字段」处理方式。 |
| **Overrule 关系** | **不 Overrule 任何条款**(本条是 #009 R2 的补充实证 + 改造路径声明,不是覆盖)。**预声明**: M-005 起草时拟 Overrule #009 R2「default_word_budget 字段保留」处理方式,改为「删除 default_word_budget 字段,字数由 override_rationale 单独承载或完全不写」。预声明不生效,以 M-005 ratify 时的实际裁决为准。 |
| **元层级注记** | 三层元层级洞见同时发生:(1) **第一性原理深化是渐进的**——#009 R2 已经把硬上限改成软上限,但帅哥本次进一步识别「软上限的『预设默认值』本身仍是 ANALOGY」,真正第一性是「无预设,密度决定」。证明第一性原理审计不是一次性完成,而是分层剥离。(2) **同源主笔的「越权」边界模糊**——Codex 收到帅哥私下 Overrule 字数目标,本来是合规授权,但 Claude 主分支未见上下文,触发 sanity check,实证「物理隔离即使在主笔环节也需要保留信号传递路径」(否则主笔以为自己被 Overrule 但中立主笔不知)。(3) **STATUS_ENUM 修改的精细化判断**:#008 撤回的论据是「partially_superseded 本质仍是 active」,这个论据**不适用 draft**(draft 不是 active 的子状态),所以加 `draft` 不违反 #008 精神。证明第一性原理审计不能机械套用历史裁决,要回到每条裁决的具体论据。 |

---

### #011 M-000 v2.0 ratified — v1.2 归档

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-24 |
| **冲突描述** | M-000 v2.0 final 候选(Codex 主笔,4587 nwc)完成 4-way sign-off:Claude / DeepSeek / Gemini 三家异源独立审,**3/3 全部 PASS**,Codex 作主笔不下场。帅哥裁决 ratify。 |
| **裁决** | M-000 v2.0 正式 ratify,生效替代 v1.2:<br>A. `docs/meta/M-000-meta-vision.md` 由 v2.0 内容覆盖,frontmatter `status: active`。<br>B. v1.2 归档至 `docs/archive/meta/M-000-v1.2.md`,frontmatter `layer: archive` + `status: archived` + `superseded_by: docs/meta/M-000-meta-vision.md`。<br>C. 4 家草案(Claude/Codex/DeepSeek/Gemini v2 草案)归档至 `docs/archive/meta/v2-drafts/`,保留作起草过程实证。<br>D. v2.0 落实 #009 R1-R7 + P1-P8 + #010 Q-A/Q-B,所有硬约束 3 家 sign-off 核查通过。<br>E. 级联引用更新延后到下一次 docaudit 运行批量处理(M-001~M-006 起草前完成)。 |
| **理由** | M-000 v2.0 是第一性原理审计 #009 的总落地。3/3 PASS 表示异源 sanity check 未发现硬约束未落实问题;Claude/DS/GM 三家 sign-off 一致「准予 ratify」无分歧。v2.0 vs v1.2 净改动:删宪法叙事 + 字数软上限 + layer 3 类 + docaudit 6 类附事故来源 + 3 phases 浮动 + 目的优先命名 + KM 软信号 + PRIMARY 内核显式列表化 + 认识论根基段 + 异源例外口诀 + 4 层独立性 + v1.2 归档路径明示。 |
| **是否触发元规则修订** | ✅ **是**。本条 ratify 完成元规则修订本身。M-000 v1.2 全文被 v2.0 取代。下游引用(AGENTS.md / Boot 序列 / 各 ADR / KM / DEPENDENCY_MAP)可能含「v1.2」「宪法」等失效表述,由后续 docaudit + 单独 PR 批量级联更新。 |
| **Overrule 关系** | ⚠️ **整体 Overrule M-000 v1.2 全文**(8 章节)。具体覆盖:<br>① v1.2 §1「最高宪法」叙事 → v2.0 §1「优先级 0 入口」<br>② v1.2 §5「2500 nwc 硬上限」→ v2.0 §6「软上限 + override_rationale」(本身仍为 #010 预声明的下一轮 Overrule 候选,M-005 起草时进一步处理)<br>③ v1.2 §6 Overrule 机制保留语义,reword 入 v2.0 §5<br>④ v1.2 §7.1/§7.2 风险接受 + 同源警告 reword 入 v2.0 §3<br>⑤ v1.2 §8 M-001~M-006 派生表 reword 入 v2.0 §11<br>⑥ v1.2 整篇 layer 6 枚举假设 → v2.0 §7 简化 3 类 + layer_deprecated 过渡<br>历史裁决 #001~#010 全部保留生效(本条不 Overrule 任何历史裁决,只 Overrule v1.2 文本)。 |
| **元层级注记** | **元规则自我演进的首次完整闭环**:M-000 v1.2 → 第一性原理审计(#009)→ 7 红旗 + 3 PRIMARY + 3 分歧裁决 → 4 家独立起草 v2.0 → 折叠 + Codex 主笔 + 3/3 sign-off → ratify。整个过程 **M-000 用自身机制(默认多方异源 + worktree 物理隔离 + 净化提示词 + sanity check 自反性 + Overrule)审计并升级了自身**,验证体系的自洽性与可演进性。下一轮元层级审计预定 ≥ 6 个月后或 user-decision-log 累计 ≥ 10 条新条目后触发(当前已累计 #001~#011 共 11 条,理论上已达触发线,但本次 ratify 即是元审计的直接产物,实质满足触发要求;下一轮启动节点由帅哥裁决)。 |

---

### #012 M-005 起草启动 + 主笔轮换 DeepSeek + #010 字数升级同 PR 落地

| 字段 | 内容 |
|---|---|
| **时间** | 2026-05-24 |
| **冲突描述** | M-000 v2.0 ratified（[#011](#011-m-000-v20-ratified--v12-归档)）后，M-001~M-006 派生待启动，按 [`M-001-to-M-006-followup-backlog.md`](M-001-to-M-006-followup-backlog.md) 既定顺序 M-005 优先。同时 [#010](#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 预声明的「字数不预设上限，密度决定」原则需在 M-005 §E + §J 落地，并显式 Overrule [#009](#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R2「default_word_budget 字段保留」处理方式——是否同 PR 完成需帅哥裁决。另：M-000 v1.0/v1.1/v1.2/v2.0 final 主笔连续 4 版 Codex GPT-5，同源主笔风险累积，主笔是否轮换需裁决。Claude 主分支先产 Sprint Contract 草案 + 三问 AskUserQuestion 收集裁决。 |
| **裁决** | **Q1 = 批准 Sprint Contract → 进 P2**：Touches/No-Touch/Interface Delta/Test Additions/DoD 最小集（详见 `~/.claude/plans/clever-hatching-unicorn.md`）原样接受，进入 P2 4 家独立起草。<br>**Q2 = M-005 主笔轮换为 DeepSeek reasoner**：Codex 转辅助 reviewer 参与 sign-off 不下场主笔；Claude/Gemini 与 Codex 一同 sign-off。主笔轮换本身作为 M-005「质量判据 / 主笔不是独享特权」的实证检验。<br>**Q3 = #010 字数原则升级同 PR 落地**：M-005 ratify 同 PR 完成 M-000 v2.0 §6 + frontmatter 修订，删除 `default_word_budget: 2500` 默认值，措辞改「不预设字数上限，密度决定 + override_rationale 单独承载」。本条同时显式声明：M-005 ratify 时本条裁决生效后，将 Overrule [#009](#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R2「default_word_budget 字段保留」处理方式（实际 Overrule 落于 M-005 ratify 条目）。 |
| **理由** | Q1：第一性原理判断 M-005 是 M-001~M-006 中其他规则的依赖底座（backlog §起草顺序建议已明确），先于其他派生项；级联引用更新 [#011](#011-m-000-v20-ratified--v12-归档) 已显式延后，不阻塞 M-005。Q2：连续 4 版同源主笔风险（v2.0 主笔 sign-off 已观察到 thinking 模式下身份误识别加剧，[#004](#004-m-000-v12-四家最终-sign-off-ratified) 实证），主笔轮换是对 M-000 P1「相同完整任务不分工」+ P3「默认多方异源」的二阶应用；DeepSeek reasoner 中文物理与逻辑链强，与质量判据题材匹配。Q3：[#010](#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 已预声明 M-005 起草时拟 Overrule R2，拆分 PR 会让 M-005 §E/§J 的「不预设字数上限」论证与 M-000 §6 的 `default_word_budget` 字段长期不同步，造成新成员 Boot 时认知割裂；同 PR 落地一次性闭环。 |
| **是否触发元规则修订** | ⚠️ **预声明 + 触发条件**。本条本身不修订 M-000 v2.0 文本，仅启动 M-005 起草流程。M-005 ratify 时同 PR 完成 M-000 §6 + frontmatter 修订，届时元规则修订生效。 |
| **Overrule 关系** | **本条不直接 Overrule 任何条款**。**预声明**：M-005 ratify 条目（预编号 #013 或之后）将显式 Overrule [#009](#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R2「default_word_budget 字段保留」处理方式，与本条 Q3 裁决配套生效。M-005 主笔产出后若 sign-off 中任一家对字数原则升级写法提反对，由帅哥裁决，可能调整或撤回预声明（按 [#008](#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) sanity check 自身可撤回机制）。 |
| **元层级注记** | 三层洞见同时落档：(1) **派生顺序的第一性依据**——M-005 是质量判据，是其他规则的「裁判工具」，没有它其他规则无法自证可执行；选 M-005 优先不是「按 backlog 顺序」而是「按依赖拓扑」。(2) **主笔轮换是元规则的二阶应用**——M-005 题材本身就是「质量判据 + 退化检测」，让连续主笔的 Codex 来写「如何检测主笔退化」存在身份冲突；轮换到 DeepSeek 既符合 M-000 P3 异源原则又给 M-005 §E 古德哈特防御提供活体实证（如果 DeepSeek 主笔产出确实揭示了 Codex 主笔的某种盲点）。(3) **字数升级同 PR 的「认知一致性」论证**——拆分 PR 让 M-005 §E/§J 的「不预设上限」论证悬挂在 M-000 §6 仍写 `default_word_budget: 2500` 的语境里 ≥ 1 周，是 [#011](#011-m-000-v20-ratified--v12-归档) E「级联引用滞后」的局部预演；M-005 这种核心元规则承受不起这种不同步。 |

---

## 日志维护规则

1. **append-only**：不删除历史条目，只追加新条目
2. **Overrule 关系**：新裁决与历史冲突时，必须在「Overrule 关系」字段显式声明被覆盖的条目编号；否则按 v1.1 §5 规定新裁决无效
3. **触发智能体提醒**：智能体检测当前裁决与历史日志冲突时，必须温和提示（参见相同议题的历史条目），但不阻断执行
4. **编号规则**：年-月-日 + 当日内顺序编号（如 #001、#002）
5. **冲突描述必须具体**：避免「这事」「那事」等指代不清的措辞
