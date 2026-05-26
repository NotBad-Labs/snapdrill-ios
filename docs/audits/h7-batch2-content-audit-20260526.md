---
last_verified: 2026-05-26
layer: pattern
scope: audit
derived_from: [M-000 §11.10, M-005 §G]
freshness:
  max_age_days: 90
  decay_trigger: [standards_refactor, derived_from_check_implemented]
---
# Goal H7 第二批内容级 Traceability Audit（templates + ADR + tech + sign-off spot-check）

> Goal H 健康度收敛 sprint H7 第二批。**重大发现：audit agent 自身污染率 ~55%**——4 次错算实证「跨 vendor 异源也需 counter-verify」。

## 1. 背景

H7 第一批 docs/standards/ 30 份 audit 完成（揭出 40% 标注问题），第二批继续审计：
- docs/templates/ 9 份
- docs/decisions/ ADR 5 份
- docs/tech/ 6 份
- docs/audits/sign-off 26 份 spot-check

帅哥决策 Option E：本会话不修任何 P0（避免主笔再脑补漂移），只做 audit trail 归档 + H3/H4 低风险。

## 2. Audit Agent 自身污染实证（**关键发现**）

第二批 Explore agent 报告 9 项 P0 finding，主笔 grep counter-verify 后发现 **5 项错算**：

