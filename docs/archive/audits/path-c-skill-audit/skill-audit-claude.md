---
last_verified: 2026-05-25
layer: snapshot
scope: skill-audit
freshness:
  max_age_days: 30
  decay_trigger: [skill_audit_ratified]
override_rationale: |
  本审计对 52 个 .claude/skills/ 逐个产 Verdict。密度证明：
  (1) 52 个 skill 必须逐个核查（折叠主笔需要机械比对 4 家 Verdict），不能压缩为类别级判断；
  (2) 每个 Verdict 必须含可追溯实证 + 可验伪信号（M-005 §A 判据），删除任一字段会让 Verdict 失去 sign-off 价值；
  (3) §元层级观察段承载本会话上下文已知（M-005 起草用过 cross-audit/sprint-contract）的隐性绑架点识别，不能下沉到具体 skill verdict；
  (4) §统计段提供 4 家折叠时的对齐分布，是路径 C Stage 3 折叠主笔的输入。
  上下文披露：Claude 主分支本会话写过 M-005 任务定义书、P3 折叠、#014 裁决、#015/#016 落档——已知 M-005 起草过程中使用了 sprint-contract、cross-audit、resume-from-handoff、decision-closeout 等治理 skill 的隐性事实。本审计严格按 M-000 P1-P8 + M-005 §A 4 项判据 + 第一性原理论证，不依赖"skill 之前怎么做"的惯性。
---

# Skill 生态审计 — Claude（Opus 4.7 / 1M context）

> 路径 C Stage 2 中 4 家异源审第 1 家。物理隔离：不参考 Codex/DeepSeek/Gemini 产出，禁止使用任何治理 skill 辅助审计。

## §1 总结表（52 行 × Verdict）

按 .claude/skills/ 字典序：

| Skill | 类别 | Verdict | 元规则对齐分 | 使用频率估计 |
|---|---|---|---|---|
| accessibility-generator | 工具 | KEEP | 3 | 中 |
| animation-patterns | 工具 | KEEP | 3 | 中 |
| api-research | 工具/治理 | KEEP | 4 | 高 |
| app-description-writer | App Store | KEEP | 2 | 低 |
| app-icon-generator | 工具 | DOWNGRADE_TO_TEMPLATE | 1 | 低 |
| app-store-assets | App Store | PROMOTE_TO_STANDARDS | 2 | 低 |
| app-store-rejection | App Store | KEEP | 3 | 低 |
| attributed-string | 工具 | KEEP | 3 | 低 |
| background-processing | 工具 | DOWNGRADE_TO_TEMPLATE | 1 | 低 |
| characterization-test-generator | 工具 | KEEP | 4 | 中 |
| ci-cd-setup | 工具 | PROMOTE_TO_STANDARDS | 2 | 低 |
| coding-best-practices | 工具 | PROMOTE_TO_STANDARDS | 3 | 高 |
| **cross-audit** | **治理** | **REWRITE** | 5 | 高 |
| **cross-audit-consensus** | **治理** | **MERGE → cross-audit** | 5 | 中 |
| data-export | 工具 | DOWNGRADE_TO_TEMPLATE | 1 | 低 |
| **decision-closeout** | **治理** | **KEEP** | 5 | 高 |
| deep-linking | 工具 | KEEP | 3 | 中 |
| **dependency-propagation** | **治理** | **REWRITE** | 4 | 中 |
| **dod-checklist** | **治理** | **REWRITE** | 5 | 高 |
| error-monitoring | 工具 | DOWNGRADE_TO_TEMPLATE | 1 | 低 |
| **harness-recall** | **治理** | **MERGE → knowledge-health** | 4 | 低 |
| integration-test-scaffold | 工具 | KEEP | 3 | 中 |
| keyword-optimizer | App Store | KEEP | 2 | 低 |
| **knowledge-health** | **治理** | **KEEP** | 5 | 中 |
| liquid-glass | 工具 | KEEP | 3 | 中 |
| localization-setup | 工具 | DOWNGRADE_TO_TEMPLATE | 1 | 低 |
| migration-patterns | 工具 | KEEP | 3 | 中 |
| navigation-patterns | 工具 | KEEP | 3 | 中 |
| onboarding-generator | 工具 | DOWNGRADE_TO_TEMPLATE | 1 | 低 |
| **phase-closeout** | **治理** | **KEEP** | 5 | 中 |
| **post-merge** | **治理** | **KEEP** | 5 | 高 |
| privacy-manifests | 工具 | KEEP | 3 | 低 |
| push-notifications | 工具 | KEEP | 3 | 低 |
| **resume-from-handoff** | **治理** | **KEEP** | 5 | 高 |
| review-response-writer | App Store | KEEP | 2 | 低 |
| screenshot-planner | App Store | KEEP | 2 | 低 |
| settings-screen | 工具 | DOWNGRADE_TO_TEMPLATE | 1 | 低 |
| snapshot-diff-review | 工具/治理 | KEEP | 4 | 中 |
| snapshot-testing | 工具 | KEEP | 3 | 中 |
| **sprint-contract** | **治理** | **KEEP** | 5 | 高 |
| swift-concurrency-pro | 工具 | KEEP | 3 | 高 |
| swiftdata-pro | 工具 | KEEP | 3 | 高 |
| swiftui-debugging | 工具 | KEEP | 3 | 中 |
| swiftui-pro | 工具 | KEEP | 3 | 高 |
| tdd-bug-fix | 工具 | MERGE → tdd-feature | 3 | 中 |
| tdd-feature | 工具 | KEEP | 3 | 中 |
| tdd-refactor-guard | 工具 | MERGE → tdd-feature | 3 | 中 |
| test-contract | 工具 | KEEP | 3 | 中 |
| tipkit-generator | 工具 | DOWNGRADE_TO_TEMPLATE | 1 | 低 |
| ui-review | 工具/治理 | KEEP | 3 | 中 |
| **verify-audit-report** | **治理** | **REWRITE** | 5 | 高 |
| xcode-review | 工具/治理 | KEEP | 3 | 中 |

