---
last_verified: 2026-05-26
layer: pattern
scope: meta
derived_from: [M-000 §3, M-005 §A, M-002 §5.2]
freshness:
  max_age_days: 30
---
# M-004 异源 Sign-off 任务定义书（净化版）

> 给 AGY / Codex 两家异源 reviewer 的净化任务定义。
> DeepSeek 通道仍故障，本批跳过。

---

## 1. 任务

审计 `docs/meta/M-004-degradation-manual.md` v1 draft 是否可 ratify。

## 2. 必读输入

按顺序读取：

1. `docs/meta/M-004-degradation-manual.md` — 待审 draft
2. `docs/meta/M-000-meta-vision.md` — 宪法（§2 PRIMARY / §10 风险降级 / §11.1 派生）
3. `docs/meta/M-005-quality-criteria.md` — §A 四判据 / §B 伪共识 / §C 静默退化 / §J 字数
4. `docs/meta/M-002-dispute-arbitration.md` — §4.1 不可逆事项 / §5.6 裁决方不可用
5. `docs/meta/M-001-collaboration-workflow.md` — §4.3 vendor 不可用降级 / §11.4 hook 失败
6. `docs/meta/M-006-data-governance.md` — §5.6 共享失败 / §8.4 等待判据
7. `docs/meta/M-001-to-M-006-followup-backlog.md` — MC-7 + MC-9
8. `docs/meta/user-decision-log.md` — #001-#027（特别 #013/#024/#025/#026/#027 实证）

## 3. 禁止材料

严禁参考：
- AGY / Codex / DeepSeek 任一 sign-off 报告（含 M-001/M-002/M-006 历次）
- Claude 主笔内部推理 / commit message 详情
- 任何 M-004 起草思路讨论
- 引导性语言

## 4. 评估维度

| ID | 判据 | M-005 锚 | 评估方法 |
|---|---|---|---|
| D1 | 可追溯性 | §A.1 | 每条规则引 #编号 / MC-N / PRIMARY ID |
| D2 | 可验伪性 | §A.2 | 每条规则有可识别违反信号 |
| D3 | 下沉证明 | §A.3 | 每章是否说明「为何不能下沉」|
| D4 | 目的关联 | §A.4 | 每条规则显式关联 PRIMARY ID |
| D5 | 边界一致 | §3 分工 | 与 M-001/M-002/M-003/M-005/M-006 边界无交叉重定义 |
| D6 | 字数密度 | §J.2 v2 | override_rationale 章节级 + 段级证明（§5 + §8）|
| D7 | backlog 覆盖 | MC-7 + MC-9 | M-004 是否完整吸收 |

**特别评估：列项原文真 grep 验证**（受 M-001 三次「数字凑数巧合」教训影响 [#027](../meta/user-decision-log.md#027)）：

请独立 grep：
- M-000 §2 P1-P8 → M-004 §2 PRIMARY 接口表（M-004 仅列 3 项 P2/P5/P8，请核查这是「派生扩展」诚实声明而非漏项错误）
- M-000 §10 原文 → M-004 §6 等待时长 4 档（M-000 §10 未给具体时长，本表是派生扩展）
- MC-9 backlog 原文 → M-004 §8 iOS 不可逆清单（请核查 MC-9 backlog 列的 6 项是否完整吸收）
- M-005 §C.6 → M-004 §9 静默退化回退 3 节

**不要因视觉对齐就 PASS**；§12 自反性表的对照声明本身也是列项，必须真 grep。

## 5. 输出格式

同 M-001/M-002/M-006 任务定义书 §5：自报身份 / Verdict / 摘要 / 逐章评估 / BLOCK finding（三要素）/ CONDITIONAL finding / 自反性标注（含列项 grep 执行情况）。

## 6. Verdict 判定规则

PASS / CONDITIONAL / BLOCK 三选一。

## 7. 主笔身份强约束

第一句自报 vendor + model。

## 8. 时限

无硬时限。

---

*任务定义书 by Claude Opus 4.7（M-004 主笔），按 M-005 §H.2 主笔不裁决原则。*
