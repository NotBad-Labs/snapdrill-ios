你被请求对 SnapDrill iOS 项目元规则 **M-005 §J.2 v2 patch**（Codex GPT-5.5 Thinking GUI 主笔产物）做异源 sign-off。

# 任务背景

- 路径 C Stage 7.8c — §J.2 patch sign-off
- 主笔：Codex GPT-5.5 Thinking GUI（第 1 次承接路径 C 主笔，由帅哥裁决 Codex 系统性更高权重而提名）
- 触发：Stage 7.8 sign-off 出现 Codex BLOCK vs Antigravity PASS binary 分歧，第一性原理分析识别 M-005 §J.2「每一段」措辞盲点（DeepSeek 主笔 §J 时未定义粒度）
- ratify 体例：与 M-003 v2 ratify 合并到同 PR（#021），第四次 + 第五次元规则修订并发

# 你的身份与角色

- **本任务模型**：Claude Opus 4.7（主分支会话）
- **同源风险**：task definition v2 起草 + Stage 7.8a 反思报告起草 + override_rationale 代修

权重 0.3（折扣最重）。Codex 主笔 §J.2 时间接受你 Stage 7.8a 反思报告的框架，请着重 sanity check：(1) 反思报告 4 候选是否完整？是否遗漏第 5 候选？(2) Codex 推荐 D 是否被反思报告框架预设引导？(3) 你自己的「分层」倾向是否在反思报告中已暗中预设？

# Zero-context 说明

你没有访问项目仓库文件系统的能力，所有输入已 inline。

# 输出格式（严格）

只输出 markdown，按以下结构：

```
## [你的名字] Sign-off — M-005 §J.2 v2 Patch

### Overall Verdict
PASS | CONDITIONAL | BLOCK

### 候选 D（分层）评估

Codex 主笔在 4 个候选（A 双门 / B 仅章节 / C 仅段级 / D 分层）中推荐 D。你独立评估：
- 是否同意 D 推荐？
- 若同意，列出 D 的核心优势
- 若不同意，指出 D 的盲点 + 推荐你的替代候选

### §A diff 精度评估

Codex 把 §J.2 原文 3 条（每一段不能下沉/压缩/省略）重写为分层结构：
- 章节级 logical unit：不能下沉 + 不能省略
- 段级 grammatical paragraph / structured block：不能压缩（仅触发审查）
- §J.1 仍优先（不预设上限）
- 违反信号 4 条扩充

请独立核验：
- 新措辞是否保留原 §J.2 三条要求的等价语义？
- 「触发审查」机制是否会让段级压缩性证明被过度规避？
- §J.1 优先声明是否完整？

### D-J1 ~ D-J4 决策点立场

Codex 未擅自裁决 4 个决策点。请独立陈述你对每个决策点的倾向（仅作为帅哥 #021 ratify 时的参考输入，最终裁决权在帅哥）：

- D-J1 「每一段」粒度定义（A 双门 / B 仅章节 / C 仅段级 / D 分层）— 你倾向？
- D-J2 default budget 行为（A 不改 §J.1 / B 同步修 §J.1 / C 只在 §J.2 注明）— 你倾向？
- D-J3 §J.2 适用范围（A 仅 M-001~M-006 / B 含 task definition / C 含 ADR/standards）— 你倾向？
- D-J4 机械验证机制（A 写入 §J / B 另设 §J.7~§J.8 / C 不写入）— 你倾向？

### 下游影响核验

Codex 列出 §E 下游影响清单（M-003 v2 sign-off / M-002~M-006 主笔 / task definition v2）。你独立核验：
- 是否遗漏其他下游影响？
- M-003 v2 按新 §J.2 v2 重审，原 Codex BLOCK 是否能转为 PASS？

### BLOCK 项（若有）

含 line range + 问题描述 + 修订建议

### CONDITIONAL 项（若有，可在 ratify 同 PR 满足）

含 line range + 条件描述 + 是否同 PR 可满足

### Sanity check 自反性

复盘你对「每一段」概念的预设立场。是否在本次评估中暗中合理化某个候选？

### 同源偏向显式标注

按 vendor 关系折扣权重。本次主笔 Codex GPT-5.5（OpenAI），反思报告 + 起草 Claude 主分支（Anthropic），原 §J 主笔 DeepSeek（DeepSeek）。

### 元层级建议（可选）

仅当发现新结构性问题。**按 P4 N≤2 规则**：本 sign-off 后不接受「对 sign-off 的二阶评价」建议——元层级建议范围限于 §J.2 v2 patch 本身。
```

