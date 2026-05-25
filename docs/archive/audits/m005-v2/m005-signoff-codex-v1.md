---
last_verified: 2026-05-25
layer: snapshot
scope: signoff
freshness:
  max_age_days: 30
  decay_trigger: [m005_ratified, source_changed, user_decision_recorded]
---

# M-005 Final Sign-off - Codex GPT-5

## Verdict

**BLOCK**。

理由：`docs/meta/M-005-quality-criteria.md` 已覆盖主体结构，但仍有多处硬输入未落实或相互冲突。尤其是 #014 D5 的升级阈值被正文写成更严且逻辑不同的条件，§D 未吸收 #013 三层错实证，§E 实证索引缺 #009/#010，且 §C.4 对身份误识别的硬阻塞写法与 #014 D8 的“不强制阻塞”冲突。以上不是措辞偏好，属于 ratify 前必须修正的硬约束偏差。

隔离说明：本审只读取指定输入与 Action Gate 所需 `docs/protocol.md`；未读取 `docs/audits/m005-signoff-claude.md` 或 `docs/audits/m005-signoff-gemini.md` 内容。

## 必须落实项核查

| 项 | 结论 | 依据 |
|---|---:|---|
| §A 产出度量 4 项 + Verdict 三分制 | ✓ | 候选 §A 明确“缺任一项 -> CONDITIONAL；缺两项以上或关键条款不可验伪 -> BLOCK”（`docs/meta/M-005-quality-criteria.md:67`），并逐项定义可追溯、可验伪、下沉证明、目的关联（`docs/meta/M-005-quality-criteria.md:69-97`）。 |
| §B.3 否决权三要素 + #014 D1 | ✓ | 三要素完整落地（`docs/meta/M-005-quality-criteria.md:132-135`），D1 阈值“24 小时内 >=3 次且至少 2 次不满足三要素”落地（`docs/meta/M-005-quality-criteria.md:137`）。 |
| §C 四信号 + §C.5 prompt injection + §C.6 D6 | ⚠️ | 四信号、prompt injection、硬信号 vs 局部退化、sign-off 立即暂停均已写入（`docs/meta/M-005-quality-criteria.md:145-183`），但 §C.4 把身份误识别写成“单次即逻辑不可用”（`docs/meta/M-005-quality-criteria.md:163-167`），与 #014 D8 的不强制阻塞冲突。 |
| §D 外部事实验证（#002 + 30 天刷新 + #013 三层错实证） | ✗ | #002 和 `agent-cli-models.md` 30 天刷新已覆盖（`docs/meta/M-005-quality-criteria.md:187-211`），但正文未引用 #013，也未落“subagent 返回 model ID/API endpoint 必须 grep SSOT 验证、SSOT 与消费代码同步刷新”的三层错实证要求（#013 要求见 `docs/meta/user-decision-log.md:196-201`）。 |
| §E 古德哈特防御（#006/#007/#008/#009/#010 实证索引，禁假设场景） | ✗ | §E.3 只列 #006/#007/#008（`docs/meta/M-005-quality-criteria.md:234-240`），漏掉折叠共识要求的 #009/#010 实证索引（`docs/audits/m005-drafting-consensus.md:67-71`）。 |
| §F + #014 D4 | ✓ | Round N -> N-1 复盘、sanity check 非终审、工程兼容性优先均已写入（`docs/meta/M-005-quality-criteria.md:244-263`），并保留 P2/P8 例外（`docs/meta/M-005-quality-criteria.md:263`）。 |
| §G + #014 D5 + 退役原则 | ✗ | 同步消费端文档、180 天降级、退役原则已写入（`docs/meta/M-005-quality-criteria.md:298-302`），但升级条件偏离 #014 D5：正文 G.2 写“误报率 <10%”（`docs/meta/M-005-quality-criteria.md:279-283`），G.4 写“>=3 次审计运行（或 30 天）”（`docs/meta/M-005-quality-criteria.md:297`）；#014 D5 裁决是“>=3 次审计 + 30 天 + 误报率 <20%”（`docs/meta/user-decision-log.md:211`）。 |
| §H + #014 D2/D3 + §H.4 | ✓ | 连续同源主笔 >=3 版落地（`docs/meta/M-005-quality-criteria.md:313`），私下授权同步不给硬时限并下沉 M-001（`docs/meta/M-005-quality-criteria.md:318`），§H.4 衔接同 PR 修订写入（`docs/meta/M-005-quality-criteria.md:328-330`）。 |
| §I + #014 D7 | ✓ | 三分、三种处置、§I<->§H 联动、PR 作废均落地（`docs/meta/M-005-quality-criteria.md:352-361`）。 |
| §J 字数原则升级 + M-000 §6/frontmatter 目标 + Overrule #009 R2 + §J.4/§J.5 | ⚠️ | M-005 正文方案完整：无预设上限、删除 `default_word_budget`、删代码块预算/译本乘数、下游脚本兼容性、#009 R2 Overrule 写法均写入（`docs/meta/M-005-quality-criteria.md:367-434`）。但当前 `docs/meta/M-000-meta-vision.md` 仍保留 `default_word_budget: 2500` 和旧 §6 文本（`docs/meta/M-000-meta-vision.md:10`、`docs/meta/M-000-meta-vision.md:75`），ratify PR 不能漏掉同 PR 修订。 |
| #014 D8 thinking/reasoning 0.5 权重折扣，不强制阻塞 | ✗ | §B.1 已写“建议折扣 0.5，不强制阻塞”（`docs/meta/M-005-quality-criteria.md:112`），但 §C.4 同时写身份误识别“一次即可触发逻辑不可用”（`docs/meta/M-005-quality-criteria.md:166`），正文内部冲突。 |

