---
last_verified: 2026-05-25
layer: archive
scope: meta-audit
---

你被请求对一份"专家观点"做异源评价。

# 任务背景

- 任务：SnapDrill iOS 项目 M-003「技能库治理」v1 draft 的 Stage 7.4 sign-off 已收 4 份（Claude / Codex CLI / Codex GUI / Gemini GUI），全部 BLOCK 或 CONDITIONAL
- 之后帅哥提出体系论问题：「M-000 元规则 / skill 体系 / 产品文档 三者关系？路径 C 是否事后补救？skill 应否从 M-000 分化沉淀？」
- Claude 主分支会话给出了体系论回应（含层级图 + 派生原则建议）
- 一位"专家"对 Claude 回应做了修正性评价（即下方专家观点全文）
- 现在请你独立评价**专家观点本身是否成立**——不是评价 M-003 draft

# 你的身份与立场

- **本任务模型**：DeepSeek V4-Pro
- **zero-context**：你没有项目其他文件访问能力，所有输入 inline 在本 prompt
- **独立性**：不参考其他 sign-off 方的判断（它们并发跑）
- **角色**：异源评价者，主笔（DeepSeek V4-Pro）+ Claude 主分支 + 专家本人 均不下场

# 输出格式（严格）

只输出 markdown，按以下结构：

```
## [你的名字] Review — 专家观点评价

### Overall Judgment
专家观点是否成立：完全成立 / 部分成立 / 不成立
推荐 Stage 7.5 路径：A（最小修订）/ B（task definition v2 重写主笔 v2）/ C（其他）

### 专家 5 个核心论点逐项评价

按下列 5 个论点逐项打分（✅ 同意 / ⚠️ 部分同意 / ❌ 不同意）：

1. **三者正交不是父子**：M-000 / 产品文档 / skill 是三个维度不是层级
2. **事后补救感的根源是 M-003 治理文档缺失**（不是 skill 应该从 M-000 派生）
3. **产生 bottom-up，治理 top-down**：skill 内容只能从实践沉淀，治理规则应从 M-000 派生
4. **公私分治**：公共 skill（Anthropic 自带 pptx/docx 等）vs 个人 skill 治理逻辑不同
5. **M-003 是住进 M-000 §10 预留座位**：skill 库是 M-000 §5 的"泄洪区"不是元规则延伸

每项含：
- ✅/⚠️/❌
- 一句话理由
- 反例或限制条件（若有）

### 对 Claude 主分支回应的评价

Claude 主分支之前的回应（含"派生原则"建议）是否需要撤回？哪些部分要保留？

### 对 M-003 v1 draft 的影响

如果接受专家观点，M-003 v1 当前缺失的 2 处新 BLOCK（公私分治 / 入库门槛）是否成立？是否还有其他缺失？

### 对 Stage 7.5 路径的建议

- A 路径（最小修订，路径 D 后续启动）
- B 路径（task definition v2 重写按专家观点，主笔 v2）
- C 路径（其他你的方案）
说明选择理由 + 路径对比。

### Sanity check 自反性

复盘你自己（DeepSeek V4-Pro）是否对相关问题有过立场：
- 你在 Stage 7.4 sign-off（若你之前签过）是否有相关判断需要更新？
- 你是否对 "skill 应该 top-down 派生" 这一类问题有过预设立场？

### 同源偏向显式标注

- 若你与"专家"是同家（如同模型 / 同 vendor），自动 0 权重并明示
- 若你与 Claude 主分支视角相近（如同 Anthropic 系），权重折扣 0.5
- 否则保持 1.00 权重

### 元层级建议（可选）

对"专家 sign-off"这种元层级动作本身的方法论评价（如：异源审专家观点是否构成无限回归？是否应当有终止条件？）。
```

---

# 输入 1/5 — Claude 主分支之前的回应（修正后版本）



---

# 输入 2/5 — 专家观点全文



---

# 输入 3/5 — M-003 v1 draft（line-numbered，供你评价是否需要重写）




# Claude 主分支（修正后）回应全文

