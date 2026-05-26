---
last_verified: 2026-05-25
layer: pattern
scope: meta
derived_from: [M-000 §3, M-005 §A, M-002 §5.2]
freshness:
  max_age_days: 30
---
# M-002 异源 Sign-off 任务定义书（净化版）

> 本文档是给三家异源 reviewer（AGY / Codex / DeepSeek）的净化任务定义。
> 严格遵循 M-000 §3 P7（净化提示词）+ M-000 §4（独立产出）+ M-005 §H.2（主笔不裁决）。

---

## 1. 任务

审计 `docs/meta/M-002-dispute-arbitration.md` v1 draft 是否可 ratify。

## 2. 必读输入

按以下顺序读取，禁止跳读：

1. `docs/meta/M-002-dispute-arbitration.md` — 待审 draft
2. `docs/meta/M-000-meta-vision.md` — 宪法层（特别 §2 PRIMARY / §3 异源 / §5 裁决 / §11.1 派生职能）
3. `docs/meta/M-005-quality-criteria.md` — 质量判据（特别 §A 四判据 / §B 伪共识 / §C 静默退化 / §F 自反性 / §J 字数原则）
4. `docs/meta/M-001-to-M-006-followup-backlog.md` — backlog（特别 MC-1 / MC-5 / MC-10 / MC-11，M-002 必须吸收）
5. `docs/meta/user-decision-log.md` — 历史裁决 #001-#024

## 3. 禁止材料

严禁参考以下任一项（违反 P7 净化提示词，会被检出后判定为辅助视角不计强证据）：

- 其他家（AGY / Codex / DeepSeek）的 sign-off 报告
- 主笔（Claude）的内部推理 / commit message 详情
- 之前任何关于 M-002 起草思路的讨论
- 任何提示「应当 PASS」「应当 BLOCK」的引导性语言

## 4. 评估维度（M-005 §A 四判据 + 三补充）

按以下 7 项逐章评估 M-002：

| ID | 判据 | M-005 锚 | 评估方法 |
|---|---|---|---|
| D1 | 可追溯性 | §A.1 | 每条规则是否引用 #编号 / MC-N / PRIMARY ID / 第一性原理论证 |
| D2 | 可验伪性 | §A.2 | 每条规则是否有可识别的违反信号（yes/no 可判定） |
| D3 | 下沉证明 | §A.3 | 每章是否说明「为何不能下沉到 standards/templates/skills/tools」 |
| D4 | 目的关联 | §A.4 | 每条规则是否显式关联 PRIMARY ID（P1-P8） |
| D5 | 边界一致 | §3 分工 | 是否与 M-005 / M-001 / M-003 / M-004 / M-006 边界一致，无交叉重定义 |
| D6 | 字数密度 | §J.2 v2 | override_rationale 章节级 + 段级证明是否充分（特别 §5 §10 段级证明） |
| D7 | backlog 覆盖 | MC-1/5/10/11 | M-002 是否完整吸收 4 项 MC 衍生（不重复 M-005 已写的 §B.3 等） |

## 5. 输出格式（强约束）

输出 markdown 文档，结构：

```markdown
# M-002 Sign-off 报告（<vendor> <model>）

## Verdict

PASS / CONDITIONAL / BLOCK（三选一）

## 摘要

<3-5 句概括评估结论>

## 逐章评估

按 D1-D7 维度逐章给出评估结果。每章格式：

### §N <章节名>
- D1: PASS / CONDITIONAL / BLOCK + 具体 finding
- D2: ...
- D3: ...
- D4: ...
- D5: ...
- D6: ...
- D7: ...

## 阻塞性问题（BLOCK finding）

按以下结构列每条 BLOCK finding：

### B<N>: <一句话标题>
- 位置：<§N 第 X 段>
- 违反判据：D<N>
- 具体描述：<问题描述>
- 修复建议：<具体修改方案>
- 强烈反对三要素（M-005 §B.3）：
  - 引用具体事实错误：<具体描述>
  - 提出可证伪反假设：<具体描述>
  - 指出明确风险路径：<具体描述>

## 改进建议（CONDITIONAL finding）

按以下结构列每条 CONDITIONAL finding：

### C<N>: <一句话标题>
- 位置：<§N 第 X 段>
- 维度：D<N>
- 建议：<改进建议>
- 不阻塞：<为何不构成 BLOCK>

## 自反性标注

- 起草工具：<vendor / model / API or CLI>
- WebSearch 使用：是 / 否 + 验证范围
- 主笔身份确认：<vendor + model 自报>
- 禁止材料确认：已遵守 P7 净化（无参考其他家 / Claude 主笔内部推理）
```

## 6. Verdict 判定规则

- **PASS**：D1-D7 全部 PASS 或仅 CONDITIONAL，无 BLOCK
- **CONDITIONAL**：D1-D7 有 1-2 项 CONDITIONAL + 主笔可在不重写架构的前提下修复
- **BLOCK**：D1-D7 有任一项 BLOCK + 必须重写章节或新增段落

## 7. 主笔身份强约束

输出文档第一句必须自报身份（vendor + model）。若身份不能稳定确认（如自称其他 vendor），按 M-005 §C.4 「身份误识别」自动降级权重 0（不计入异源）。

## 8. 时限

无硬时限。请尽可能深度评估，不要为节省 token 跳读必读材料。

---

*任务定义书 by Claude Opus 4.7（M-002 主笔），按 M-005 §H.2 主笔不裁决原则，本主笔仅提供任务定义不参与 sign-off。*