---

# 输入 1/4 — Stage 7.8a 反思报告（Claude 主分支起草）

---
last_verified: 2026-05-25
layer: snapshot
scope: meta-reflection
freshness:
  max_age_days: 30
  decay_trigger: [m_005_j2_ratified]
---

# 路径 C Stage 7.8a — M-005 §J.2 措辞盲点反思报告

> 类比 Stage 6.1（[`path-c-stage6-reflection.md`](path-c-stage6-reflection.md)）反思报告模式。Stage 7.8 sign-off 异源分歧（Codex GUI BLOCK vs Antigravity GUI PASS）触发的元规则反思。本文是 Stage 7.8b Codex GUI 主笔 §J.2 patch 的输入。

## §0 触发事件

Stage 7.8 M-003 v2 sign-off 出现 binary 分歧：
- **Codex GUI**：BLOCK（3 BLOCK + 5 CONDITIONAL）
- **Antigravity GUI**：PASS（15/15 ✅）
- 两家都 0 同源折扣（异源），但严格度判定相反

帅哥按第一性原理分析后裁决（2026-05-25）：
- D = 彻底解决（不绕过盲点）
- 节奏疲劳高容忍（5 次元规则修订可接受）
- Codex 系统性更高权重

→ 启动 F 路径：精化 M-005 §J.2 + 与 M-003 v2 同 PR ratify。

## §1 盲点定位

### §1.1 M-005 §J.2 原文（line 461-467）

> `override_rationale` 不再是「破例」，而是**密度证明**——作者必须论证：
> 1. **每一段不能下沉**：段落内容不可沉到下游 standards/skills/tools。
> 2. **每一段不能压缩**：段落中无冗余、重复、装饰性论证。
> 3. **每一段不能省略**：省略后会导致信息缺失（依赖链断裂、证据链模糊）。

### §1.2 「每一段」的语义歧义

「段」在元规则文本中可解读为：

| 解读 | 含义 | 应用到 M-003 v2 |
|---|---|---|
| **A. grammatical paragraph** | 散文段（以空行分隔）| 8 章 × 3-5 段 ≈ 24-40 段需逐段论证 |
| **B. logical unit** | 章节级（§1 / §2 / ...）| 8 章 + 附录 ≈ 10 段需逐章论证 |
| **C. 双轨** | 章节级必选 + 段级触发条件 | 看下文 §3 候选 |

§J.2 原文无显式定义 → 两个解读都合字面。

### §1.3 起源：DeepSeek 主笔的概念建模

M-005 v2 由 DeepSeek V4-Pro 主笔（user-decision-log #015）。

**实证关联**：
- DeepSeek M-003 v1 字数自检：自报 2480 实测 4958（错估 ~2×）
- DeepSeek M-003 v2 字数自检：自报 2412 实测 5132（错估 ~2×）
- 两次都是 DeepSeek 主笔
- **同一主笔对「每一段 / 字数 / 密度」概念建模都不精确**

§J.2 措辞盲点与字数自检失真**同源**——DeepSeek 起草元规则时对「段」「字数」这类度量单位的概念精度不足。

### §1.4 异源 sign-off 的实证价值

| 维度 | Codex GUI | Antigravity GUI |
|---|---|---|
| 解读「每一段」| grammatical paragraph | logical unit |
| 对 v2 override 判定 | BLOCK（未证压缩性）| PASS（结构论证已足）|
| 对字数 frontmatter 错误 | 抓到 line 11-12 重复 + 5132/5328 冲突 | 漏看 |
| 对 WebSearch 可复核 | 要求 URL + 精确清单 | 接受 inline 结论 |

→ Codex 字面级精读 vs Antigravity 概念级匹配。两种判读各有道理，但都暴露 **§J.2 措辞本身不严密**——严密措辞应使两家解读收敛。

## §2 候选修订（待 Stage 7.8b 主笔细化）