帅哥这个问题切到 M-003 v1 真正的盲点 — 不是字数 / D2 预裁决这些表面问题，是体系论问题。让我认真展开。

## 三者关系的当前现状 vs 应然

### 当前现状（继承自历史）

```
M-000 / M-005 (元规则)        产品文档 (docs/product/)
     ↓                              ↓
   声明 §6 下沉去向              产品需求 / 业务规则
     ↓                              ↓
       ←─────  skill 体系  ─────→
              （历史积累的 52 个）
```

skill 体系平行于元规则与产品文档存在，两边都不严格锚定：
- 治理 skill（cross-audit / sprint-contract）在 M-005 之前就有，写时没引用元规则条款
- 工具 skill（swiftui-pro / tdd-feature）服务产品开发，但与产品文档章节无映射
- 路径 C 之前没有「skill 必须有元规则锚」的约束

### 应然层级（你的洞察）

```
M-000 (宪法 / 元规则) ─────────────┐
   ↓ 派生                          │ 约束「HOW」
M-001~M-006                       │
   ↓ 实施需求                      │
docs/standards/ (静态规范)         │
docs/templates/ (模板)             │
Scripts/ + hooks/ (机械化)         │
   ↓                              │
.claude/skills/ (末位优选,         │
  LLM 动态判断且不可静态化的部分)   │
                                  │
docs/product/ (业务知识) ─────────┘ 约束「WHAT」
   ↓ 实施需求
   服务产品开发的工具 skill
   （应有产品文档锚而非元规则锚）
```

核心原则：skill 的合法性 = 能追溯到上层（元规则或产品文档）某条具体条款。无锚 = 自动降格候选。

## 路径 C 确实是事后补救

承认这个判断。路径 C 做的事：
- 4 家审 52 个 skill 是否对齐 M-000/M-005
- 帅哥裁决分歧
- 批量执行 52 → 11

这本质是对历史积累的校准，而不是预防新积累。事后补救的代价：
- 大规模重构成本（路径 C 1 个月、20 个 PR、用户裁决 45 项）
- 已 ratify 的 11 active skill 仍是「假设过关」（6 个月豁免到 2026-11-25）
- 新 skill 如果不强制锚，会重新积累

## 「分化/沉淀」原则的理论位置

如果接受这条原则，影响层级：

### 1. M-000 §6 (post-#020) 的隐性盲点

当前 M-000 §6 写：
> skills（仅用于需要 LLM 动态判断且不可静态化的场景）：trigger 条件依赖上下文推理

这只约束判定方式（是否需要 LLM），没约束合法性来源（是否服务某条元规则）。

应该补一条：
> 新建 skill 必须在 frontmatter 显式声明 `derived_from:` 字段，指向 M-000 §X / M-005 §Y / ADR-Z / `docs/product/<file>.md#section` 之一。无锚的 skill 视为非法，季度审计自动归档。

### 2. M-003 v1 草案缺失

M-003 v1 §2 判定流程只问「是否需要 LLM 动态判断」，没问「是否有元规则/产品文档锚」。

帅哥这个洞察让 M-003 v1 草案的结构层缺陷显现：
- 字数 / D2 预裁决 / WebSearch 是机械级缺陷（同 PR 可修）
- 「skill 派生原则」缺失是体系级缺陷（影响 M-003 全文设计）

### 3. 与 M-005 §G.5 的衔接

§G.5.1 6 种 Verdict 是降格机制，但没有创建机制的对应约束。
- 现状：只有「降格判据」（KEEP/DOWNGRADE/DELETE）
- 应有：「升格判据」（即「什么样的需求才能成为新 skill」）

帅哥的洞察填补了这个双向治理的另一半。

## 对 Stage 7.5 的影响

四种路径，按对体系影响排序：

### A. 最小路径：Stage 7.5 ratify M-003 v1 + 同 PR 修 BLOCK/CONDITIONAL