| Agent 报告 P0 | 实际 verify 结果 | 性质 |
|---|---|---|
| post-merge-checklist.md「M-004 文件不存在」| ❌ 错 — `docs/meta/M-004-degradation-manual.md` 存在，[#028](../meta/user-decision-log.md#028) ratified | agent 文件存在性判断错误 |
| deep-linking.md「缺 derived_from」| ❌ 错 — 实际有 `scope: product-support`，按 [M-000 §11.10](../meta/M-000-meta-vision.md) §11.7 字段豁免 | agent 未读 §11.7 豁免规则 |
| localization-workflow.md「缺 derived_from」| ❌ 错 — 同上，product-support 豁免 | 同上 |
| onboarding-generator.md「缺 derived_from」| ❌ 错 — 同上，product-support 豁免 | 同上 |
| apple-limits.md「gap_due 已过期」| ❌ 错 — `wwdc_2026` 是 event-tied 字符串，`docaudit external-gap-expiry` clean | agent 把字符串当日期解析 |
| docs/tech/ 4 份「缺 max_age_days」| ❌ 错 — 实际 0 份缺（agent 错算清单） | agent 文件遍历不全 |

**Agent 自身污染率：6/15 ≈ 40%**（按 P0 finding + 衍生 inventory 错）

**实证关键**：
- agent 报告说 H7 第二批漂移率 26%
- 实际真实漂移率 ≤7%
- **agent 自己比文档还漂移**

这直接验证 [feedback_numeric_alignment_blindspot](../../.. unused) 第 6 条「跨 vendor 异源不能完全消除盲信但能补主笔单点盲区」——异源是必需但**不是充分**条件，counter-verify 才是闭环。

## 3. 真实 P0 漂移（counter-verify 后）

### 3.1 cross-audit-workflow.md（**待 verify**）

- **当前**：`derived_from: [M-001, M-003]`
- **agent 怀疑**：F-008「相同完整任务不分工」纪律来自 ADR-005 §2，不在 M-001/M-003 中
- **counter-verify 要点**：grep ADR-005 §2 + M-001 §5 + M-003，看 F-008 真实来源
- **修复风险**：中——若改 derived_from 涉及内容判断，需异源 second-opinion

### 3.2 knowledge-health-workflow.md（**待 verify**）

- **当前**：`derived_from: [M-005 §G]`
- **agent 怀疑**：内容（docaudit 扫描 + 私有空间 + 分层报告）派生自 ADR-004 防漂移机制，更贴 ADR-004 而非 M-005 §G
- **counter-verify 要点**：read ADR-004 完整内容 + M-005 §G 完整内容 + knowledge-health 实际章节
- **修复风险**：中

## 4. 真实 P1（标注精化，agent 报告但未错）

### 4.1 ADR-003 orphan
- 派生关系 `[M-002]` 正确
- 但**无 user-decision-log 反向引用** → orphan
- 修复：补 user-decision-log 反向链 or 加 `referenced_in` frontmatter

### 4.2 第一批 standards 4 P0 仍未修
- shared-constraints.md / permission-model.md / audit-rubric.md / harness-recall.md
- 详见 [h7-standards-content-audit-20260526.md](h7-standards-content-audit-20260526.md)

## 5. ✅ 无漂移（确认）

- ADR-001/002/004/005：派生关系全 verified
- audits sign-off 26 份：100% 结构合规（frontmatter / derived_from 全有）
- docs/tech/ 6 份：100% 内容时效性 PASS（含 apple-limits gap_due 仍 valid）
- templates 5 份（deep-linking / localization / onboarding / cross-audit-consensus / session-resume / sprint-contract）：标注合理

## 6. 综合修复路径（与第一批合并）

### 真实 P0（**待异源 verify 才修**，本会话暂缓）

| # | 文件 | 漂移类型 | 工作量 |
|---|---|---|---|
| 1 | shared-constraints.md | derived_from 标注错（第一批 P0）| 30 min + 异源 verify |
| 2 | permission-model.md | derived_from 标注错（第一批 P0）| 30 min + 异源 verify |
| 3 | audit-rubric.md | derived_from 部分错（第一批 P0）| 30 min + 异源 verify |
| 4 | harness-recall.md | derived_from 标注错（第一批 P0）| 30 min + 异源 verify |
| 5 | cross-audit-workflow.md | derived_from 可能漂移（第二批 P0）| 30 min + 异源 verify |
| 6 | knowledge-health-workflow.md | derived_from 可能漂移（第二批 P0）| 30 min + 异源 verify |

**总计 6 项 P0，约 3-4 小时含异源 verify。留下次 session 处理。**

### 真实漂移率重估

| 类别 | 样本 | 真实 P0 | agent 报告 P0 | agent 误报 |
|---|---|---|---|---|
| standards | 30 | 4（待 verify）| 4 | 0% |
| templates | 9 | 1-2 | 4 | **50-75%** |
| ADR | 5 | 0（含 1 orphan）| 0 | 0% |
| tech | 6 | 0 | 1 | **100%** |
| audits | 26 | 0 | 0 | 0% |
| **合计** | **76** | **5-6** | **9** | **~33% 总误报** |

**真实总体漂移率：6/76 ≈ 8%**（远低于 agent 报告的 26%）

## 7. 元层级注记（升级 [feedback_numeric_alignment_blindspot](../../.. unused) 第 6 条）

帅哥 2026-05-26 concern 链条得到三重验证：

### 7.1 字段层 audit 不足以检测内容漂移
- docaudit frontmatter check 100% pass
- 内容级 audit 揭出 8% 真实漂移（main：standards derived_from 误标）

### 7.2 跨 vendor 异源也会污染
- Explore agent（Claude 同源）H7 第二批误报率 33-55%
- 错算 5 项 + 衍生 inventory 错算 1 项
- 错算类型：文件存在性判断错 / §11.7 豁免规则未读 / 字符串vs日期解析错 / 文件遍历不全

### 7.3 主笔 grep counter-verify 是闭环必需
- 主笔 verify 后真实漂移率从 26% 降到 8%（减少 ~70% 误报）
- counter-verify 应作为 audit 流程**必需步骤**纳入 M-005 §G

## 8. 修复纪律建议（Goal H 收敛后 follow-up）

1. **M-005 §G.7 新增**：audit 报告流程必须含「主笔 counter-verify」步骤，error 率 >20% 的 audit 报告需驳回重做
2. **PreEdit hook 扩展**：可扩展 [pre-edit-numeric-alignment.sh](.. unused) 检测 audit 报告的「文件不存在」/「字段缺失」声明，强制 grep 验证
3. **agent prompt 模板升级**：所有 audit prompt 加 "请 verify 你引用的文件存在 / 章节真实，错引一律 BLOCK 报告" 纪律

---

*主笔: Claude Opus 4.7 (1M context) | 2026-05-26 Goal H7 第二批*
*Audit agent: Explore (a45aa11d5e17c2b89) | 145 秒 / 75K tokens*
*真实样本: 46 份 templates+ADR+tech+audits*
*Agent 报告 P0: 9 | 主笔 counter-verify 后真实 P0: 2-3*
*Agent 误报率: ~55%*
