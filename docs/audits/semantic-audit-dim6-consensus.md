---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# 语义层维度 6 — 三方对抗共识报告（skill description ↔ body 一致性）

> **日期**：2026-05-21 | **维度**：6 skill description ↔ body 一致性（52 个 skill 全量逐个核对）| **三方**：Claude CLI / Codex 桌面端 / Antigravity (Gemini 3.5 Flash (High))
>
> **方法**：F-008「相同完整任务、不分工」+ 控制变量法精髓——三家完整扫 52 个 skill。[[cross-audit-consensus]] 折结果。
>
> 单家原始报告：
> - Claude CLI：本会话上下文 (2 finding：0H/0M/1L/1INFO，Claude 第一次 0 独家)
> - Codex 桌面端：本会话上下文 (6 finding：0H/2M/4L)
> - Antigravity：[`semantic-audit-dim6-findings.md`](semantic-audit-dim6-findings.md) (5 finding：0H/4M/1L)
>
> 共识 ledger：[`audit-ledger-semantic-2026-05.tsv`](audit-ledger-semantic-2026-05.tsv) S-D6-001 ~ S-D6-007

## 三家分布对比

| 项目 | Claude | Codex | Antigravity |
|---|---|---|---|
| 总 finding | 2 | 6 | 5 |
| HIGH | 0 | 0 | 0 |
| MEDIUM | 0 | 2 | 3 (含 3 个 H1 缺失) |
| LOW | 1 | 4 | 2 |
| INFO | 1 | 0 | 0 |
| 工作流违规 | — | — | ✅ 无 |

**形态对比**：
- **Codex** 三轮连续最强（维度 4+5+6）。本轮抓到批量大发现 D6-001（13+ domain skill missing support files）+ 动词偏移 + 4 个范围漂移
- **Antigravity** 守规矩（继续）。命中 Claude/Codex 共识 + 3 个 H1 独家 (但修复处方违规)
- **Claude CLI** 0 独家——首次出现，**控制变量法暴露的真实局限**：大范围机械实证不如 Codex

## 折叠总览

| 共识等级 | 数量 | 严重度分布 |
|---|---|---|
| **2/3 共识** | 2 | MEDIUM×1 LOW×1 |
| **1/3 单家 (Codex)** | 5 | MEDIUM×2 LOW×3 |
| **Claude 自驳** | 1 | (C6.2 INFO → 接受 Antigravity MEDIUM，归并到 S-D5-004) |
| **合计 OPEN** | **7** | MEDIUM×3 LOW×4 |

## 2/3 共识

### S-D6-002 [MEDIUM, 2/3 Antigravity+Codex] — 3 个 shared skill 缺 H1（**Claude 自驳此前判断**）

`swift-concurrency-pro` / `swiftdata-pro` / `swiftui-pro` 三个 vendored shared skill `frontmatter name:` 字段存在但**无 H1 标题**，正文直接从段落开始。

**Claude 自驳记录**：Claude CLI 此前判断「社区 skill 原格式不算漂移」，看到 Codex/Antigravity 论证后接受这是真 finding——name 字段值与 H1 缺失确实是 name → H1 对齐断裂。

**关键复杂性**（Claude 补充洞察）：`skill-source-ledger.md:16` 明文「Do not edit community skill bodies directly for project preferences」。这 3 个是 `kind: managed` vendored 社区 skill（如 `twostraws/Swift-Concurrency-Agent-Skill`），修复路径**不能**走 Antigravity 建议的「修 body 加 H1」——那违反项目纪律。

**正确修复路径**：
- **A (推荐)**：标 WAIVED，在 `skill-architecture.md` 加 ADR 说明 vendored 社区 skill 不强制 H1
- **B**：向上游 GitHub PR 提加 H1（最 ideal 但慢）

**元层级 finding**：此事件暴露 **skill-source-ledger 纪律 vs name → H1 对齐期望的冲突**——skill 体系治理盲区。

### S-D6-004 [LOW, 2/3 Claude+Antigravity] — xcode-review description 范围窄于 body

description 「Xcode Intelligence Review 提示词撰写指南」vs body line 22 「适用于：外部 Reviewer（如 Antigravity 等全量代码上下文工具，可选）和 Xcode Intelligence Review（项目内上下文）」——description 缺「外部 Reviewer」覆盖。

修复：description 改为「外部手动 Reviewer 与 Xcode Intelligence Review 双轨提示词写作规范」。

## 1/3 单家可采纳（仅 Codex，5 项）

### S-D6-001 [MEDIUM, 1/3 Codex 独家] — 大批 domain skill description 引用不存在的 support files

**本轮最大独家发现**。实证命令 `find .claude/skills -maxdepth 2 -type f -not -name SKILL.md` **0 输出**——`.claude/skills` 内只有 SKILL.md，无任何 support files。但 13+ 个 domain skill body 真要读：
- `app-icon-generator:77` `Read apple-hig-icons.md before generating`
- `data-export:78` `Read templates.md for production Swift code`
- `coding-best-practices:33-36` `swift-patterns.md / swiftui-patterns.md / architecture-patterns.md / coredata-patterns.md`

受影响同类还包括 `app-store-assets / app-store-rejection / background-processing / error-monitoring / keyword-optimizer / migration-patterns / onboarding-generator / settings-screen / swiftui-debugging / tipkit-generator / ui-review` 共约 13+ 个 skill。