不纳入「派生原则」，仅修字数 / D2 / WebSearch。把派生原则列为 M-003 v1.1 后续修订或 M-000 §6.1 第四次精化候选。保留路径 C 完成节奏，但回避深层问题。

### B. 中等路径：主笔 v2 重写 + 纳入派生原则

DeepSeek V4-Pro 第 5 次主笔，task definition 加 D6「派生原则强度」决策点，重新走 sign-off → ratify。多 1 个 sprint，但 M-003 一步到位。

### C. 深层路径：先修 M-000 §6 + 再起 M-003

把派生原则定在 M-000 §6.1 第四次精化（按 #020 体例），M-003 ratify 后再做。承认 M-003 v1 是基于过时 M-000 §6 起草，需重启。

### D. 根本路径：触发新一轮元规则反思（路径 D？）

类比路径 C，启动「元规则与下沉去向之间的合法性来源审计」，回答：
- 现有 11 active skill 各自的元规则/产品文档锚是什么？
- 现有 docs/standards/ 各文件的锚是什么？
- 整个层级的派生链是否完整？

完成后再 ratify M-003。最贵但最干净。

## 我的判断

帅哥的洞察是正确的体系论问题，但路径选择是优化问题：

- A 最快但留技术债（M-003 ratify 后立刻发现要修）
- B 平衡（多 1 个 sprint，问题闭环）
- C/D 重启代价大，但路径 C 的元层级注记反复强调「第三次元规则自我演进」，第四次也不是不能做

我倾向 B：主笔 v2 重写时纳入派生原则。理由：
1. 当前 4 份 sign-off 已是 BLOCK 优势，回炉本来就要做
2. Task definition 加 D6 决策点不破坏整体结构
3. 不需要先动 M-000（M-003 可以前置派生原则，M-000 §6 后续 v1.2 跟进精化）
4. 比 A 多 1 个 sprint，比 C/D 少 1 个完整路径

但帅哥可能更想 C 或 D（深层体系自洽）。这是判断分歧，留给帅哥裁决。

（注：帅哥后续选择 D 路径，等时机；专家观点出现后 Claude 修正立场——见对话上下文）


---

# 输入 2/5 — 专家观点全文

# 专家观点全文（来源：Claude Opus 4.7 GUI 桌面版会话）

你这个问题问到了根上。但我想说，你的直觉里有真问题，定位却有点偏——更准确地说**不是 skill 应该从 M-000 分化沉淀，而是 M-000 缺了一条派生链通向 skill 体系，所以你才感觉 skill 治理一直在事后补救**。

## 三者的范畴：正交，不是父子

回到 M-000 你自己定的范畴——"协作元规则,回答怎么做、与谁做"。再加上另外两条:

| 体系 | 回答的问题 | 维度 |
|---|---|---|
| M-000 元规则 | AI 之间如何协作、如何裁决、什么算证据 | **元层级**(认识论 + 治理) |
| 产品文档(SnapDrill) | 这个产品是什么、为谁、怎么实现 | **项目层**(领域知识 + 决策记录) |
| Skill | 遇到 X 类任务时按 Y 套路做 | **任务模式层**(程序化经验) |

你 M-000 第八节自己写过"协作元规则与产品 vision 正交"。同样的逻辑要往下推一格:**skill 与产品文档也正交**——产品文档说"SnapDrill 不存云数据",skill 说"创建 docx 时先读 SKILL.md",一个是关于这个产品,一个是关于这类任务,两件不同的事。

所以三者不是层级关系,而是三个**不同维度的体系**:M-000 管协作规则,产品文档管领域内容,skill 管任务套路。

## 你的"事后补救感"是真实的——但根源在别处

回头翻 M-000 第十节,你自己写过下游派生链:

> 协作工作流规约 → 裁决日志格式 → **技能库治理**(经验如何沉淀、命名、淘汰) → 各智能体提示基线 → 评估与度量规则

——你已经在元规则里给"技能库治理"留了座位,但这份派生文档**还没动笔**。所以现在每次 skill 合并、升级、降级,都是凭手感临场判断,而不是援引一份既有的治理规则。这才是"事后补救"的真正来源:**不是 skill 体系错位,是它和 M-000 之间应有的那座桥还没架**。