### §2.1 候选 A — 章节级 + 关键段级双门

「每一段」定义为：
- **必选 1：每个 logical unit（章节，含 §1-§N + 附录）**
  - 必须证明：不能下沉 / 不能压缩 / 不能省略（三条）
- **必选 2：超 default budget 部分中的每个 grammatical paragraph**
  - 当文档超 ≤2500 default 后，超出部分（折算到具体段落）必须额外按散文段级证明压缩性

优点：覆盖 Antigravity 与 Codex 两种解读 + 与「密度决定字数」立场一致
缺点：双门复杂度高，主笔可能误用

### §2.2 候选 B — 仅章节级

「每一段」定义为：每个 logical unit（章节）。删除散文段级要求。

优点：简洁；与 M-005 §A 章节化判据一致
缺点：散文级冗余（如 D1-D7 表格化空间）不可机械识别；Codex 类严格审计仍会抓到压缩点

### §2.3 候选 C — 仅散文段级 + 章节级总论

「每一段」= grammatical paragraph，每章首段做章节级总论 + 每段单独论证。

优点：最严，符合 Codex 标准
缺点：override_rationale 量爆炸（M-003 v2 24-40 段 × 3 条 = 72-120 行论证）

### §2.4 候选 D — 元层级声明 + 三层 detail

§J.2 重写为「分层证明」结构：
1. **章节级（mandatory）**：每章证不能下沉 / 不能省略（依赖链层面）
2. **段级（mandatory when over budget）**：超 default 部分必须证不能压缩（token 层面）
3. **句级（recommended）**：高 stakes 关键句可加压缩证明（深度治理）

优点：与 M-000 §6「下沉去向优先级」体例对应（分层）；超 budget 触发更严标准
缺点：3 层复杂度，可能让 override_rationale 形式化

## §3 决策点（帅哥 Stage 7.9 ratify 时裁决）

### §3.1 D-J1 「每一段」粒度定义

A / B / C / D 候选选哪个？

### §3.2 D-J2 default budget 行为

- M-005 §J.1 已说「不预设上限」
- 但 §J.2 字面隐含「default = 2500」（超才需 override）
- 这本身是张力。是否同步修 §J.1 / §J.2 对齐？

### §3.3 D-J3 §J.2 适用范围

- 仅 M-001~M-006 元规则文档？
- 还是包括 task definition？
- 还是包括 ADR / standards？

当前 v2 task definition 也超字数（15446 nwc / ~300 行），如果 §J.2 适用范围扩到 task definition，那 task definition v2 本身也违规。

→ 实证：task definition 是 contract layer 不是 principle layer，可能不适用 §J.2。但 §J.2 原文未明示。

### §3.4 D-J4 与字数机械验证机制衔接

帅哥之前批准 task definition v2 §6 加「字数机械验证机制」（frontmatter 声明可机械验证）。这条要不要写入 M-005 §J 作为正式条款？

## §4 主笔提名

按 M-005 §H 同源轮换 + 帅哥裁决 Codex 更高权重：

- ❌ DeepSeek：§J 原主笔 + 字数自检失真 + M-003 v2 主笔 → 同源风险三重
- ❌ Claude 主分支：task definition v2 起草 + override_rationale 代修 → 同源
- ✅ **Codex GUI（GPT-5.5 Thinking）**：路径 C 三次最严格判断 + 帅哥裁决更高权重 + 异源
- ⚠️ Antigravity GUI：异源但 Stage 7.8 已 PASS（同源风险中等，「立场固化」可能）

**推荐主笔**：Codex GUI

## §5 §J.2 精化的下游影响

| 下游 | 影响 |
|---|---|
| M-003 v2 sign-off | Codex BLOCK 的 override 缺压缩性问题按新 §J.2 v2 重审 |
| M-002/M-006/M-001/M-004 主笔 | 未起草，按新 §J.2 v2 直接采纳 |
| 现有 standards/templates | §J.2 不适用（D-J3 决定）|
| task definition v2 | 视 D-J3 决定 |
| ADR | 视 D-J3 决定 |

## §6 ratify 体例（Stage 7.9）

按 #020 体例（同 PR 落地多处精化）：

