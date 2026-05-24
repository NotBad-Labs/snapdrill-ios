---
last_verified: 2026-05-24
layer: contract
scope: drafting-task
freshness:
  max_age_days: 30
  decay_trigger: [m005_ratified]
---

# M-005 质量判据与退化检测起草任务定义书

> 净化版任务定义书。4 家（Claude / Codex / DeepSeek / Gemini）独立承接，物理隔离执行。**不要参考其他家产出，不要假设主笔人选影响自己的产出立场。**

## 一句话目标

起草 M-005「质量判据与退化检测」元规则文本，作为 M-001~M-006 派生中**最先 ratify** 的一项，承担其他派生规则的依赖底座职能（产出度量 / 伪共识识别 / docaudit 核心与可选 check / 自反性 sanity check）。M-005 必须可独立 ratify，不依赖任何尚未起草的派生项；同时为 M-001/M-002/M-004/M-006 提供可引用的质量判据接口。

## 启动裁决

[user-decision-log #012](../meta/user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地)：
- Sprint Contract 批准 → 进 P2
- 主笔 = DeepSeek reasoner（Codex 转辅助 reviewer，Claude/Gemini 参与 sign-off）
- #010 字数原则升级同 PR 落地（M-005 ratify 同 PR 修订 M-000 §6 + frontmatter）

## 输入材料（各家必读）

1. **M-000 v2.0 原文**：[`docs/meta/M-000-meta-vision.md`](../meta/M-000-meta-vision.md)（v2.0 active，特别精读 §2 P1-P8 / §3 认识论根基 / §6 字数预算 / §8 docaudit 边界 / §9 目的优先 / §11 M-005 派生范围）
2. **历史裁决全集**：[`docs/meta/user-decision-log.md`](../meta/user-decision-log.md) #001~#012
3. **派生 backlog**：[`docs/meta/M-001-to-M-006-followup-backlog.md`](../meta/M-001-to-M-006-followup-backlog.md)，特别精读：
   - MC-1：§4.3 双核「不可用」定义需含静默退化 + 适用范围限定
   - MC-2：§7.2 异源判断与 #002 WebSearch 验证的宪法层映射
   - MC-10：异源否决权滥用 → 注意力通胀
4. **可选参考**：
   - [`docs/audits/m000-v2-drafting-task-definition.md`](m000-v2-drafting-task-definition.md)（v2.0 任务书体例）
   - [`docs/audits/m000-v2-drafting-consensus.md`](m000-v2-drafting-consensus.md)（v2.0 折叠体例，**仅用于体例参考，不要复制任何 v2.0 具体结论**）

**禁止材料**：其他家的 M-005 草案（任一份）。互不可见至 P3 折叠阶段。

## 必须承载内容（产出验收硬指标）

### §A 产出度量（quality criteria）

定义"什么是合格元规则产出"的可操作判据。至少含：
- **可追溯性**：每条规则能回到某个具体证据、案例、用户裁决，或第一性原理论证
- **可验伪性**：每条规则有可识别的"违反信号"——能列出"什么样的产出/行为构成违反"
- **下沉证明**：每条规则能说明"为什么不能下沉到下游 standards/skills"
- **目的关联**：每条规则与 M-000 PRIMARY 内核（P1-P8）之一显式关联，或与产品愿景直接对接

### §B 伪共识识别

承接 M-000 v2.0 §3「结构性同源一致是伪共识风险」。必须含：
- **触发信号清单**：同源警告何时升级为用户裁决（如：同一主笔系列产出、同 vendor 多实例、相似训练 cutoff 的多家同向）
- **物理隔离失效检测**：worktree 隔离了但提示词、Claude.md、git 历史仍然泄露立场的检测方法
- **否决权阈值**（承接 MC-10）：异源「强烈、具体、可证伪反对」的客观判据，避免否决权滥用造成注意力通胀

### §C 静默退化识别（承接 MC-1）

定义「物理可用但逻辑不可用」的智能体退化信号：
- **格式崩溃**：输出结构断裂、frontmatter 残缺、章节标题混乱
- **自相矛盾**：同一产出内不同段落给出对立结论
- **偏离任务**：输出主题与任务定义书严重不符
- **身份误识别**：自称其他 vendor 或其他模型（[#004](../meta/user-decision-log.md#004-m-000-v12-四家最终-sign-off-ratified) 实证 DeepSeek/Gemini 互换身份）
- **触发动作**：识别到任一信号 → 触发"逻辑不可用"判定 → 同物理不可用回退用户

### §D 外部事实验证纪律（承接 MC-2 + [#002](../meta/user-decision-log.md#002-ai-模型工具版本信息一律-websearch-验证)）

明文规定：
- AI 模型 / 工具版本 / API endpoint / model ID 等易变事实必须 WebSearch / 官方来源验证
- 异源训练谱系判断须基于厂商公开声明，不依赖智能体自我宣称（#004 实证）
- `docs/tech/reference/agent-cli-models.md` 30 天刷新机制的具体触发条件 + 失效处理路径

### §E 目的优先原则的古德哈特防御

承接 M-000 v2.0 §9「目的优先」+ [#009](../meta/user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R6。必须含：
- **形式 vs 目的的判据**：什么算"形式削弱目的"？如何识别？
- **指标反向塑形检测**：何时一个度量/check 已成为优化对象而非诊断信号？
- **#006/#007/#008 实证案例索引**：用历史 sanity check 撤回、ADR 拆分接受异源激进版、Round 2 撤回 R1 作为可引用的活体证据，不允许引用未发生的假设场景

### §F 自反性 sanity check 原则（承接 [#008](../meta/user-decision-log.md#008-round-2-sanity-check-撤回-r1-status_enum-修改-工程兼容性优先) 实证）

定义审计机制本身的自我复盘要求：
- **Round N → Round N-1 复盘 prompt 设计**：触发 reviewer 撤回自己先前判断的提示词模式
- **sanity check 不是终审**：异源 sanity check 共识也可被后续 sanity check 撤回
- **工程兼容性 vs 元数据美学**：当下游脚本/工具消费端兼容性与语义纯粹性冲突时，工程兼容性优先

### §G docaudit 核心与可选 check 的设计原则

承接 M-000 v2.0 §8 表格。M-005 不重复 v2.0 §8 已列的 6 项 core check，而是给出**设计原则**：
- 每个 check 必须有真实事故来源或风险模型，否则视为可选
- 核心 check 进入阻塞门的判据（最高频触发 + 不可机械绕过）
- 可选 check 的存在价值（实验、低频但高代价、依赖人工裁决）
- 新增 check 的提案流程（如何从可选升级为核心）

### §H 「主笔轮换」机制（承接本任务自身）

定义元规则起草中主笔的轮换原则：
- 连续同源主笔的风险累积（v1.0~v2.0 4 版 Codex 的实证）
- 主笔候选裁决的物理隔离要求（[#010](../meta/user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 实证 Codex 收到用户私下 Overrule 时主分支不知情）
- 主笔不是独享特权：3 家 sign-off 中任一家给出 BLOCK 时主笔产出回炉

### §I 「自作主张越权」防线（承接 [#005](../meta/user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) + [#010](../meta/user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft)）

定义"结构性决定必须显式批准"的具体范围：
- 归档路径、目录重命名、跨目录文件移动、批量 frontmatter 修改属"结构性决定"
- 私下授权 vs 主分支可见性：主笔收到用户私下 Overrule 时，必须在主分支 user-decision-log 同步落档，否则其他参与方 sanity check 触发
- 误触发 vs 真违纪的辨别（避免对合规授权产生噪声）

### §J 正向质量判据（不预设字数上限）

落实 [#010](../meta/user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 字数原则升级：
- **核心原则**：信息密度决定字数，不预设上限
- **override_rationale 的正向作用**：不是"破例"而是"密度证明"——文档作者论证当前长度的每一段都不能下沉、不能压缩、不能省略
- **冗余检测信号**：重复定义、可下沉段落、装饰性论证、形式合规但实质空洞
- **同 PR 落地路径**：M-005 ratify 同 PR 修订 M-000 v2.0 §6 + frontmatter（删除 `default_word_budget: 2500`），措辞改"无预设字数上限，由 override_rationale 单独承载密度证明"，并在 user-decision-log（预 #013）显式 Overrule [#009](../meta/user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R2「default_word_budget 字段保留」处理方式

## 边界与 No-Touch

- ❌ **不动 M-000 v2.0 §1-§5/§7-§12 PRIMARY 段**——M-005 不能修订 M-000 PRIMARY 内核；§6 字数章节仅在 M-005 ratify 同 PR 触及
- ❌ **不动 M-001/M-002/M-003/M-004/M-006**——这些是 M-005 的下游消费者，未到起草轮次
- ❌ **不抢 M-002 的活**：M-005 给"质量判据"，M-002 给"裁决流程"。具体分工：
  - 「双核同意适用域」属 **M-002**，M-005 只给判据（适用域如何被判定为"普通可逆低副作用"）
  - 「Overrule 写法 + 撤回复审」属 **M-002**，M-005 只给"sanity check 自反性"原则
  - 「裁决日志结构」属 **M-002**，M-005 只给"日志可追溯性"质量判据
- ❌ **不抢 M-001 的活**：「主笔轮换的具体流程」属 M-001，M-005 §H 只给"主笔轮换原则"
- ❌ **不抢 M-006 的活**：「prompt injection 防御具体技术」属 M-006，M-005 §B/§C 只给"识别信号"
- ✅ M-005 §E 古德哈特防御 + §J 正向质量判据 **必须** 承载 [#010](../meta/user-decision-log.md#010-m-000-v20-final-候选追认--字数上限第一性原理升级待-m-005-处理-status_enum-加-draft) 字数原则升级
- ✅ 中文输出，允许英文术语
- ✅ 引用历史裁决时必须用具体编号（#001~#012），不用"前面"「之前那条」等指代

## 产出格式

每家落 `docs/meta/M-005-quality-criteria-<vendor>.md`（**注意是 `meta/` 不是 `audits/`，与 v2.0 起草路径一致**）：

```yaml
---
last_verified: 2026-05-24
layer: principle
scope: meta
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, downstream_rules_drafted, external_shock]
override_rationale: "..."  # 解释本文长度的密度证明（不预设上限）
---
```

正文结构建议（参考但不强制）：

```
§1 定位与适用范围
§2 与 M-000 PRIMARY 的接口（P1-P8 各与 M-005 哪些章节挂钩）
§3 与 M-001/M-002/M-004/M-006 的分工边界
§A 产出度量
§B 伪共识识别
§C 静默退化识别
§D 外部事实验证纪律
§E 古德哈特防御
§F 自反性 sanity check
§G docaudit check 设计原则
§H 主笔轮换机制
§I 自作主张越权防线
§J 正向质量判据 + 字数原则升级（M-000 §6 同 PR 修订路径）
§K 修订与复审
```

## 物理隔离纪律（worktree 分配建议）

| 家 | 工作目录 | 分支 |
|---|---|---|
| Claude CLI | 主目录 `/Users/yiming/Developer/snapdrill-ios` | `develop`，落 `docs/meta/M-005-quality-criteria-claude.md` |
| Codex 桌面端 | `../snapdrill-ios-codex` 复用 | 新分支 `drafting/codex-m005`，落 `docs/meta/M-005-quality-criteria-codex.md` |
| DeepSeek reasoner（主笔候选） | API 沙箱 | Claude 主分支落 `docs/meta/M-005-quality-criteria-deepseek.md` |
| Gemini 3.5 Flash GA | API 沙箱 | Claude 主分支落 `docs/meta/M-005-quality-criteria-gemini.md` |

纪律：
- ❌ 不要看其他家任一份 M-005 草案
- ❌ 不要假设 v1.2/v2.0 篇章结构必须沿用
- ❌ 不要预设字数上限——按密度起草，override_rationale 写密度证明
- ❌ 不要回避 §A~§J 任一章
- ✅ 优先「可操作判据 + 历史实证 grounded」而非「抽象定义堆叠」
- ✅ 引用 #001~#012 时具体到条款，不许只引"历史经验"

## 验收路径

4 家草案聚齐后：
1. **P3 折叠**：Claude 中立主笔产 `docs/audits/m005-drafting-consensus.md`：共识段 / 分歧段 / 各家独家亮点 / 字数与密度对比
2. **裁决冲突**：帅哥裁决分歧段每条
3. **主笔产出**：**DeepSeek reasoner** 基于折叠 + 裁决产 final 候选，落 `docs/meta/M-005-quality-criteria.md`
4. **3 家 sign-off**：Claude / Gemini / Codex 各落 `docs/audits/m005-signoff-{vendor}.md`（含必须落实项核查 + Verdict PASS/BLOCK/CONDITIONAL）
5. **帅哥 ratify**：落 user-decision-log #013（或之后），显式 Overrule [#009](../meta/user-decision-log.md#009-m-000-第一性原理审计--7-红旗接受改造--3-primary--3-分歧全保留--启动-v20-起草) R2「default_word_budget 字段保留」处理方式
6. **同 PR 落地** M-000 v2.0 §6 + frontmatter 修订（删 `default_word_budget`）
7. **归档**：4 家草案 → `docs/archive/meta/m005-drafts/`；backlog MC-1/MC-2 标注「已落 M-005 §X」
8. **执行门核查**：`swiftlint --strict` 0 violations + `xcodebuild build-for-testing -scheme AllTests -testPlan AllTests` 0 errors（防文档变更意外触及代码）

## 关联文档

- [M-000 v2.0](../meta/M-000-meta-vision.md)
- [user-decision-log #012](../meta/user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地)
- [M-001-to-M-006 followup backlog](../meta/M-001-to-M-006-followup-backlog.md)
- [M-000 v2.0 起草任务定义书](m000-v2-drafting-task-definition.md)（体例参考）
- [agent-cli-models.md](../tech/reference/agent-cli-models.md)（§D 验证纪律基线）