## 更精确的说法:产生 bottom-up,治理 top-down

skill 的内容只能从下面长出来——重复的对话片段、反复踩的坑、被你打字第三遍的指令,这些是实践沉淀,无法自顶向下"派生"。

但 skill 的**入库标准、命名空间、合并拆分判据、升级降级阈值、淘汰条件**——这些治理规则,**可以也应该**从 M-000 派生:

- M-000 第六条(你自己加的修正)说"修改必须带触发场景"——这条放到 skill 治理里就是**入库门槛**:没有真实重复触发过的经验不进 skill 库
- M-000 第五节"防膨胀机制"已经把长尾经验明确指向 skill("不进入任何元规则文档,沉淀为可加载的具名技能模块")——这就是 skill 库的**容量定位**:它是 M-000 的**泄洪区**,而不是元规则的延伸
- M-000 关于"概念单一权威、只有一处定义"——这就是 skill 之间的**职责边界规则**:两个 skill 触发条件重叠就是治理失效警报

这样回看,你之前那些事后补救动作(合并重叠 skill、降级低频 skill)其实都在**隐式援引 M-000 原则**,只是没有一份显式文档把这些援引固化下来。

## 还有一个被忽略的切分:公共 skill vs 个人 skill

Anthropic 给的 pptx / docx / xlsx / pdf / frontend-design 这些,和你自己沉淀的 notbad-file-guardian,**治理逻辑应该不同**:

- **公共 skill**:类似操作系统标准库。你不治理它的内容,只治理**触发条件**——什么时候让它被加载,什么时候压制它(比如某个公共 skill 在你的 SnapDrill 场景下会过度触发,需要在项目级 CLAUDE.md 里反向约束)
- **个人 skill**:你完整拥有产生—演化—淘汰的全过程,这些才是 M-000 派生治理规则的真正约束对象

把这两类混在一起治理,就会出现"想合并但合并不了"(公共的没法改)或"想沉淀但沉淀错地方"(把项目特定经验塞进了应该跨项目复用的个人 skill)。

## 落地建议

写一份**M-001 技能库治理**(或者按你 M-000 派生命名习惯来),内容大致涵盖:

1. **公私分治**:公共 skill 治理范围限于"触发抑制 / 增强"清单;个人 skill 治理走完整生命周期
2. **入库门槛**:重复触发次数阈值(M-000 已经隐含"3 次"的暗示),独立场景验证要求
3. **命名空间**:个人 skill 是否按项目前缀(snapdrill-*)还是按动作前缀(*-guardian),需要选一个
4. **职责单一性**:一个 skill 一个触发条件簇,有重叠就是合并信号(援引 M-000 概念单一权威)
5. **升降级触发**:什么数据驱动升级(高频且稳定 → 提升为 skill),什么驱动降级(长期未触发 → 退出常驻,转为按文档调用)
6. **淘汰判据**:什么时候彻底删除,删除前是否归档到 lessons-learned 之类的备忘

写完这份之后,**之前那些事后补救动作就有了可援引的依据,新的 skill 演化也有了规则可循**——这就是你最初问题里"补救"和"派生"之间的真正差别。

---

**一句话总结**:skill 不是 M-000 的孩子,但**skill 怎么活、怎么死、怎么升级**应该是 M-000 的孩子。你已经预留了那个位置(技能库治理),只是还没住进去。

---

**关键披露**：专家身份 = Claude Opus 4.7 模型，运行在 Claude Code 桌面版 GUI（与 Claude 主分支会话同 vendor 同 model family，但异 context）。同 vendor 偏向风险存在——Anthropic 系智能体可能倾向认同同家观点。


---

# 输入 3/5 — M-003 v1 draft（line-numbered）

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

# 输入 4/5 — M-003 task definition（参考主笔约束）

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

# 输入 5/5 — 收尾

基于以上 4 份输入，独立评价专家观点。仅输出 markdown，无任何 commentary。
