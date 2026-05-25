---
last_verified: 2026-05-25
layer: contract
scope: skill-audit-consensus
freshness:
  max_age_days: 30
  decay_trigger: [skill_audit_ratified]
---

# Skill 审计 Stage 3 折叠报告

> 路径 C Stage 3：Claude 中立主笔产 4 家 Verdict 矩阵对比 + 共识识别 + 帅哥裁决点。  
> 4 家产物链接：[claude](skill-audit-claude.md) / [codex](skill-audit-codex.md) / [deepseek](skill-audit-deepseek.md) / [gemini](skill-audit-gemini.md)。  
> 启动裁决：[#016](../meta/user-decision-log.md#016-路径-c-启动--skill-生态第一性原理审计彻底解决自举循环)。

## §1 4 家产物索引

| 家 | 文件 | bytes | nwc | model | Verdict 分布 | 倾向 |
|---|---|---|---|---|---|---|
| Claude | [skill-audit-claude.md](skill-audit-claude.md) | 27242 | ~16000 | Opus 4.7 (1M) | KEEP 34 / MERGE 1 / DELETE 1 / PROMOTE 4 / DOWNGRADE 9 / REWRITE 5 | 🛡️ **保守**：34 KEEP（已知 M-005 起草用过部分 skill，同源偏向） |
| Codex | [skill-audit-codex.md](skill-audit-codex.md) | 47306 | ~22000 | GPT-5 (worktree) | KEEP 2 / MERGE 21 / DELETE 2 / PROMOTE 7 / DOWNGRADE 14 / REWRITE 12 | 🔪 **激进 MERGE**：21 MERGE（识别大量功能重叠） |
| DeepSeek | [skill-audit-deepseek.md](skill-audit-deepseek.md) | 34080 | ~17000 | reasoner | KEEP 26 / MERGE 1 / DELETE 14 / PROMOTE 5 / DOWNGRADE 1 / REWRITE 11 | 🔪 **激进 DELETE**：14 DELETE（认为多数 skill 无证据存在价值） |
| Gemini | [skill-audit-gemini.md](skill-audit-gemini.md) | 36717 | ~18000 | gemini-3.5-flash GA | KEEP 12 / MERGE 3 / DELETE 4 / PROMOTE 13 / DOWNGRADE 16 / REWRITE 4 | 🔪 **激进 PROMOTE+DOWNGRADE**：13 PROMOTE + 16 DOWNGRADE / 仅 12 KEEP（认为多数应转 standards / templates） |

## §2 总共识统计

- **3+/4 共识项**: **7 / 52 = 13%**
- **2/4 多数 + 2 分歧**: 约 **30 项**
- **完全分歧 (1-1-1-1)**: 约 **15 项**

**结论**：87% 分歧率，远超 M-000 v2.0 起草（4 家对 R1~R7 + D1~D3 形成多数 3/4 共识）和 M-005 v1→v2 起草（4 处 BLOCK 精准识别）。这证明 **skill 生态确实有大量结构性问题**——4 家在不同视角看，几乎每个 skill 都有不同处理意见。

## §3 7 个 3+/4 共识项（直接落地，无需裁决）

| skill | 共识 Verdict | 反对方 |
|---|---|---|
| `coding-best-practices` | **PROMOTE_TO_STANDARDS (3/4)** | DeepSeek KEEP |
| `dod-checklist` | **KEEP (3/4)** | Codex PROMOTE |
| `onboarding-generator` | **DOWNGRADE_TO_TEMPLATE (3/4)** | DeepSeek KEEP |
| `phase-closeout` | **KEEP (3/4)** | Codex MERGE |
| `swiftui-pro` | **KEEP (3/4)** | Codex MERGE |
| `ui-review` | **MERGE (3/4)** | DeepSeek KEEP |
| `verify-audit-report` | **KEEP (3/4)** | Codex DOWNGRADE |

**Claude 推荐**：7 个共识项 ratify 后**直接执行 Verdict**，无需用户裁决。

## §4 4 家 Verdict 完整矩阵（52 项）

| skill | claude | codex | deepseek | gemini | consensus/Claude 推荐 |
|---|---|---|---|---|---|
| accessibility-generator | KEEP | MERGE | DELETE | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| animation-patterns | KEEP | MERGE | PROMOTE_TO_STANDARDS | PROMOTE_TO_STANDARDS | 分歧 (2-2 或 2-1-1) ⚠️ |
| api-research | MERGE | MERGE | KEEP | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
| app-description-writer | KEEP | MERGE | DELETE | DELETE | 分歧 (2-2 或 2-1-1) ⚠️ |
| app-icon-generator | DOWNGRADE_TO_TEMPLATE | PROMOTE_TO_STANDARDS | KEEP | DOWNGRADE_TO_TEMPLATE | 分歧 (2-2 或 2-1-1) ⚠️ |
| app-store-assets | PROMOTE_TO_STANDARDS | MERGE | KEEP | PROMOTE_TO_STANDARDS | 分歧 (2-2 或 2-1-1) ⚠️ |
| app-store-rejection | KEEP | MERGE | KEEP | PROMOTE_TO_STANDARDS | 分歧 (2-2 或 2-1-1) ⚠️ |
| attributed-string | KEEP | MERGE | DELETE | DOWNGRADE_TO_TEMPLATE | 完全分歧 (1-1-1-1) 🔴 |
| background-processing | DOWNGRADE_TO_TEMPLATE | MERGE | KEEP | DOWNGRADE_TO_TEMPLATE | 分歧 (2-2 或 2-1-1) ⚠️ |
| characterization-test-generator | KEEP | MERGE | DELETE | REWRITE | 完全分歧 (1-1-1-1) 🔴 |
| ci-cd-setup | PROMOTE_TO_STANDARDS | PROMOTE_TO_STANDARDS | KEEP | DOWNGRADE_TO_TEMPLATE | 分歧 (2-2 或 2-1-1) ⚠️ |
| coding-best-practices | PROMOTE_TO_STANDARDS | PROMOTE_TO_STANDARDS | KEEP | PROMOTE_TO_STANDARDS | **PROMOTE_TO_STANDARDS (3/4)** ✅ |
| cross-audit | KEEP | DOWNGRADE_TO_TEMPLATE | KEEP | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| cross-audit-consensus | KEEP | DOWNGRADE_TO_TEMPLATE | REWRITE | MERGE | 完全分歧 (1-1-1-1) 🔴 |
| data-export | DOWNGRADE_TO_TEMPLATE | MERGE | KEEP | DOWNGRADE_TO_TEMPLATE | 分歧 (2-2 或 2-1-1) ⚠️ |
| decision-closeout | KEEP | MERGE | REWRITE | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| deep-linking | KEEP | MERGE | DELETE | DOWNGRADE_TO_TEMPLATE | 完全分歧 (1-1-1-1) 🔴 |
| dependency-propagation | KEEP | PROMOTE_TO_STANDARDS | KEEP | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| dod-checklist | KEEP | PROMOTE_TO_STANDARDS | KEEP | KEEP | **KEEP (3/4)** ✅ |
| error-monitoring | DOWNGRADE_TO_TEMPLATE | MERGE | KEEP | DOWNGRADE_TO_TEMPLATE | 分歧 (2-2 或 2-1-1) ⚠️ |
| harness-recall | KEEP | MERGE | REWRITE | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
| integration-test-scaffold | KEEP | MERGE | DELETE | DOWNGRADE_TO_TEMPLATE | 完全分歧 (1-1-1-1) 🔴 |
| keyword-optimizer | KEEP | MERGE | KEEP | DELETE | 分歧 (2-2 或 2-1-1) ⚠️ |
| knowledge-health | DELETE | MERGE | REWRITE | KEEP | 完全分歧 (1-1-1-1) 🔴 |
| liquid-glass | KEEP | MERGE | DELETE | DOWNGRADE_TO_TEMPLATE | 完全分歧 (1-1-1-1) 🔴 |
| localization-setup | DOWNGRADE_TO_TEMPLATE | MERGE | KEEP | DOWNGRADE_TO_TEMPLATE | 分歧 (2-2 或 2-1-1) ⚠️ |
| migration-patterns | KEEP | MERGE | PROMOTE_TO_STANDARDS | PROMOTE_TO_STANDARDS | 分歧 (2-2 或 2-1-1) ⚠️ |
| navigation-patterns | KEEP | MERGE | DELETE | PROMOTE_TO_STANDARDS | 完全分歧 (1-1-1-1) 🔴 |
| onboarding-generator | DOWNGRADE_TO_TEMPLATE | DOWNGRADE_TO_TEMPLATE | KEEP | DOWNGRADE_TO_TEMPLATE | **DOWNGRADE_TO_TEMPLATE (3/4)** ✅ |
| phase-closeout | KEEP | MERGE | KEEP | KEEP | **KEEP (3/4)** ✅ |
| post-merge | KEEP | MERGE | REWRITE | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
| privacy-manifests | KEEP | MERGE | DELETE | DOWNGRADE_TO_TEMPLATE | 完全分歧 (1-1-1-1) 🔴 |
| push-notifications | KEEP | MERGE | DELETE | DOWNGRADE_TO_TEMPLATE | 完全分歧 (1-1-1-1) 🔴 |
| resume-from-handoff | KEEP | MERGE | REWRITE | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
| review-response-writer | KEEP | KEEP | DELETE | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| screenshot-planner | KEEP | KEEP | DELETE | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| settings-screen | DOWNGRADE_TO_TEMPLATE | KEEP | KEEP | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| snapshot-diff-review | MERGE | KEEP | KEEP | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| snapshot-testing | KEEP | MERGE | KEEP | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| sprint-contract | KEEP | MERGE | KEEP | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| swift-concurrency-pro | KEEP | REWRITE | KEEP | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| swiftdata-pro | KEEP | REWRITE | KEEP | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| swiftui-debugging | KEEP | MERGE | PROMOTE_TO_STANDARDS | MERGE | 分歧 (2-2 或 2-1-1) ⚠️ |
| swiftui-pro | KEEP | MERGE | KEEP | KEEP | **KEEP (3/4)** ✅ |
| tdd-bug-fix | MERGE | MERGE | KEEP | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
| tdd-feature | MERGE | MERGE | KEEP | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
| tdd-refactor-guard | MERGE | PROMOTE_TO_STANDARDS | KEEP | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
| test-contract | KEEP | MERGE | DELETE | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
| tipkit-generator | DOWNGRADE_TO_TEMPLATE | MERGE | KEEP | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
| ui-review | MERGE | MERGE | KEEP | MERGE | **MERGE (3/4)** ✅ |
| verify-audit-report | KEEP | DOWNGRADE_TO_TEMPLATE | KEEP | KEEP | **KEEP (3/4)** ✅ |
| xcode-review | MERGE | KEEP | PROMOTE_TO_STANDARDS | KEEP | 分歧 (2-2 或 2-1-1) ⚠️ |
## §5 分歧分析 + Claude 推荐裁决

### §5.1 治理 skill 的高分歧度（12 个治理 skill 中只有 2 个共识）

| 治理 skill | 4 家 | Claude 推荐 | 理由 |
|---|---|---|---|
| `cross-audit` | KEEP / DOWNGRADE / KEEP / MERGE | **REWRITE 对齐 M-005 v2** | Codex DOWNGRADE 不成立（cross-audit 需 LLM 判断不是纯模板）；Gemini MERGE 目标若是 cross-audit-consensus 则同向；保留为治理 skill 但需对齐 M-005 §B/§H 文本 |
| `cross-audit-consensus` | KEEP / DOWNGRADE / REWRITE / MERGE | **MERGE → cross-audit** | 与 cross-audit 同工作流不同阶段，3/4 家倾向合并/降级，应合并 |
| `decision-closeout` | KEEP / MERGE / REWRITE / MERGE | **REWRITE 等待 M-002** | Codex/Gemini MERGE 但合并目标未明；DeepSeek REWRITE 合理（应对齐 M-002 ratify 后文本）。当前 M-002 未起草，暂保留 + 标 REWRITE |
| `dependency-propagation` | KEEP / PROMOTE / KEEP / MERGE | **REWRITE 对齐 M-005 §D.4** | 2/4 KEEP 但需对齐 M-005 §D.4 SSOT 同步刷新三层纪律 |
| `harness-recall` | KEEP / MERGE / REWRITE / KEEP | **MERGE → knowledge-health** | Codex MERGE 目标可能是 knowledge-health；DeepSeek REWRITE 也指向重写为 self-reflection。Claude 倾向合并 |
| `knowledge-health` | DELETE / MERGE / REWRITE / KEEP | **REWRITE 对齐 M-005 §F + §K** | Claude DELETE 是误判（应该是 KEEP/REWRITE 不是 DELETE）；DeepSeek REWRITE + Gemini KEEP 合理；保留 + 重写 |
| `phase-closeout` | KEEP / MERGE / KEEP / KEEP | **KEEP (3/4) ✅** | 共识项 |
| `post-merge` | KEEP / MERGE / REWRITE / KEEP | **REWRITE 对齐 M-001 ratify 后** | Codex MERGE 目标不明；DeepSeek REWRITE 合理；2/4 KEEP 倾向保留 + 重写 |
| `resume-from-handoff` | KEEP / MERGE / REWRITE / KEEP | **REWRITE 对齐 M-001 协作工作流** | 2/4 KEEP 但需对齐 M-001 起草后文本 |
| `sprint-contract` | KEEP / MERGE / KEEP / MERGE | **REWRITE 对齐 M-005 §I 结构性决定清单** | 2/4 KEEP + 2/4 MERGE。本会话已实证使用，但需对齐 M-005 v2 §I 文本 |
| `verify-audit-report` | KEEP / DOWNGRADE / KEEP / KEEP | **KEEP (3/4) ✅** | 共识项 |
| `dod-checklist` | KEEP / PROMOTE / KEEP / KEEP | **KEEP (3/4) ✅** | 共识项 |

**治理 skill 小结**：3 个共识保留 + 9 个 REWRITE / MERGE。其中 **6 个治理 skill 需要 REWRITE 对齐当前或未来的元规则文本**，2 个 MERGE 合并，1 个等 M-002 ratify。

### §5.2 工具 skill 的高分歧度（30 个工具 skill 几乎全分歧）

工具 skill 没有 Claude 推荐机械规则——需按内容深审。但 4 家方向给出**统计规律**：

- **`*-pro` skill（swiftui-pro / swiftdata-pro / swift-concurrency-pro / swiftui-debugging）**：Claude/DeepSeek 倾向 KEEP，Codex/Gemini 倾向 MERGE/PROMOTE_TO_STANDARDS。**Claude 推荐**：**KEEP** 但加 `category: tool` frontmatter 字段（与治理 skill 区分）
- **`*-patterns` skill（animation-patterns / navigation-patterns / migration-patterns）**：3/4 家倾向 PROMOTE_TO_STANDARDS / MERGE。**Claude 推荐**：**PROMOTE_TO_STANDARDS** 到 `docs/standards/swiftui-patterns.md`
- **`*-generator` skill（app-icon-generator / onboarding-generator / settings-screen / localization-setup / tipkit-generator 等）**：分歧大，但 Claude/Gemini 多数倾向 DOWNGRADE_TO_TEMPLATE。**Claude 推荐**：**DOWNGRADE_TO_TEMPLATE** 到 `docs/templates/`，仅 `onboarding-generator` 已确认共识
- **TDD 三件套（tdd-feature / tdd-bug-fix / tdd-refactor-guard）**：Claude/Codex MERGE → tdd-feature；DeepSeek/Gemini KEEP。**Claude 推荐**：**MERGE 全部到 tdd-feature**（Codex+Claude 立场强）
- **iOS API skill（attributed-string / deep-linking / liquid-glass / push-notifications / privacy-manifests / accessibility-generator / background-processing / data-export / error-monitoring）**：Claude KEEP / DeepSeek DELETE / Codex MERGE / Gemini DOWNGRADE。**Claude 推荐**：分别看（多数应该 DOWNGRADE_TO_TEMPLATE）

### §5.3 App Store skill 的分歧（6 个）

- `app-description-writer`: KEEP/MERGE/DELETE/DELETE → **DELETE** (2/4)
- `app-store-assets`: PROMOTE/MERGE/KEEP/PROMOTE → **PROMOTE_TO_STANDARDS** (2/4)
- `app-store-rejection`: KEEP/MERGE/KEEP/PROMOTE → **KEEP** (2/4，但 PROMOTE 可考虑)
- `keyword-optimizer`: KEEP/MERGE/KEEP/DELETE → **KEEP** (2/4)
- `review-response-writer`: KEEP/KEEP/DELETE/MERGE → **KEEP** (2/4)
- `screenshot-planner`: KEEP/KEEP/DELETE/MERGE → **KEEP** (2/4)

**Claude 推荐**：5 个 KEEP / 1 个 PROMOTE_TO_STANDARDS（app-store-assets）。

### §5.4 完全分歧 (1-1-1-1) 项（15 项）

这些项没有任何两家一致，必须帅哥逐条裁决：

`api-research` / `cross-audit` / `cross-audit-consensus` / `decision-closeout` / `dependency-propagation` / `harness-recall` / `knowledge-health` / `app-icon-generator` / `app-store-assets` / `attributed-string` / `characterization-test-generator` / `ci-cd-setup` / `deep-linking` / `integration-test-scaffold` / `liquid-glass`

**Claude 推荐**：在 §5.1 + §5.2 中已对治理 skill 给推荐；工具 skill 等帅哥裁决。

## §6 元层级观察（折叠主笔视角）

### O1: 4 家分歧度 = 异源价值最大化 + skill 生态结构性问题双重信号

87% 分歧率不是 4 家"乱判"——4 家用相同任务定义书 + 物理隔离独立审，得出截然不同的 Verdict 分布（Claude 保守 / Codex MERGE 激进 / DeepSeek DELETE 激进 / Gemini PROMOTE+DOWNGRADE 激进）。

**这正是 M-000 §3 默认多方异源 + §7.2 同源警告的根本必要性证明**。如果 skill 生态本身简单清晰，4 家会高度一致；4 家高度分歧 = **生态本身复杂模糊，需要用户裁决而非智能体自动决断**。

按 M-005 §B.3 + #014 D1 否决权阈值，4 家分歧本身不构成 BLOCK，但触发用户裁决（[#005](../meta/user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) 批准权机制）。45 个分歧项必须由帅哥逐条或批量裁决。

### O2: Claude 同源风险已实证

Claude 给 `cross-audit` KEEP（已知 M-005 起草用过），但 Codex DOWNGRADE_TO_TEMPLATE / Gemini MERGE。**这是 M-005 §B 同源警告的实证**——本会话上下文污染导致 Claude 倾向保留自己起草过程用过的 skill。

**建议**：Stage 4 sign-off + Stage 5 批量执行时，对 cross-audit / sprint-contract / decision-closeout 等"M-005 起草用过的 skill"采用 **Codex/DeepSeek/Gemini 三家立场加权**（屏蔽 Claude 同源偏向），减小 Claude 自审失真。

### O3: skill 生态的"全光谱缺陷"

4 家从 4 个不同维度发现问题：
- **Codex**（MERGE 21 项）：识别功能重叠 / 命名重复 / 同概念多 skill
- **DeepSeek**（DELETE 14 项）：识别证据不足 / 无真实事故来源 / 形式空洞
- **Gemini**（PROMOTE 13 + DOWNGRADE 16）：识别 skill 形式不匹配（应升 standards 或降 templates）
- **Claude**（KEEP 34）：识别保留价值但可能放过偏差

**4 个维度叠加** = skill 生态确实需要大规模重构。Stage 5 批量执行应**综合 4 家立场**而非单选其一。

### O4: §5.2 工具 skill 的统计规律

`*-pro` / `*-patterns` / `*-generator` / TDD 三件套 / iOS API 五类 skill 的处理方向**可批量裁决**而非逐个：
- `*-pro` 类 → KEEP + 加 category 标签
- `*-patterns` 类 → PROMOTE_TO_STANDARDS
- `*-generator` 类 → DOWNGRADE_TO_TEMPLATE
- TDD 三件套 → MERGE 到 tdd-feature
- iOS API 类 → 多数 DOWNGRADE_TO_TEMPLATE

**Claude 推荐**：帅哥按类别批量裁决（节省时间），单点 skill 再单审。

### O5: §1 中 4 家文件 nwc 比较

Codex 22000 / DeepSeek 17000 / Gemini 18000 / Claude 16000。**Codex 最长** 主要因为 21 MERGE 详情每个都写了合并目标 + 重叠论证（密度高，不冗余）。这与 #015 M-005 起草时 Codex 沟通密度低形成对比——**审计任务比起草任务更适合 Codex**（识别重叠 + 删冗余优势）。

## §7 致帅哥的裁决问题（Stage 3.5 用户裁决点）

按 [#005](../meta/user-decision-log.md#005-docsmeta-归档治理--归档路径用户显式批准) 批准权机制 + #016 排他纪律，**45 个分歧 skill 需要帅哥裁决**。提供三种裁决方式：

### 方式 A：按类别批量裁决（推荐）
帅哥对 §5 中识别的 5 个工具 skill 类别 + 治理 skill 9 个 + App Store skill 6 个共 ~20 个决策点做批量裁决。Claude 推荐方案已在 §5 列出。

### 方式 B：逐条裁决
帅哥对 45 个分歧 skill 逐一裁决。最严格但最耗时。

### 方式 C：接受 Claude 推荐 + 单点 override
帅哥接受 §5 全部 Claude 推荐，仅 override 个别不认同的项。最快但依赖 Claude 中立性（O2 已识别 Claude 同源风险）。

## §8 后续路径

帅哥裁决落 user-decision-log #017（预编号）后：
1. **Stage 3.5 完成**：完整 Verdict 矩阵确定
2. **Stage 4 启动**：DeepSeek 主笔产 `skill-audit-final.md`（综合 4 家 + #017 裁决 + Claude consensus 报告）
3. **3 家 sign-off**（Claude/Codex/Gemini，DeepSeek 不下场）
4. **帅哥 ratify** 落 #018
5. **Stage 5 批量执行**：DELETE / MERGE / PROMOTE / DOWNGRADE / REWRITE 分类批处理
6. **Stage 6 元规则反思**：审计完回头检查 M-000/M-005 是否需 patch
7. **Stage 7 M-003 起草**：基于路径 C 实证

## 关联文档

- [任务定义书](skill-audit-task-definition.md)
- [4 家产物](skill-audit-claude.md) | [codex](skill-audit-codex.md) | [deepseek](skill-audit-deepseek.md) | [gemini](skill-audit-gemini.md)
- [M-000 v2.0](../meta/M-000-meta-vision.md) §3 / §7.2 异源原则
- [M-005 v2](../meta/M-005-quality-criteria.md) §B 伪共识识别 / §F 自反性
- [user-decision-log](../meta/user-decision-log.md) #016 路径 C 启动