## 强反对

### 1. #014 D5 阈值被改写

- **具体事实错误**：#014 D5 裁决为“>=3 次审计 + 30 天 + 误报率 <20%”（`docs/meta/user-decision-log.md:211`），候选 G.2/G.4 实际组合为“误报率 <10%”且“>=3 次审计运行（或 30 天）”（`docs/meta/M-005-quality-criteria.md:279-297`）。
- **可证伪反假设**：若正文改为“经过 >=3 次审计运行 + 至少 30 天观测 + 误报率 <20% + 消费端文档同步”，则与 #014 D5 一致；否则任何 reviewer 可逐字比对 #014 D5 判定不一致。
- **明确风险路径**：阈值收紧到 <10% 会让本应可升级的 check 被无授权延后；“或 30 天”又允许未满 3 次审计的 check 过早升级。二者都会破坏 §G 作为阻塞门设计原则的可追溯性。

### 2. §D 漏掉 #013 三层错实证

- **具体事实错误**：任务要求 §D 包含 #013 三层错实证；#013 明确记录“未强制注入 SSOT、subagent 报告 model ID 未 grep SSOT、代码 SSOT 与文档 SSOT 不同步”（`docs/meta/user-decision-log.md:196-201`）。候选 §D 只覆盖 #002、外部源、30 天刷新和失效处理（`docs/meta/M-005-quality-criteria.md:187-211`）。
- **可证伪反假设**：若 §D 增加“调度方必须注入 `agent-cli-models.md`、subagent 返回模型/endpoint 必须 grep SSOT、消费 SSOT 的代码必须同步刷新”，则 #013 三层错被覆盖；当前文本 grep `#013` 无命中。
- **明确风险路径**：缺 #013 会让 M-005 自身刚暴露的 Gemini 2.5/3.5 误用事故不能转化为判据，后续仍可能把 subagent 自报 model ID 当事实并污染折叠输入。

### 3. §C.4 与 #014 D8 互相打架

- **具体事实错误**：#014 D8 裁决为 thinking/reasoning 模式下身份误识别时“建议折扣 0.5，不强制阻塞”（`docs/meta/user-decision-log.md:211`）；候选 §C.4 写“判定：硬信号。一次身份误识别即可触发逻辑不可用”（`docs/meta/M-005-quality-criteria.md:163-167`）。
- **可证伪反假设**：若 §C.4 改为区分“身份误识别作为退化信号”与“thinking 模式下按 D8 先做 0.5 权重折扣，非自动 BLOCK”，则 §B.1 与 §C.4 一致。
- **明确风险路径**：保留当前冲突会让 sign-off 执行时无法判断：同一身份误识别到底是折扣继续、暂停 sign-off，还是直接逻辑不可用，导致 M-005 的退化检测规则在首个案例上自相矛盾。

### 4. §E 实证索引漏 #009/#010

- **具体事实错误**：P3 共识要求 §E 历史实证索引包含 #006/#007/#008/#009/#010（`docs/audits/m005-drafting-consensus.md:67-71`），候选 §E.3 只列 #006/#007/#008（`docs/meta/M-005-quality-criteria.md:234-240`）。
- **可证伪反假设**：若 §E.3 增加 #009 第一性原理审计识别 M-000 非第一性外壳、#010 字数默认值被进一步识别为非第一性惯性的实证，则满足输入清单。
- **明确风险路径**：缺 #009/#010 会削弱 §E/§J 的证据闭环，使“无预设字数上限”看起来像抽象偏好，而不是由 #009/#010 连续实证推出的目的优先结果。

## 结论

不建议 ratify 当前候选。修复上述四处后，剩余问题主要是 ratify PR 的执行项：同步修改 M-000 §6/frontmatter、grep 并处理 `default_word_budget` 消费端、再录入 user-decision-log 的正式 Overrule 条目。
