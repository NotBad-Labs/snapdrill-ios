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

## 日志维护规则

1. **append-only**：不删除历史条目，只追加新条目
2. **Overrule 关系**：新裁决与历史冲突时，必须在「Overrule 关系」字段显式声明被覆盖的条目编号；否则按 v1.1 §5 规定新裁决无效
3. **触发智能体提醒**：智能体检测当前裁决与历史日志冲突时，必须温和提示（参见相同议题的历史条目），但不阻断执行
4. **编号规则**：年-月-日 + 当日内顺序编号（如 #001、#002）
5. **冲突描述必须具体**：避免「这事」「那事」等指代不清的措辞