**#021 ratify 同 PR 落地**：
1. M-005 §J.2 v2（按主笔产 patch + sign-off）
2. M-003 v1（首次 ratify，从 v2 draft 改名）
3. M-003 task definition v2 → 归档
4. M-000 §11 派生表更新（M-003 改「已 ratified」）
5. 排他性条款 #016 解除
6. user-decision-log #021 含 D-J1~D-J4 裁决 + 主笔轮换裁决 + Codex 更高权重立场

第四次（M-003 ratify）+ 第五次（§J.2 v2）元规则修订**合并为一次 PR**，节奏对齐 #020 模式。

## §7 sanity check 自反性

本反思报告由 Claude 主分支起草。同源偏向风险：
- 我是 task def v2 + override_rationale 代修者
- 我之前在 Stage 7.8 倾向 C 路径（绕过盲点）
- 帅哥裁决 D=彻底解决后我才转向 F

→ 本报告 **可能低估 Antigravity 立场强度 + 高估 Codex 立场强度**（呼应帅哥裁决 Codex 更高权重）。Stage 7.8b 主笔（Codex GUI）和 7.8c sign-off（Antigravity + DeepSeek + Claude）应当独立核验本报告问题陈述与候选措辞是否中立。

## §8 启动 Stage 7.8b 条件

本报告 commit 后，Stage 7.8b 启动：
- Claude 主分支为 Codex GUI 准备完整 prompt（含本反思报告 + M-005 §J 全文 + 候选 A-D + 决策点）
- 三处可达（剪贴板 / Desktop / /tmp）
- 帅哥手动跑 ChatGPT 桌面 GPT-5.5 Thinking
- 输出粘回 → Claude 综合 → Stage 7.8c sign-off

---

**实证锚**：
- Stage 7.8 sign-off 矩阵：`/tmp/m003-signoff-v2-{codex,gemini}-output.md`
- Expert review 3 家：`/tmp/m003-expert-review-{deepseek,codex-gui,gemini-gui}-output.md`
- 第一性原理分析：`~/.claude/plans/compiled-pondering-tulip.md`
- M-005 §J 全文：`docs/meta/M-005-quality-criteria.md` line 447-510


---

# 输入 2/4 — Codex GUI 主笔 §J.2 v2 patch（待 sign-off）

# M-005 §J.2 v2 Patch

## §A 修订前后对比（diff 视图）

### Before（M-005 v2 §J.2 原文）

`override_rationale` 不再是「破例」，而是**密度证明**——作者必须论证：

1. **每一段不能下沉**：段落内容不可沉到下游 standards/skills/tools。
2. **每一段不能压缩**：段落中无冗余、重复、装饰性论证。
3. **每一段不能省略**：省略后会导致信息缺失（依赖链断裂、证据链模糊）。

### After（v2 候选 D — 主笔推荐，待帅哥裁决）

`override_rationale` 不再是「破例」，而是**分层密度证明**。为消除「每一段」歧义，本文采用两个可机械区分的粒度：

1. **章节级 logical unit**：由 `##` / `###` 标题、`§N` 编号章节、附录标题界定。每个 logical unit 必须说明：
   - **不能下沉**：为何不能沉到 standards / skills / tools / templates。
   - **不能省略**：删去后会断裂哪条依赖链、证据链或裁决链。
2. **段级 grammatical paragraph / structured block**：由空行分隔的散文段；表格、列表、代码块按一个 structured block 计算。凡触发超预算审查、sign-off 指出冗余、或作者主动主张 override 的超出部分，必须说明：
   - **不能压缩**：为何不能表格化、合并、删重、下沉模板化，且无重复定义、装饰性论证、空洞合规句。
3. **§J.1 仍优先**：字数不是硬上限；默认预算只触发密度证明，不自动否决。
4. 仅证明"结构重要"但不回应段级压缩信号，或仅逐段删重但不证明章节级必要性，均不足以成立 override。

违反信号：
- `override_rationale` 为空，或只有"因为超字数"。
- 只按章节证明不可省略，却回避已指出的段级可压缩点。
- 正文存在重复定义、可模板化段落、可脚本生成清单、或无信息量宣示句。
- 字数声明与机械实测不一致，导致密度证明对象不确定。

## §B 候选方案分析

