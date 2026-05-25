---
last_verified: 2026-05-25
layer: contract
scope: path-c-stage6-signoff
freshness:
  max_age_days: 30
  decay_trigger: [stage_6_ratified, patch_final_changed]
verdict: CONDITIONAL
reviewer: Codex GPT-5
---

# 路径 C Stage 6.2 patch final Codex sign-off

## Verdict

**CONDITIONAL**。

DeepSeek 主笔 `path-c-stage6-patch-final.md` 的三处修订方向成立：P1 把 skill 从平级下沉去向降为第 6 优先级，P2 在 M-005 §G 后追加 skill 升降级双轨，P3 在 M-005 §B.1 增加主笔消费偏向 0.5 折扣信号。整体可进入 ratify，但需在 ratify 前修正 2 个条件：

1. **执行清单必须补真实 numeric line range，且补 user-decision-log #020 追加步骤。**
   - 事实错误：patch final §6.1~§6.3 只写「起始于某句 / 结束于某句」，没有给出实际 line range；§6.4 只在表格里提到 `user-decision-log.md`，没有单独列出追加 #020 的执行项。
   - 可证伪反假设：若执行清单写为 `M-000: replace line 76`、`M-005: append after line 113`、`M-005: append after line 342`、`user-decision-log: append #020 before 日志维护规则 after line 285`，则执行者可以无歧义落地。
   - 风险路径：若保持当前写法，Stage 6.3 执行者可能漏写 #020，或把 M-000 §6 第三段也纳入替换范围，破坏 `patch-final.md` 自己第 14 行承诺的「执行清单需精确到 line 范围」。

2. **P3 追加到 §B.1 时需消除「自动用户裁决」与「不自动升级」的语义冲突。**
   - 事实错误：当前 M-005 §B.1 lead sentence 是「任一信号出现时，同源警告升级为自动用户裁决」（`M-005-quality-criteria.md` 行 108），而 patch final P3 风险段又写「主笔消费偏向信号不自动升级为用户裁决」（`path-c-stage6-patch-final.md` 行 129）。
   - 可证伪反假设：若同步精化 §B.1 lead sentence，区分「自动用户裁决」类信号与「折扣标注」类信号；或把第 5 条放入一个独立的折扣信号小节，则 P3 的 0.5 折扣不会与章节入口冲突。
   - 风险路径：若直接追加第 5 条，后续折叠主笔可同时读出「必须自动上交用户」和「不自动升级」两种执行语义，导致 P3 在执行层不可验伪。

## 必须核查项

| 项 | 结论 | 依据 |
|---|---|---|
| P1: M-000 §6 替换文本是否精确落实下沉优先级（6 级） | ✓ | patch final 行 45-55 给出 6 级列表：standards / templates / hook-CI / 工具脚本 / M-001~M-006-ADR / skills；M-000 当前 §6 待替换段在行 76。 |
| P1: Overrule 关系是否清晰（精化非 Overrule） | ✓ | patch final 行 36-42 明确类型为「精化（非 Overrule）」，只替换 §6 第二段并保留其余内容；#017 行 256 也把此方向定义为精化非 Overrule。 |
| P1: risk & exception 是否覆盖 11 个 active skill 短期保护 | ✓ | patch final 行 59 列出 11 个 KEEP/REWRITE/暂保留 skill；#019 行 281 也列出剩余 11 个 active skill，二者一致。 |
| P2: §G.5 是否完整含 §G.5.1~§G.5.5 | ✓ | patch final 行 75-103 完整包含 §G.5.1 6 Verdict、§G.5.2 季度审计、§G.5.3 baseline/expires_on、§G.5.4 主笔消费偏向、§G.5.5 M-001 衔接。 |
| P2: 6 种 Verdict 体系是否精确对应 #017 裁决 | ✓ | patch final 行 79-85 的 KEEP / REWRITE / MERGE / PROMOTE_TO_STANDARDS / DOWNGRADE_TO_TEMPLATE / DELETE 对应 #017 行 253 的完整 Verdict 分布；#016 行 239 已定义同一 6 Verdict 审计体系。 |
| P2: §G.5.4 主笔消费偏向警示是否与 §B.1 第 5 信号衔接 | ⚠️ | patch final 行 97-99 与行 121-124 双向引用，但 §B.1 当前 lead sentence 与「不自动升级」存在条件 2 所述冲突。 |
| P3: §B.1 追加第 5 条信号是否精确落实主笔消费偏向折扣 0.5 | ✓ | patch final 行 121 明确 KEEP/REWRITE 判定建议折扣 0.5，行 123 要求折叠报告显式标注。 |
| P3: 实证锚定是否引用具体 #017 / Claude Stage 2 实证 | ✓ | patch final 行 122 引用 Claude Stage 2 对 cross-audit / sprint-contract / decision-closeout / knowledge-health 的 KEEP 与 #017 用户裁决纠偏；#017 行 257 记录同源偏向实证。 |
| #020 草案是否含 7 字段 | ✓ | patch final 行 137-145 包含时间 / 冲突描述 / 裁决 / 理由 / 是否触发元规则修订 / Overrule 关系 / 元层级注记。 |
| 执行清单是否精确到 line 范围 | ✗ | patch final 行 151-170 仅给语义位置，不给 numeric line range；且缺 user-decision-log #020 追加执行项。 |

## 自反性复盘（M-005 §F.1）

我在 skill 审计 Stage 2 给过激进 MERGE 路径（21 MERGE）。这一路径抓到了大量功能重叠，但当时的盲点是：MERGE 本身只能解决「两个 skill 重叠」，不能回答「这段知识是否根本不该以 skill 存在」。

本 patch 落实了这个功能重叠识别，但把它提升到了更正确的层级：

- P1 把 skill 明确降为第 6 优先级，修正了我 Stage 2 容易把重叠组件继续合并成 skill 容器的偏向。
- P2 的 §G.5.1 保留 MERGE，但与 PROMOTE_TO_STANDARDS / DOWNGRADE_TO_TEMPLATE / DELETE 并列，避免把所有重叠都吸入更大的 skill。
- P3 把主笔消费过治理 skill 的 KEEP/REWRITE 判定折扣 0.5，能约束 Claude 式自审保留偏向，也同样约束我这种「看到功能重叠就偏向 MERGE」的审计偏向。

因此，patch 对我 Stage 2 的激进 MERGE 路径是有效修正：接受「功能重叠」这个发现，但不让 MERGE 成为默认解。

## 结论

满足上述两个条件后，我的 sign-off 可升为 **PASS**。当前不建议 BLOCK，因为 P1/P2/P3 的核心修订方向与 #016-#019 实证一致，偏差集中在执行清单精度与 §B.1 落点语义，而非三处 patch 的治理目标本身。

<!-- nwc: 2086 -->
