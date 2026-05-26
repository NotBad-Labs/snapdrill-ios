---
last_verified: 2026-05-26
layer: pattern
scope: meta
derived_from: [M-000 §3, M-005 §A, M-002 §5.2]
freshness:
  max_age_days: 30
---
# M-001 异源 Sign-off 任务定义书（净化版）

> 给 AGY / Codex 两家异源 reviewer 的净化任务定义。
> 严格遵循 M-000 §3 P7（净化提示词）+ M-005 §H.2（主笔不裁决）。
> DeepSeek 通道仍故障，本批跳过（按 [#017](../meta/user-decision-log.md#017)/[#021](../meta/user-decision-log.md#021)/[#025](../meta/user-decision-log.md#025)/[#026](../meta/user-decision-log.md#026) 实证 2 家 + 用户裁决有效）。

---

## 1. 任务

审计 `docs/meta/M-001-collaboration-workflow.md` v1 draft 是否可 ratify。

## 2. 必读输入

按顺序读取：

1. `docs/meta/M-001-collaboration-workflow.md` — 待审 draft
2. `docs/meta/M-000-meta-vision.md` — 宪法（§2 P1-P8 / §3 异源 / §4 隔离 / §11.1 派生）
3. `docs/meta/M-005-quality-criteria.md` — §A 四判据 / §B 伪共识 / §C 静默退化 / §F 自反性 / §H 主笔轮换 / §I 越权 / §J 字数
4. `docs/meta/M-002-dispute-arbitration.md` — §4.4 单方窗口 / §11 sync-status 元规则层
5. `docs/meta/M-006-data-governance.md` — §5.4 独立性四层 / §6.4 CLI hook
6. `docs/meta/M-003-skill-library-governance.md` — §2.4 入库门槛（M-001 §10 sync-status skill 入库引用）
7. `docs/meta/M-001-to-M-006-followup-backlog.md` — MC-2（M-001 必吸收）
8. `docs/meta/user-decision-log.md` — #001-#026（特别 #006 Boot 重构 / #010 私下 Overrule / #013 model ID 误用 / #025/#026 数字凑数巧合两次实证）

## 3. 禁止材料

严禁参考：
- AGY / Codex / DeepSeek 任一 sign-off 报告（含 M-002 / M-006 历次报告）
- Claude 主笔内部推理 / commit message 详情
- 任何 M-001 起草思路讨论
- 引导性语言

## 4. 评估维度（M-005 §A 四判据 + 三补充）

| ID | 判据 | M-005 锚 | 评估方法 |
|---|---|---|---|
| D1 | 可追溯性 | §A.1 | 每条规则引 #编号 / MC-N / PRIMARY ID |
| D2 | 可验伪性 | §A.2 | 每条规则有可识别违反信号（yes/no 可判定）|
| D3 | 下沉证明 | §A.3 | 每章是否说明「为何不能下沉」|
| D4 | 目的关联 | §A.4 | 每条规则显式关联 PRIMARY ID |
| D5 | 边界一致 | §3 分工 | 与 M-002/M-003/M-004/M-005/M-006 边界无交叉重定义 |
| D6 | 字数密度 | §J.2 v2 | override_rationale 章节级 + 段级证明（§5 + §8）|
| D7 | backlog 覆盖 | MC-2 + Antigravity 独家发现 1 | M-001 是否完整吸收 |

**特别评估：列项原文真 grep 验证**（受 M-002/M-006 两次「数字凑数巧合盲信」教训影响，[user-decision-log #025/#026](../meta/user-decision-log.md#026) 实证）：

请独立 grep 以下宪法层原文，逐项对照 M-001 列项：
- M-000 §2 P1-P8 原文 → M-001 §2 PRIMARY 接口表
- M-000 §3 「独立性至少包含四层」原文 → M-001 §5 物理隔离 4 节
- user-decision-log #006 裁决 A-F → M-001 §6 Boot 三段架构

**不要因为视觉对齐就 PASS**；自反性标注章节（§13）的对照声明本身也是列项，必须真 grep。

## 5. 输出格式

同 M-002/M-006 任务定义书 §5：
- 自报身份（vendor + model，第一句）
- Verdict（PASS / CONDITIONAL / BLOCK）
- 摘要 3-5 句
- 逐章评估（D1-D7 每章）
- BLOCK finding（M-005 §B.3 三要素）
- CONDITIONAL finding
- 自反性标注（含列项原文 grep 执行情况 + 哪些列项已对照）

## 6. Verdict 判定规则

- **PASS**：D1-D7 全部 PASS 或仅 CONDITIONAL，无 BLOCK
- **CONDITIONAL**：D1-D7 有 1-2 项 CONDITIONAL，不重写架构可修
- **BLOCK**：D1-D7 有任一项 BLOCK，必须回炉

## 7. 主笔身份强约束

输出第一句自报 vendor + model；身份漂移按 M-005 §C.4 降级权重 0。

## 8. 时限

无硬时限。深度评估。

---

*任务定义书 by Claude Opus 4.7（M-001 主笔），按 M-005 §H.2 主笔不裁决原则。*