- **A 双门**：优点是兼容章节级与段级；缺点是规则复杂。与 §J.1 一致，因为超预算触发证明而非硬砍。能较好消解 Antigravity/Codex 分歧。
- **B 仅章节**：优点是简洁；缺点是无法抓 D1-D7 表格化、重复句等段内冗余。与 §J.1 部分一致，但弱化"密度"。分歧消解弱。
- **C 仅段级**：优点是最严格；缺点是 override 膨胀，易变成合规仪式。与 §J.1 有张力，会把密度证明变成段落税。分歧消解强但成本过高。
- **D 三层/分层**：优点是章节证必要性、段级证压缩性，句级只建议；缺点是仍需 reviewer 判断触发段级审查。与 §J.1 最一致。分歧消解最稳。

推荐：**D**。一句话理由：它保留"不预设上限"，同时把章节级必要性和段级压缩性拆开验收。

## §C D-J1 ~ D-J4 主笔不裁决

- **D-J1 「每一段」粒度定义**
  - A 双门：覆盖完整；复杂。
  - B 仅章节：易执行；漏段内冗余。
  - C 仅段级：最严格；成本爆炸。
  - D 分层：平衡；需定义触发条件。
  - 主笔不裁决。

- **D-J2 default budget 行为**
  - A 不改 §J.1：保持"不预设上限"；需解释 default 只是触发器。
  - B 同步修 §J.1：最清楚；扩大 patch 范围。
  - C 只在 §J.2 注明：改动最小；张力仍残留。
  - 主笔不裁决。

- **D-J3 §J.2 适用范围**
  - A 仅 M-001~M-006：边界清晰；task definition 不受管。
  - B 含 task definition：一致；会追溯影响 v2 task definition。
  - C 含 ADR/standards：最广；可能过度治理。
  - 主笔不裁决。

- **D-J4 机械验证机制**
  - A 写入 §J：统一字数字段；扩大 §J.2 范围。
  - B 另设 §J.7/§J.8：结构清楚；新增章节。
  - C 不写入：轻量；继续依赖 task definition。
  - 主笔不裁决。

## §D 实施细节

- Patch line range：替换 M-005 line 461-467 的 §J.2 核心定义；违反信号保留并精化。
- 是否同步修 §J.1：仅 D-J2 选择 B 时同步；否则 §J.2 内声明"default 只触发证明"。
- 是否新增 §J.7 / §J.8：仅 D-J4 选择 B 时新增；本 patch 不主动新增。
- frontmatter 字段：无变更。

## §E 下游影响清单

- **M-003 v2 sign-off**：需重审 `override_rationale` 是否同时满足章节级不可下沉/不可省略、段级不可压缩；同时修正 5132/5328 冲突与重复行。
- **M-002/M-006/M-001/M-004 主笔**：超预算时不得只写"结构不可删"，必须回应被指出的段级压缩点。
- **task definition v2**：是否纳入 §J.2 取决于 D-J3；若纳入，需补自己的密度证明或显式豁免。

## §F Sanity check 自反性

我的 Stage 7.8 BLOCK 立场触发了本 patch；最需警惕的是把"Codex 当时的逐散文段审查"写成唯一正解。为降低合理化风险，本 patch 未选 C，而选 D：章节级保留 Antigravity 的 logical unit 解读，段级只在超预算或被指出冗余时触发。

我的 grammar-fundamentalism bias 确实会偏向散文段级；本 patch 通过"段级触发条件"而非"全段必审"降低该偏向。

主笔侧 zero-context 无 wc 工具；字数估算不作为事实，需 Claude 主分支机械校验。

## §G 主笔轮换裁决（M-005 §H 实证）

DeepSeek 同 vendor 已连续承担 M-005 v2、skill-audit-final、Stage 6.2 patch、M-003 v1、M-003 v2，共 5 版；已超过 §H "≥3 版同 vendor 主笔"轮换触发线。Codex 本次为第 1 次元规则主笔，符合轮换目的。

但 Codex 在 Stage 7.8 明显偏严格化，建议帅哥在 #021 同 PR 裁决：是否将"Codex 更高严格度权重 + DeepSeek 字数度量失真 + 主笔轮换实证"写入 user-decision-log。


---

# 输入 3/4 — M-005 §J 完整原文（精化前对比）

