---
last_verified: 2026-05-26
layer: pattern
scope: meta
derived_from: [M-000 §3, M-005 §A, M-002 §5.2]
freshness:
  max_age_days: 30
---
# M-006 异源 Sign-off 任务定义书（净化版）

> 本文档是给两家异源 reviewer（AGY / Codex）的净化任务定义。
> 严格遵循 M-000 §3 P7（净化提示词）+ M-000 §4（独立产出）+ M-005 §H.2（主笔不裁决）。
> DeepSeek 通道故障（详 user-decision-log #025），本批跳过。

---

## 1. 任务

审计 `docs/meta/M-006-data-governance.md` v1 draft 是否可 ratify。

## 2. 必读输入

按以下顺序读取，禁止跳读：

1. `docs/meta/M-006-data-governance.md` — 待审 draft
2. `docs/meta/M-000-meta-vision.md` — 宪法层（特别 §2 PRIMARY / §3 异源 + 净化提示词 / §5 裁决 / §11.1 派生职能）
3. `docs/meta/M-005-quality-criteria.md` — 质量判据（特别 §A 四判据 / §B 伪共识 / §C 静默退化 / §C.5 prompt injection / §D 外部事实 / §F 自反性 / §I 越权 / §J 字数原则）
4. `docs/meta/M-002-dispute-arbitration.md` — 裁决流程（特别 §4.3 跨厂商触发 / §10 user-decision-log schema）
5. `docs/meta/M-001-to-M-006-followup-backlog.md` — backlog（特别 MC-4，M-006 必须吸收）
6. `docs/meta/user-decision-log.md` — 历史裁决 #001-#025（特别 #022 私有 memory 实证 + #025 M-002 ratify + 数字凑数巧合发现）

## 3. 禁止材料

严禁参考以下任一项（违反 P7 净化提示词，会被检出后判定为辅助视角不计强证据）：

- 其他家（AGY / Codex / DeepSeek）的 sign-off 报告（含 M-002 历次 sign-off 报告）
- 主笔（Claude）的内部推理 / commit message 详情
- 之前任何关于 M-006 起草思路的讨论
- 任何提示「应当 PASS」「应当 BLOCK」的引导性语言

## 4. 评估维度（M-005 §A 四判据 + 三补充）

按以下 7 项逐章评估 M-006：

| ID | 判据 | M-005 锚 | 评估方法 |
|---|---|---|---|
| D1 | 可追溯性 | §A.1 | 每条规则是否引用 #编号 / MC-N / PRIMARY ID / 第一性原理论证 |
| D2 | 可验伪性 | §A.2 | 每条规则是否有可识别的违反信号（yes/no 可判定） |
| D3 | 下沉证明 | §A.3 | 每章是否说明「为何不能下沉到 standards/templates/skills/tools」 |
| D4 | 目的关联 | §A.4 | 每条规则是否显式关联 PRIMARY ID（P1-P8） |
| D5 | 边界一致 | §3 分工 | 是否与 M-001 / M-002 / M-003 / M-004 / M-005 边界一致，无交叉重定义 |
| D6 | 字数密度 | §J.2 v2 | override_rationale 章节级 + 段级证明是否充分（特别 §5 §7 段级证明） |
| D7 | backlog 覆盖 | MC-4 | M-006 是否完整吸收 MC-4 衍生（用户未定义时三件套默认行为） |

**特别评估：列项原文对照**（受 M-002 v1 §10.1「数字凑数巧合」教训影响）：

请独立 grep M-000 §3 + M-002 §4.3 + M-005 §C.5 原文，逐项对照 M-006 §4 数据分类（5 档）/ §5.1 三件套 / §7.1 信号 4 条 / §8.1 硬边界 4 项是否完整吸收宪法层清单。**不要因为视觉上凑数对齐就判 PASS**。

## 5. 输出格式（强约束）

输出 markdown 文档，结构（同 M-002 任务定义书 §5，省略重复说明）：

- 自报身份（vendor + model）
- Verdict（PASS / CONDITIONAL / BLOCK）
- 摘要（3-5 句）
- 逐章评估（D1-D7 每章）
- 阻塞性问题（BLOCK finding，按 M-005 §B.3 三要素：具体事实错误 + 可证伪反假设 + 明确风险路径）
- 改进建议（CONDITIONAL finding）
- 自反性标注（含「列项原文对照」是否执行 + 哪些清单已对照）

## 6. Verdict 判定规则

- **PASS**：D1-D7 全部 PASS 或仅 CONDITIONAL，无 BLOCK
- **CONDITIONAL**：D1-D7 有 1-2 项 CONDITIONAL + 主笔可在不重写架构的前提下修复
- **BLOCK**：D1-D7 有任一项 BLOCK + 必须重写章节或新增段落

## 7. 主笔身份强约束

输出文档第一句必须自报身份（vendor + model）。若身份不能稳定确认（如自称其他 vendor），按 M-005 §C.4 「身份误识别」自动降级权重 0。

## 8. 时限

无硬时限。请尽可能深度评估。

---

*任务定义书 by Claude Opus 4.7（M-006 主笔），按 M-005 §H.2 主笔不裁决原则。*