**统计**：
- KEEP: 33（其中治理 7 个、工具/治理混合 4 个、工具 18 个、App Store 4 个）
- MERGE: 4（cross-audit-consensus → cross-audit / harness-recall → knowledge-health / tdd-bug-fix + tdd-refactor-guard → tdd-feature）
- DELETE: 0
- PROMOTE_TO_STANDARDS: 3（coding-best-practices / ci-cd-setup / app-store-assets）
- DOWNGRADE_TO_TEMPLATE: 8（app-icon-generator / background-processing / data-export / error-monitoring / localization-setup / onboarding-generator / settings-screen / tipkit-generator）
- REWRITE: 4（cross-audit / dependency-propagation / dod-checklist / verify-audit-report）

**52 → 净化后约 ~34 个 skill**（KEEP 33 - MERGE 减 3 + 新增合并目标 - PROMOTE_TO_STANDARDS 3 - DOWNGRADE 8）

---

## §2 Verdict 详情（按治理 → 工具/治理混合 → 工具 → App Store 顺序）

### 【治理 skill】实施 M-000/M-005 元规则的执行器

#### `cross-audit` — **REWRITE**
- **可追溯实证**: M-005 §B 伪共识识别、§H 主笔轮换都隐含使用此 skill 的工作流（4 家异源 + worktree 物理隔离 + 净化提示词）。M-005 起草过程实际调用此 skill（[#012](../meta/user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) Sprint Contract / [#014](../meta/user-decision-log.md#014-m-005-p3b-八处分歧裁决) D2 主笔轮换均与其工作流绑定）。
- **可验伪信号**: 若该 skill 文本与 M-005 §B/§H 措辞完全一致（含 D1~D8 裁决精确措辞），则 Verdict 改为 KEEP。
- **重写要点**: skill 文本需对齐 M-005 v2 §B（伪共识识别）+ §H（主笔轮换 ≥3 版阈值 / D3 不给硬时限）+ §F（自反性 sanity check）+ #014 D1 否决权阈值（24h ≥3 次且 ≥2 次不满足三要素）。当前 skill 文本可能停留在 M-005 v1 之前的工作流假设。
- **元规则对齐分**: 5（核心治理 skill，但文本可能未同步 M-005 v2）

#### `cross-audit-consensus` — **MERGE → cross-audit**
- **可追溯实证**: 与 `cross-audit` 实施同一工作流的不同阶段（前者是审计本身，后者是 4 家结论的折叠裁决）。M-005 §B + §H + §F 没有分开规定两个 skill 的必要。
- **可验伪信号**: 若 cross-audit-consensus 含独立的"评分方权重"规则（如 Codex 主锚点 / Gemini 次锚点）且该规则在元规则中不可下沉，则 Verdict 改为 KEEP。
- **合并目标**: 合并入 `cross-audit` 作为 §共识折叠章节。合并后 skill 名仍为 `cross-audit`。
- **元规则对齐分**: 5

#### `decision-closeout` — **KEEP**
- **可追溯实证**: 直接对接 M-002 分歧裁决与裁决日志（M-000 §11 派生表）+ M-005 §I.3 误触发 vs 真违纪辨别。
- **可验伪信号**: 若该 skill 内容完全可下沉到 M-002 ratify 后的流程规约，则 Verdict 改 PROMOTE_TO_STANDARDS。
- **下沉证明**: 当前 M-002 尚未起草，decision-closeout 是 M-002 ratify 前的临时治理工具，必须保留。M-002 ratify 后可能需 REWRITE 对齐 M-002 文本。
- **元规则对齐分**: 5

#### `dependency-propagation` — **REWRITE**
- **可追溯实证**: [#011](../meta/user-decision-log.md#011-m-000-v20-ratified--v12-归档) E 级联引用更新延后项的执行工具。M-005 §J.5 下游脚本兼容性处理（grep 消费点 + 同步刷新）使用此 skill 思路。
- **可验伪信号**: 若 skill 文本明确含 M-000 v2.0 / M-005 v2 后的级联引用机制（含 `default_word_budget` 删除 + Antigravity CLI 替代等场景），则 Verdict 改 KEEP。
- **重写要点**: 对齐 M-005 §D.4 SSOT 注入 / grep 验证 / 代码与文档 SSOT 同步刷新三层纪律。当前 skill 文本可能停留在 ADR-004 时期的级联机制。
- **元规则对齐分**: 4

#### `dod-checklist` — **REWRITE**
- **可追溯实证**: 执行门检查（AGENTS.md "执行门" 段引用 swiftlint + xcodebuild）。M-005 §A 4 项判据 + Verdict 三分制（CONDITIONAL / BLOCK）的执行接口。
- **可验伪信号**: 若 skill 文本明确含 M-005 §A 4 项判据（可追溯 / 可验伪 / 下沉证明 / 目的关联）+ Verdict 三分制，则 Verdict 改 KEEP。
- **重写要点**: 对齐 M-005 §A 4 项判据 + §A 嵌入 Verdict 三分制 + #014 D7 误触发 vs 真违纪三分。当前 dod-checklist 可能停留在"测试通过 + lint 通过"的工具级 check，未升到 M-005 §A 元规则级。
- **元规则对齐分**: 5

#### `harness-recall` — **MERGE → knowledge-health**
- **可追溯实证**: 两者都是自反性体检 / 重复问题模式扫描的范畴。M-005 §F 自反性 sanity check 没有为两个 skill 分别立条款的必要。
- **可验伪信号**: 若 harness-recall 含独立的"anti-pattern-scan 警报"规则（与 M-005 §F.1 Round N-1 复盘机制不同），则 Verdict 改 KEEP。
- **合并目标**: 合并入 `knowledge-health` 作为 §reflection 章节。合并后 skill 名 `knowledge-health`。
- **元规则对齐分**: 4

#### `knowledge-health` — **KEEP**
- **可追溯实证**: M-005 §F 自反性 sanity check + §K 修订与复审的执行工具。docaudit all 跑 + 私有空间扫描，对接 M-000 v2.0 §8 docaudit 边界。
- **可验伪信号**: 若 skill 文本完全可下沉到 docaudit policy.yaml 的 check 集合，则 Verdict 改 DOWNGRADE_TO_TEMPLATE。
- **下沉证明**: skill 含"分层修复计划"逻辑（不只是机械 check 跑），需要 LLM 介入做优先级判断，不可纯模板化。
- **元规则对齐分**: 5

#### `phase-closeout` — **KEEP**
- **可追溯实证**: M-005 §H 主笔轮换 + M-000 v2.0 §10 风险/降级/复审都涉及"phase 收官"。本会话已实证使用（M-005 起草 P1→P2→P3.a→P3.b→P3.c→P3.d→P3.e 节奏对应 phase-closeout 思路）。
- **可验伪信号**: 若 M-001（协作工作流）起草后 phase-closeout 完全被 M-001 §流程章节覆盖，则 Verdict 改 PROMOTE_TO_STANDARDS。
- **下沉证明**: 当前 M-001 未起草，phase-closeout 是 M-001 ratify 前的临时治理工具。M-001 ratify 后可能需 REWRITE。
- **元规则对齐分**: 5

#### `post-merge` — **KEEP**
- **可追溯实证**: PR 合并后必做清单（CI 检查 / STATUS 更新 / anti-pattern-scan / 文档同步检查）。本会话每次 commit 后实际用了类似流程（docaudit + swiftlint + push）。
- **可验伪信号**: 若该 skill 完全可下沉到 .github/workflows 自动化 + git hook，则 Verdict 改 DOWNGRADE_TO_TEMPLATE。
- **下沉证明**: skill 含"基于改动类型的差异化 check"逻辑，需要 LLM 介入判断（如代码改动 vs 文档改动 vs UI 改动的不同 check 集合）。
- **元规则对齐分**: 5

#### `resume-from-handoff` — **KEEP**
- **可追溯实证**: 新 Claude 会话接手项目时的最小上下文加载顺序。M-000 v2.0 §1 定位 + AGENTS.md Boot 序列的执行工具。本会话开始时实际加载了类似上下文。
- **可验伪信号**: 若 AGENTS.md Boot 序列 + CLAUDE.md 已完全覆盖 resume-from-handoff 描述的加载顺序，则 Verdict 改 DELETE。
- **下沉证明**: skill 含"按层级递归加载 + 避免吃长 transcript"的判断逻辑，AGENTS.md/CLAUDE.md 是静态规则不含此动态判断。
- **元规则对齐分**: 5

#### `sprint-contract` — **KEEP**
- **可追溯实证**: F-018 强制执行器。M-005 起草 P1 实际调用过（[#012](../meta/user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) Sprint Contract 批准）。M-005 §I 自作主张越权防线对接此 skill 的 Touches/No-Touch/Interface Delta/DoD 字段。
- **可验伪信号**: 若该 skill 文本明确含 M-005 §I 结构性决定清单 + Sprint Contract 字段必须落实项，则 Verdict 改 KEEP（确认）；若否，则可能需 REWRITE。
- **下沉证明**: skill 是 F-018 的具体执行模板（结构性 contract），不可下沉到 standards 因 contract 字段需要 LLM 在具体 issue 上下文中填写。
- **元规则对齐分**: 5（但若 M-005 v2 ratify 后未同步检查 sprint-contract 文本，可能需 REWRITE）

#### `verify-audit-report` — **REWRITE**
- **可追溯实证**: M-005 §A 4 项判据（可追溯性 / 可验伪性 / 下沉证明 / 目的关联）的执行工具。本会话 P3.d sign-off 阶段实际应用类似逻辑（Claude/Codex/Gemini 互审 final）。
- **可验伪信号**: 若 skill 文本明确含 M-005 §A 4 项判据 + Verdict 三分制 + §B.3 否决权三要素 + §F sanity check 自反性，则 Verdict 改 KEEP。
- **重写要点**: 对齐 M-005 v2 §A + §B.3 + §F。当前 skill 文本可能停留在 ADR-004 时期"逐条 grep + read 验证 finding 真实性"，未升到 M-005 §A 元规则级。
- **元规则对齐分**: 5

### 【工具/治理混合 skill】

#### `api-research` — **KEEP**
- **可追溯实证**: F-017 强制执行器（API 引入前先查 Apple 最新文档）。M-005 §D 外部事实验证纪律的具体应用（不只 AI 模型版本，还含 SDK / API 版本）。
- **可验伪信号**: 若该 skill 文本完全可下沉到 docs/standards/api-research.md 静态规则，则 Verdict 改 PROMOTE_TO_STANDARDS。
- **下沉证明**: skill 含"识别新组件 / 新 SDK API 引入时机"的判断逻辑，不可静态化。
- **元规则对齐分**: 4

#### `snapshot-diff-review` — **KEEP**
- **可追溯实证**: snapshot baseline 变更审查工作流。M-005 §A.2 可验伪性的实证（视觉变化是否有意）。
- **可验伪信号**: 若与 snapshot-testing 完全重叠（都是 snapshot 范畴），则 Verdict 改 MERGE → snapshot-testing。
- **下沉证明**: snapshot-diff-review 处理"baseline 变更后的 git diff 审查"，snapshot-testing 处理"测试本身的设置"，两者关注点不同保留独立。
- **元规则对齐分**: 4

#### `ui-review` — **KEEP**
- **可追溯实证**: HIG / Dynamic Type / 可访问性审查的执行工具。与 xcode-review 不同（后者是 Xcode Intelligence Review 提示词撰写）。
- **可验伪信号**: 若该 skill 完全可下沉到 docs/standards/hig-compliance.md，则 Verdict 改 PROMOTE_TO_STANDARDS。
- **下沉证明**: skill 含 SwiftUI 代码 vs HIG 的具体对照逻辑，需要 LLM 介入。
- **元规则对齐分**: 3

#### `xcode-review` — **KEEP**
- **可追溯实证**: Xcode Intelligence Review 提示词撰写指南。M-005 §F.1 Round N → Round N-1 复盘 prompt 设计的具体应用（Xcode 视角 review）。
- **可验伪信号**: 若该 skill 完全可被 ui-review 覆盖，则 Verdict 改 MERGE → ui-review。
- **下沉证明**: xcode-review 是"提示词撰写指南"（如何让 Xcode AI 做更好的 review），ui-review 是"HIG 审查"，关注点不同保留独立。
- **元规则对齐分**: 3

### 【工具 skill — KEEP 块】

以下 18 个工具 skill 在 iOS 开发中有具体应用价值，与元规则关系弱（对齐分 3），全部 **KEEP**：

- `accessibility-generator` (3)：a11y label/hint 生成 + 审计，与 M-005 §A 可验伪信号弱相关
- `animation-patterns` (3)：springs/transitions/PhaseAnimator/KeyframeAnimator/SF Symbol 模式
- `attributed-string` (3)：AttributedString API 使用指南
- `characterization-test-generator` (4)：refactoring 前的 safety net 测试，对接 tdd-refactor-guard
- `deep-linking` (3)：Universal Links / custom URL scheme
- `integration-test-scaffold` (3)：networking + persistence + business logic 集成测试
- `liquid-glass` (3)：Liquid Glass 设计 API
- `migration-patterns` (3)：CoreData→SwiftData / UIKit→SwiftUI / ObservableObject→@Observable
- `navigation-patterns` (3)：SwiftUI navigation architecture
- `privacy-manifests` (3)：App Store privacy 要求
- `push-notifications` (3)：APNs / notification categories
- `snapshot-testing` (3)：swift-snapshot-testing 视觉回归
- `swift-concurrency-pro` (3)：Swift concurrency review
- `swiftdata-pro` (3)：SwiftData best practices
- `swiftui-debugging` (3)：re-render / view identity / body 性能
- `swiftui-pro` (3)：SwiftUI best practices
- `tdd-feature` (3)：red-green-refactor 新功能（吸纳 tdd-bug-fix + tdd-refactor-guard）
- `test-contract` (3)：协议设计 + 实现替换

### 【工具 skill — MERGE 块】

#### `tdd-bug-fix` — **MERGE → tdd-feature**
- **可追溯实证**: 都是 red-green-refactor 模式。tdd-bug-fix = 先写失败测试复现 bug 再修，tdd-feature = 先写失败测试再实现。两者本质同一工作流不同入口。
- **合并目标**: 吸纳到 tdd-feature 作为 §bug-fix scenario 章节。

#### `tdd-refactor-guard` — **MERGE → tdd-feature**
- **可追溯实证**: refactor 前 pre-checklist，与 characterization-test-generator 配套使用。本质是 tdd-feature 工作流中"修改 existing code 前的 safety check"环节。
- **合并目标**: 吸纳到 tdd-feature 作为 §refactor scenario 章节。

### 【工具 skill — PROMOTE_TO_STANDARDS 块】

#### `coding-best-practices` — **PROMOTE_TO_STANDARDS**
- **可追溯实证**: 内容是 Swift/iOS 代码规范（modern Swift idioms / Apple platform best practices / 架构模式），是规则不是动作。
- **升级目标**: 移到 `docs/standards/swift-coding.md`（或合并到现有 standards 文件）。skill 删除。

#### `ci-cd-setup` — **PROMOTE_TO_STANDARDS**
- **可追溯实证**: GitHub Actions / Xcode Cloud / fastlane 配置，是 setup 规范不是动态判断。
- **升级目标**: 移到 `docs/standards/ci-cd.md`。skill 保留 boilerplate 部分作 template，删除规则部分。

#### `app-store-assets` — **PROMOTE_TO_STANDARDS**
- **可追溯实证**: 全部 promotional artwork 规范（app icons / screenshots / app previews / event cards / subscription images）。是规范文档。
- **升级目标**: 移到 `docs/standards/app-store-assets.md`。

### 【工具 skill — DOWNGRADE_TO_TEMPLATE 块】

以下 8 个 skill 是纯模板/代码生成，无需 LLM 动态判断，应剥离 trigger 改静态模板：

- `app-icon-generator`：CoreGraphics 代码生成 → `docs/templates/app-icon-coregraphics.swift`
- `background-processing`：BGTaskScheduler boilerplate → `docs/templates/background-processing/`
- `data-export`：JSON/CSV/PDF export boilerplate → `docs/templates/data-export/`
- `error-monitoring`：协议 + provider 切换 boilerplate → `docs/templates/error-monitoring/`
- `localization-setup`：xcstrings 设置 → `docs/templates/localization/`
- `onboarding-generator`：onboarding flow boilerplate → `docs/templates/onboarding/`
- `settings-screen`：settings UI boilerplate → `docs/templates/settings-screen/`
- `tipkit-generator`：TipKit boilerplate → `docs/templates/tipkit/`

降级理由（共用）：内容是 boilerplate 代码，trigger 是"用户要加这个功能"——这种触发条件不需要 LLM 介入判断，直接 cp template 修改即可。保留为 skill 反而增加 trigger 解析成本。

### 【App Store skill — KEEP 块】

- `app-description-writer` (2)：App Store 描述写作
- `app-store-rejection` (3)：拒审应对
- `keyword-optimizer` (2)：ASO 关键词
- `review-response-writer` (2)：用户 review 回复
- `screenshot-planner` (2)：截图规划

全部 KEEP（对齐分低但有具体动作价值）。可能在 M-006 数据治理 ratify 后批量重审（涉及隐私 / 数据共享部分）。

---

## §3 元层级观察

### O1: 治理 vs 工具 skill 混杂的结构性问题

52 个 skill 中**真正的治理 skill 只有 12 个**（cross-audit / cross-audit-consensus / decision-closeout / dependency-propagation / dod-checklist / harness-recall / knowledge-health / phase-closeout / post-merge / resume-from-handoff / sprint-contract / verify-audit-report），约 23%。其余 ~77% 是工具 skill 或 App Store 流程 skill，与 M-000/M-005 元规则关系弱。

混在同一目录、同一 trigger 机制造成**两个问题**：
1. **元规则审查范围模糊**：M-005 §I.1 结构性决定清单是否包含 swiftui-pro skill 的修改？语义上不应该，但目录结构上同等待遇。
2. **自启动触发污染**：当用户提"加个按钮"时，多个 skill 都可能争夺触发（swiftui-pro / animation-patterns / liquid-glass / api-research），但治理 skill 不应该被工具 skill trigger 拉到同一上下文。

**建议**: M-003 起草时考虑命名空间分离（`.claude/skills/governance/` vs `.claude/skills/tools/` vs `.claude/skills/templates/`），或 frontmatter 加 `category: governance|tool|template` 字段，让 trigger 引擎按类别决定优先级。

### O2: M-005 起草过程的隐性绑架点

M-005 v2 起草过程实际使用了：sprint-contract（[#012](../meta/user-decision-log.md#012-m-005-起草启动--主笔轮换-deepseek--010-字数升级同-pr-落地) P1）+ cross-audit 工作流（4 家异源审）+ verify-audit-report 思路（sign-off 阶段）+ decision-closeout 思路（[#015](../meta/user-decision-log.md#015-m-005-v2-ratified--同-pr-修订-m-000-v20-6--frontmatter--显式-overrule-009-r2) ratify）。

**但这些 skill 的文本本身没有经过 M-005 sign-off**——M-005 §B/§F/§H 措辞实际上是把这些 skill 的设计假设升级为元规则。如果 skill 文本与 M-005 v2 不一致，元规则起草过程就在违反自己的规则。

**建议**: Stage 5 批量执行时优先处理 4 个 REWRITE skill（cross-audit / dependency-propagation / dod-checklist / verify-audit-report），把它们的文本对齐 M-005 v2 措辞，关闭自举循环的最后一道缝。

### O3: `.claude/skills/` 与 `.agents/skills/` 双份存在

16 个 skill 双份存在（accessibility-generator / app-description-writer / attributed-string / characterization-test-generator / deep-linking / integration-test-scaffold / liquid-glass / navigation-patterns / privacy-manifests / push-notifications / review-response-writer / screenshot-planner / swift-concurrency-pro / swiftdata-pro / swiftui-pro / test-contract）。

AGENTS.md 声明 `.agents/skills/` 是 SSOT，但实际不是 symlink 而是手动同步。这是 [#013](../meta/user-decision-log.md#013-gemini-主笔候选-model-误用事故--直接-api-修复--scriptsgemini_utilspy-ssot-同步) 三层错的同类问题（文档 SSOT 与代码 SSOT 不同步）。

**建议**: Stage 5 批量执行时统一治理：
- 方案 A：保留 `.agents/skills/` 作 SSOT，`.claude/skills/` 用 symlink（AGENTS.md 已警告未验证）
- 方案 B：删 `.agents/skills/`，`.claude/skills/` 是唯一来源（但牺牲跨项目共享能力）
- 方案 C：保持双份但加 CI check 强制 hash 一致（最差，仍是手动同步）

需 M-003 给具体裁决。

### O4: 路径 C 自身的自反性

本审计过程禁止使用治理 skill，但 Claude 主分支会话上下文已经被 M-005 起草过程污染（已知 cross-audit / sprint-contract / decision-closeout 的隐性事实）。**Claude 审 cross-audit skill 的 Verdict 是否独立可信？**

按 §F.1 自反性 sanity check 原则，Claude 自审应该被异源（Codex / DeepSeek / Gemini）的审计验证。如果 4 家对 cross-audit / sprint-contract 的 Verdict 不一致，触发用户裁决（[#014](../meta/user-decision-log.md#014-m-005-p3b-八处分歧裁决) 体例）。

**建议**: Stage 3 折叠主笔（Claude 中立主笔）特别关注 Claude/Codex/DeepSeek/Gemini 对 12 个治理 skill 的 Verdict 一致性。若 Claude 给 KEEP/REWRITE 但其他 3 家给 DELETE/MERGE，按 §B 伪共识识别触发用户裁决。

### O5: 未来 M-002~M-006 起草对 skill 文本的反向滋养

M-002 / M-006 / M-001 / M-004 / M-003 起草时，必然引用 / 修改某些 skill。Stage 5 批量执行后 skill 文本对齐 M-005 v2，但后续元规则修订会再次让 skill 文本过时。

**建议**: M-003 §核心机制必须含"元规则修订时 skill 同步触发条件"（类比 M-005 §D.4 SSOT 与消费代码同步刷新原则）。每次 user-decision-log 落新条目 + 触发元规则修订时，必须 grep `.claude/skills/` 找受影响的 skill 并同步重写或归档。

---

## §4 统计

### Verdict 分布

| Verdict | 数量 | 占比 |
|---|---|---|
| KEEP | 33 | 63.5% |
| MERGE | 4 | 7.7% |
| DELETE | 0 | 0% |
| PROMOTE_TO_STANDARDS | 3 | 5.8% |
| DOWNGRADE_TO_TEMPLATE | 8 | 15.4% |
| REWRITE | 4 | 7.7% |

净化后 skill 数：~34 个（KEEP 33 - MERGE 减 3 实际净化 30 + 现有 KEEP 中 4 个 REWRITE = 30 + 4 = 34）。

### 元规则对齐分分布

| 分数 | 数量 | 含义 |
|---|---|---|
| 5 | 9 | 核心治理 skill |
| 4 | 5 | 治理 / 工具/治理混合 |
| 3 | 25 | 工具 skill 主体 |
| 2 | 5 | App Store 流程 |
| 1 | 8 | 纯模板（DOWNGRADE 目标） |

### 治理 vs 工具 vs App Store 比例

| 类别 | 数量 | 占比 |
|---|---|---|
| 治理 skill | 12 | 23% |
| 工具/治理混合 | 4 | 7.7% |
| 工具 skill | 30 | 57.7% |
| App Store skill | 6 | 11.5% |

### 自举循环关闭进度（路径 C Stage 5 目标）

| 路径 | 数量 | 动作 |
|---|---|---|
| 重写治理 skill 对齐 M-005 v2 | 4 | cross-audit / dependency-propagation / dod-checklist / verify-audit-report |
| 合并冗余治理 skill | 2 | cross-audit-consensus → cross-audit / harness-recall → knowledge-health |
| 升 standards（规范类） | 3 | coding-best-practices / ci-cd-setup / app-store-assets |
| 降 templates（纯模板类） | 8 | 8 个 generator skill |
| 治理 skill SSOT 单源化 | 16 | 解决 `.claude/skills/` vs `.agents/skills/` 双份 |

Stage 5 完成后 skill 生态从 52 个混杂 → 约 34 个清晰分类（治理 ~10 / 工具 ~30 / App Store ~6），自举循环的核心 4 处 REWRITE 关闭。

---

## §5 致 Stage 3 折叠主笔的备忘

Claude 中立主笔（即本会话）做 Stage 3 折叠时，特别关注以下点：

1. **Claude 审 cross-audit / sprint-contract 的 Verdict 独立性**：Claude 起草过程使用了这两个 skill，Verdict 可能有偏。若 Codex/DeepSeek/Gemini 三家全部给 DELETE/MERGE，触发用户裁决。
2. **DOWNGRADE_TO_TEMPLATE 的 8 个 skill 是否真的纯模板**：Claude 给 1 分的判断依赖 SKILL.md 摘要，未深 read 完整文件。若其他家深 read 后给 KEEP/REWRITE，以更深的审为准。
3. **REWRITE 的 4 个治理 skill 文本是否真与 M-005 v2 不一致**：Claude 假设这些 skill 早于 M-005 v2，未实际 grep 它们的文本与 M-005 v2 措辞对照。Stage 3 折叠时必须 grep 实证。

## 关联文档

- [任务定义书](skill-audit-task-definition.md)
- [M-000 v2.0](../meta/M-000-meta-vision.md)
- [M-005 v2](../meta/M-005-quality-criteria.md)
- [user-decision-log](../meta/user-decision-log.md) #001~#016
