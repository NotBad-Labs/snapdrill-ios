---
last_verified: 2026-05-24
layer: contract
scope: audit-task
freshness:
  max_age_days: 30
  decay_trigger: [audit_complete]
---

# M-000 元规则体系 — 第一性原理审计任务定义书

> 净化版任务定义。本文档将由 4 家(Claude / Codex / DeepSeek / Gemini)独立承接,物理隔离执行。**不要参考其他家产出,包括主分支已有产物**。

## 一句话目标

用第一性原理(First Principles),系统性审计 SnapDrill iOS 项目当前的 M-000 元规则体系,识别其中哪些规则/概念/机制是**从底层事实推导出来的**,哪些是**类比/惯性/模仿**得来的(尤其是模仿其他项目、模仿 RFC/ADR 风格、模仿 LLM 训练偏好等)。

## 第一性原理定义 (审计统一口径)

> 第一性原理 = 把事物拆解到不能再拆的、不证自明的基本事实,再从那里重新推导,而不是从「别人怎么做」「以前怎么做」「类比像什么」出发。

### 5 问审计方法(每条待审项必答)

对每条待审规则/概念/机制,必须回答以下 5 个问题:

1. **目的**: 这条规则为了解决什么真实问题?(拒绝「为了规范」「为了一致」「最佳实践」这种无信息量答案)
2. **机制**: 它通过什么具体机制达成目的?
3. **替代**: 有没有更直接、更朴素的方式达成同一目的?
4. **来源**: 这个规则是「拆到底层推出来的」,还是「类比/模仿了某个已知做法」?如果是后者,模仿对象是什么?
5. **破坏测试**: 如果删除/修改这条规则,系统会怎样退化?如果没有可观察的退化,它就是冗余。

### Verdict 4 类

每条待审项必须打一个 verdict:

- **PRIMARY** (第一性): 5 问全部站得住,从底层事实推导而来
- **INHERITED** (惯性): 沿用历史/前人/模板,但没有底层论证
- **ANALOGY** (类比): 借用其他领域概念(RFC、ADR、宪法、经济学、生物学等),需要重新论证
- **UNDETERMINED** (待定): 信息不足,需要更多证据或拆解

## 审计范围 (4 个层级,不强制覆盖,各家自由扫描)

### Layer 1: M-000 v1.2 文本本身

- 路径: `docs/meta/M-000-meta-vision.md`
- 涵盖: 8 章节(协作宪法定位 / 议题清单 / 默认多方异源 / user-decision-log / 字数 B+ 方案 / Overrule / 风险接受 + 同源警告 / M-001~M-006 派生)

### Layer 2: 派生约束(起草过程的隐性规则)

- 4 家选型(Claude/Codex/DS/GM)、worktree 物理隔离、5 phases 起草流程、净化提示词、sanity check 自反性、4-way sign-off 等

### Layer 3: 基础设施(落地工程)

- docaudit 11 check、frontmatter schema(layer/status/freshness/last_verified)、ADR-004/005 方法论、audit-ledger TSV、KNOWLEDGE_MAP、DOC_DEPENDENCY_MAP、F 规则索引(feedback.md)、permission-model 等
- 路径参考: `docs/standards/` / `docs/decisions/` / `docs/audits/` / `docs/memory/` / `Scripts/`

### Layer 4: 方法论核心概念

- 同源 vs 异源、古德哈特防御、F-008 相同完整任务不分工、layer 6 枚举、verdict-sync、external-gap-expiry 等

### Layer 5: 用户裁决积累

- 路径: `docs/meta/user-decision-log.md` (#001~#008)
- 涵盖: 裁决格式、Overrule 关系结构化分解、side-channel frontmatter workaround 等

## 产出要求

每家落档到 `docs/audits/m000-first-principles-<vendor>.md`,结构:

```markdown
# M-000 第一性原理审计 — <vendor>

## 总评 (≤ 200 字)
4 个 verdict 类各几条,你的核心结论 1-2 句。

## 待审项明细

### [I001] <规则/概念/机制名称>
- 范围: Layer 1-5 哪一层
- 路径: 具体文件/章节
- **目的**: ...
- **机制**: ...
- **替代**: ...
- **来源**: ...
- **破坏测试**: ...
- **Verdict**: PRIMARY / INHERITED / ANALOGY / UNDETERMINED
- **改造建议** (如非 PRIMARY): 重写 / 废除 / 保留 / 暂缓 + 1-2 句理由

### [I002] ...
(每家自由数量,不要求覆盖全部范围 — 深度 > 广度)
```

## 禁止 / 净化原则

- ❌ 不要参考其他家产出(包括主分支已有的 consensus / Claude 的工作笔记)
- ❌ 不要假设当前 M-000 体系一定正确
- ❌ 不要给「整体不错」「方向正确」这类无信息量评价
- ❌ 不要回避 Verdict — 即使 UNDETERMINED 也必须明确写
- ❌ 不要替帅哥(用户)做决定 — 改造建议只是「建议」,终审权在用户
- ✅ 优先深度,允许只扫一部分范围但每条扎实
- ✅ 优先找「容易被忽视的 INHERITED/ANALOGY」 — 即看起来合理但站不住的规则
- ✅ 中文输出,允许英文术语

## 验收

- 4 家产物聚齐后,Claude(中立主笔)做 P3 折叠:产出**共识项 / 分歧项 / 各家独家项**三类清单
- 不投票,4 家齐声标红的就是高置信红旗
- 终审权: 用户(帅哥)

## 提交方式

| 家 | 工作目录 | 分支 | 产物文件 |
|---|---|---|---|
| Claude CLI | 主目录 `/Users/yiming/Developer/snapdrill-ios` | develop | `docs/audits/m000-first-principles-claude.md` |
| Codex 桌面端 | `../snapdrill-ios-codex` | `audit/codex-m000-first-principles` | `docs/audits/m000-first-principles-codex.md` |
| DeepSeek API | 沙箱 (无 repo 访问,基于本任务书内嵌范围描述) | — | 通过 API 返回,Claude 落档 `m000-first-principles-deepseek.md` |
| Gemini API | 沙箱 (同上) | — | Claude 落档 `m000-first-principles-gemini.md` |

完成后 commit + push 各自分支,Claude 主分支 cherry-pick 单文件汇总。

## 关联

- [M-000 v1.2](../meta/M-000-meta-vision.md)
- [user-decision-log](../meta/user-decision-log.md)
- [worktree 工作流](../standards/worktree-audit-workflow.md)
