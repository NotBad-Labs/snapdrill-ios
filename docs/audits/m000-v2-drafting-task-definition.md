---
last_verified: 2026-05-24
layer: contract
scope: drafting-task
freshness:
  max_age_days: 30
  decay_trigger: [v2_ratified]
---

# M-000 v2.0 起草任务定义书

> 净化版任务定义书。4 家(Claude / Codex / DeepSeek / Gemini)独立承接,物理隔离执行。不要参考其他家产出。

## 一句话目标

基于第一性原理审计共识(user-decision-log #009),起草 M-000 v2.0 文本,**保留所有 PRIMARY 内核 + 改造所有强共识 ANALOGY/INHERITED 红旗**,产出可 ratify 的元规则最高文档。

## 输入材料(各家必读)

1. **M-000 v1.2 原文**: `docs/meta/M-000-meta-vision.md`
2. **审计裁决**: `docs/meta/user-decision-log.md` #009 (含 R1-R7 + D1/D2/D3 + Q5=A)
3. **4 家审计产物**(只看自己那份,不看别人):
   - `docs/audits/m000-first-principles-<vendor>.md`
4. **折叠报告**(可选,如想看共识汇总): `docs/audits/m000-first-principles-consensus.md`

## 改造目标(R1-R7 必须落到 v2.0 文本)

### R1: 删除「协作宪法」叙事

- v1.2 原文中所有「宪法」「立宪」「ratified」「sign-off」等政治法律修辞 → 改朴素表述
- 建议候选: 「项目最高优先级协作规则」/「Root Rule」/「核心规则集」/ 你自定
- 保留「优先级 0」「冲突时本文件仲裁」的功能性表述

### R2: 字数 B+ 改软上限 + override

- v1.2 §5 「2500 nwc + 400 代码块 + 4000 英译」硬上限 → 改软上限
- 新机制: `default_word_budget: 2500 / override_rationale: <text>` 字段
- v2.0 自身字数允许超 2500 nwc(本审计已实证密度需要),但必须在文档 frontmatter 写明 override_rationale

### R3: frontmatter layer 6 枚举简化

- v1.2 当前 6 类: principle / pattern / snapshot / archive / decision / contract
- 改造方向: 简化到 3-4 类(建议: principle / decision / archive,或转多标签)
- 在 v2.0 中明确给出新枚举值 + 迁移映射(旧 6 → 新 N)

### R4: docaudit 11 check 拆开

- v2.0 不预设 check 数量上限
- 改造方向: 每个 check 必须附「真实事故来源或风险模型」,否则视为可选
- v2.0 给出「核心 check」清单(5-6 项最高频触发) + 「可选 check」清单

### R5: 5 phases 起草流程缩为 3 phases

- v1.2 当前: P1 议题对齐 / P2 4 家独立 / P3 折叠 / P4 主笔 / P5 sign-off
- 改造方向: P1 准备 / P2 独立产出 / P3 合并裁决(sign-off 融入)
- phase 数随议题复杂度浮动,不预设固定数

### R6: 古德哈特改名「目的优先原则」

- 实质保留(机制 PRIMARY),命名去经济学借词
- 改造方向: 「目的优先原则 / Purpose over Form」+ 旧名「古德哈特防御」作 alias

### R7: KNOWLEDGE_MAP 45/50 硬数字改软信号

- v2.0 不出现硬文件数阈值
- 改造方向: 「新增需引用方 + 4 周无 incoming refs 触发 archive 候选 + Boot 字符预算」多指标

## PRIMARY 内核(不可动,必须保留实质,可 reword)

- **P1** F-008 相同完整任务、不分工 (DS+GM PRIMARY)
- **P2** 用户最高裁决权 + append-only user-decision-log (Codex PRIMARY)
- **P3** 默认多方异源(M-000 §3)(Claude+DS PRIMARY,D1 阵营 A)
- **P4** 同源警告(M-000 §7.2)(Claude PRIMARY)
- **P5** worktree 物理隔离(D2 阵营 A)
- **P6** sanity check 自反性(Claude PRIMARY,#008 实证)
- **P7** 净化提示词(Claude PRIMARY)
- **P8** Overrule 机制(D3 阵营 A)

## 硬约束(违反 = v2.0 草案废)

- ❌ 不得废除 D1/D2/D3 任一(阵营 A 已裁决)
- ❌ 不得保留「宪法」叙事或类似政治法律修辞(R1)
- ❌ 不得保留「2500 nwc 硬上限」表述(R2)
- ✅ 必须含 override_rationale 字段说明 v2.0 自身字数(若超 2500)
- ✅ 必须含 M-001~M-006 派生表(v1.2 §8 沿用,Codex 标 ANALOGY 但帅哥未裁决改造,暂保留)
- ✅ 中文输出,允许英文术语

## 产出要求

每家落 `docs/meta/M-000-meta-vision-v2-<vendor>.md`(注意是 `meta/`,不是 `audits/`):

```yaml
---
last_verified: 2026-05-24
layer: principle  # 或新简化枚举
scope: root-rule
freshness:
  max_age_days: 180
  decay_trigger: [meta_audit, override_rationale_change]
default_word_budget: 2500
override_rationale: "..."  # 如超 2500
---
```

正文结构(参考 v1.2 但不强制照搬):

1. 定位与适用范围(R1 朴素表述)
2. 议题清单(沿用 v1.2 §2 或重组)
3. 默认多方异源(P3 保留 + 同源警告 P4 合并)
4. user-decision-log + Overrule(P2 + P8)
5. 字数 B+ 软上限 + override(R2)
6. 风险接受
7. 目的优先原则(R6 改名,机制保留)
8. M-001~M-006 派生表

## 物理隔离纪律

| 家 | 工作目录 | 分支 |
|---|---|---|
| Claude CLI | 主目录(/Users/yiming/Developer/snapdrill-ios) | develop,落 `docs/meta/M-000-meta-vision-v2-claude.md` |
| Codex 桌面端 | `../snapdrill-ios-codex` 复用 | 新分支 `drafting/codex-m000-v2`,落 `docs/meta/M-000-meta-vision-v2-codex.md` |
| DeepSeek API | 沙箱 | Claude 主分支落 `docs/meta/M-000-meta-vision-v2-deepseek.md` |
| Gemini API | 沙箱 | Claude 主分支落 `docs/meta/M-000-meta-vision-v2-gemini.md` |

- ❌ 不要参考主分支已有 v2 产物
- ❌ 不要假设 v1.2 文字一定要保留
- ❌ 不要回避 R1-R7 任一改造
- ✅ 优先「文本可读 + 第一性密度高」而非「沿用 v1.2 篇章结构」

## 验收

4 家草案聚齐后:
1. Claude(中立主笔)做 P3 折叠: 共识段落 / 分歧段落 / 各家独家亮点
2. 帅哥裁决冲突 + 选定主笔(默认 Codex 桌面端)
3. 主笔基于裁决产出 v2.0 final
4. 4-way sign-off (Claude 中立主笔不下场)
5. 帅哥 ratify + 落 user-decision-log #010(M-000 v2.0 ratified)
6. v1.2 归档到 `docs/archive/meta/M-000-v1.2.md`