## §J 正向质量判据 + 字数原则升级（[#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 落地）

### J.1 核心原则：密度决定字数，不预设上限

从 M-000 第一性原理审计（[#009 R2](user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草)）到用户显式 Overrule（[#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft)），字数原则的演进路径：
- v1.2: `hard 2500 nwc`
- v2.0: `soft 2500 nwc + override_rationale`
- M-005: **无预设字数上限，正由 override_rationale 单独承载密度证明**

「不预设上限」意味着：
- 没有 `default_word_budget` 字段，没有默认值。
- 文档作者根据信息密度自然决定字数。
- 唯一约束：每一段的不可压缩性需在 `override_rationale` 证明。

### J.2 override_rationale 的正向作用

`override_rationale` 不再是「破例」，而是**密度证明**——作者必须论证：

1. **每一段不能下沉**：段落内容不可沉到下游 standards/skills/tools。
2. **每一段不能压缩**：段落中无冗余、重复、装饰性论证。
3. **每一段不能省略**：省略后会导致信息缺失（依赖链断裂、证据链模糊）。

违反信号：
- frontmatter 中 `override_rationale` 内容为空或只有「按长度需要」而无具体下沉/压缩/省略论证。
- 正文中存在明显重复定义（同一概念在不同段落被定义两次）。
- 存在可被工具脚本或模板自动生成的段落（如列举命令、模板示例）。
- 存在「形式合规但实质空洞」的段落——如「本规则很重要」「我们应当遵守」等无信息量的陈述。

### J.3 冗余检测信号（表格化）

| 信号 | 检测方法 | 严重级 |
|---|---|---|
| 重复定义 | 语义相同段落出现在不同章节 | 黄色警告，若 > 3 处则升级为红色 |
| 可下沉段落 | 段落内容完全由操作步骤或工具命令组成 | 红色（违反 §A.3） |
| 装饰性论证 | 无实质内容的描述性话语 | 黄色警告，若 > 5% 字符量则升级 |
| 形式合规但空洞 | 通过了所有 check 但产出后无实质影响（例：写了 3000 字但未解决任何用户提出的问题） | 红色（可被 sign-off 时拒绝） |

### J.4 删除代码块预算和英文译本乘数

根据 [#010](user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 和 [#014](user-decision-log.md#014-m-005-p3b-八处分歧裁决)，代码块独立预算和英文译本固定乘数不再作为默认规则保留。若未来代码块或译本过长，应由该文档自己的 `override_rationale` 或译本说明处理，不设立独立预算。

### J.5 下游脚本兼容性处理

`default_word_budget` 字段删除后，下游消费该字段的脚本可能受影响。M-005 ratify 同 PR 必须：
1. 全仓 grep `default_word_budget` 找消费点。
2. 受影响脚本同步修订（不消费该字段 / 改消费 `override_rationale` 存在性）。
3. 若发现消费点但本轮无法修订，落 user-decision-log「字数升级后续 PR backlog」条目，不阻塞本轮 ratify。
4. 按 §F.3 工程兼容性优先：若删除阻碍其他工作流，可暂保留 `default_word_budget` 字段值为 `null`（语义为「不预设」），单独 PR 完成最终删除。

### J.6 同 PR 落地路径（M-005 ratify 时执行）

**步骤 1**：修订 M-000 v2.0 §6 章节。

当前文本：
> M-000 默认正文预算为 2500 non-whitespace chars；这是可读性和冷启动成本的设计目标，不是自动否决线。超过默认预算时，frontmatter 必须写 `override_rationale`……

修订为：
> M-000 无预设字数上限。正文密度由 frontmatter `override_rationale` 单独承载——作者必须在该字段中证明正文每段的不可下沉性、不可压缩性和不可省略性。代码块、译本等不单独设立预算，由同一密度证明覆盖。

**步骤 2**：删除 M-000 v2.0 frontmatter 中的 `default_word_budget: 2500` 字段。

**步骤 3**：在 `user-decision-log` 录入新条目，显式 Overrule [#009](user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R2 处理方式：

```


---

# 输入 4/4 — 收尾指令

基于以上 3 份输入，独立完成 sign-off。仅输出 markdown，无任何 commentary。