**结构层 skill-provenance check 应该抓但漏了的真问题**——vendored skill 同步时只复制 SKILL.md，没同步 `reference/` 子目录的 support files。description 承诺的 Generator/Reviewer 工作流**不能独立执行**。

**修复**：补 vendored support files（通过 skills-lock.json 同步上游）或 description/body 降级为「SKILL.md-only high-level guidance」。

### S-D6-003 [MEDIUM, 1/3 Codex] — tdd-refactor-guard 动词偏移

description「Pre-refactor safety checklist. **Verifies** test coverage exists」vs body line 9 「If coverage is insufficient, **generates** characterization tests first」+ Step 4 真生成测试——`verify` 漂移到 `generate`，实际是 generator gate 不是单纯 checklist。

### S-D6-005 [LOW, 1/3 Codex] — post-merge 4 步 vs 5 步

description「4 步链条 CI 检查 → STATUS.md → anti-pattern-scan → 文档同步」+ body §一句话「4 个必做步骤」vs body 实际有 **Step 5「检查 handoff.md」**（line 100）+ 输出清单只列 4 项漏 Step 5。

### S-D6-006 [LOW, 1/3 Codex] — liquid-glass 缺 visionOS

description 定位 iOS/macOS 26+ 覆盖 SwiftUI/AppKit/UIKit/WidgetKit，但触发条件 + body line 682 含 **visionOS** widget textures/mounting styles 独立段。

### S-D6-007 [LOW, 1/3 Codex] — screenshot-planner 范围窄

description 只承诺 screenshot sequences / conversion / captions，body 还覆盖 **App Preview Video 规格**（line 194）+ **本地化市场优先级**（line 217）。

## 与维度 5 同源（不重复列入）

- `harness-recall` body 仍 grep `## Risks` 但 handoff 已无该段——**S-D5-004 同源**，Antigravity 标 MEDIUM Codex 显式排除「视为 S-D5-004 同源」。维度 6 标 INFO 不入 ledger（同源条目应在 S-D5-004 统一修复）。

## 结构层已知（不重复列入）

- `app-store-rejection` 文件夹名 vs `name: rejection-handler` — A072 VALID_WITH_GAP
- `snapshot-testing` 文件夹名 vs `name: snapshot-test-setup` — A083 VALID_WITH_GAP

## Gemini 3.5 over-endorse 持续监控（维度 6 数据点）

| 指标 | 维度 1 | 维度 2 | 维度 3 | 维度 4 | 维度 5 | 维度 6 |
|---|---|---|---|---|---|---|
| HIGH 占比 | 33% | 17% | 17% | 40% | 17% | **0%** |
| 100% VALID 倾向 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 抓到独家深度 finding | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (3 个 H1) |
| 误判数 | 2 | 0 | 0 | 0 | 0 | 0 (但修复处方违规) |
| 工作流违规 | — | — | ⚠️ 抢跑 | ✅ | ✅ | ✅ |

**累计结论**：Gemini 3.5 六轮实测**未复现 over-endorse 病灶**。维度 6 出现 0 HIGH 不是 over-endorse 信号——本维度三家都 0 HIGH（说明 skill 体系经维度 1-5 审查后真无 HIGH 级问题）。但 Antigravity 的 H1 修复处方违反 skill-source-ledger 是新现象（**抓真问题 + 开错处方**），需要监控。

## 单家排名（维度 6）

| 排名 | 单家 | 角色 |
|---|---|---|
| 1 | **Codex** | 三轮连续最强（维度 4+5+6）——本轮 6 项含 1 个批量大发现 D6-001（13+ skill 缺 support files）+ 1 动词偏移 + 4 范围漂移 |
| 2 | Antigravity | 5 项含 3 个 H1 独家。守规矩（连续三轮无抢跑）。**第一次出现「找到真 finding + 处方违规」**——H1 修复违反 skill-source-ledger 纪律 |
| 3 | Claude CLI | **首次 0 独家**——大范围机械实证类任务上不如 Codex。控制变量法暴露的真实模型局限 |

## Claude CLI 维度 6 局限标注

- Claude CLI 第一次 0 独家 finding，所有发现都被 Antigravity/Codex 覆盖
- 不是偷懒——Claude 完整扫了 52 个 SKILL.md（含 head 全扫 + 14 个 governance 深读 + 21 个 domain + 13 adapter + 3 symlink + 16 .agents）
- **真实局限**：Codex 在大范围跨文件 grep 系统性扫描上比 Claude 强，特别是「support files 是否存在」「step count 数量」这类机械实证
- Claude 强项是元层级自指（维度 5 S-D5-010 制定者不遵守自己规则），本维度无此类机会

## 累计 OPEN finding

| 维度 | OPEN |
|---|---|
| 1 跨文档语义链条 | 22 |
| 2 反向溯源 | 11 |
| 3 内部冲突扫描 | 10 |
| 4 技术↔产品对齐 | 11 |
| 5 standards 约束力 | 15 |
| **6 skill description↔body** | **7** |
| **累计** | **76** |
| 7 F-rule 遵守度 | ⏳ |

## 下一步

1. **本会话**：commit + push（ledger + dim6-consensus + ADR-005 维度 6 行 + STATUS/handoff）
2. **下一会话**：维度 7「F-rule 实际遵守度」——按新工作流 Claude CLI 先跑 → 提示词 → Codex/Antigravity。这是 Phase 10 最后一维度
3. **Phase 10 收官倒计时**：维度 7 完成后回填 ADR-005「提议」→「已决策」+ ADR-004 backlog 第一条勾 ✅
