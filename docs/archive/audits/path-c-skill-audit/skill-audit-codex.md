---
last_verified: 2026-05-25
layer: snapshot
scope: skill-audit
freshness:
  max_age_days: 30
  decay_trigger: [skill_audit_ratified]
override_rationale: "本报告是路径 C Stage 2 的完整独立审计产物，必须逐一覆盖 52 个 .claude/skills/*/SKILL.md，并为每个 Verdict 写明可追溯实证、可验伪信号、适用的下沉/合并/升级/重写字段、元规则对齐分与使用频率估计。若压缩为只给矩阵，会丢失 M-005 §A 要求的可追溯性与可验伪性；若拆成多个文件，会增加 Stage 3 机械比对成本。本报告不使用治理 skill，不引用其他三家产物；正文长度由 52 项逐条证据密度决定。"
---

# Codex Skill 生态审计报告

## 审计边界

- 输入边界：已读 `docs/audits/skill-audit-task-definition.md`、`docs/meta/M-000-meta-vision.md`、`docs/meta/M-005-quality-criteria.md`、`docs/meta/user-decision-log.md`、`docs/protocol.md` 与 52 个 `.claude/skills/*/SKILL.md`。
- 禁止材料：未读取 `docs/audits/skill-audit-claude.md` / `skill-audit-deepseek.md` / `skill-audit-gemini.md`。
- 禁止工具：未调用 sprint-contract / cross-audit / verify-audit-report / dod-checklist / decision-closeout / phase-closeout / post-merge / dependency-propagation / resume-from-handoff / knowledge-health / harness-recall。
- 元规则基线：M-000 P1-P8（`docs/meta/M-000-meta-vision.md:31-38`）、M-005 §A 四项判据（`docs/meta/M-005-quality-criteria.md:66-99`）、#016 路径 C（`docs/meta/user-decision-log.md:233-243`）。

## 1. 总结表

| # | skill | 分类 | Verdict | 目标 / 处置摘要 | 对齐分 | 频率 |
|---:|---|---|---|---|---:|---|
| 1 | accessibility-generator | 工具 | MERGE | 合并到 `.agents/skills/accessibility-generator` | 3 | 中 |
| 2 | animation-patterns | 工具 | MERGE | 合并到 `swiftui-pro` 的 animation reference | 3 | 中 |
| 3 | api-research | 治理 | REWRITE | 改写为 M-005 §D / #002 外部事实验证执行器 | 4 | 高 |
| 4 | app-description-writer | 工具 | MERGE | 合并到 `.agents/skills/app-description-writer` | 3 | 低 |
| 5 | app-icon-generator | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/app-store/app-icon-generation.md` | 2 | 低 |
| 6 | app-store-assets | 工具 | PROMOTE_TO_STANDARDS | 升到 `docs/standards/app-store-assets.md` | 3 | 低 |
| 7 | app-store-rejection | 工具 | PROMOTE_TO_STANDARDS | 升到 `docs/standards/app-store-review.md` | 3 | 低 |
| 8 | attributed-string | 工具 | MERGE | 合并到 `.agents/skills/attributed-string` | 3 | 中 |
| 9 | background-processing | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/ios/background-processing.md` | 2 | 低 |
| 10 | characterization-test-generator | 工具 | MERGE | 合并到 `.agents/skills/characterization-test-generator` | 3 | 中 |
| 11 | ci-cd-setup | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/ci/ios-ci.md` | 2 | 低 |
| 12 | coding-best-practices | 工具 | PROMOTE_TO_STANDARDS | 升到 `docs/standards/engineering.md` | 3 | 中 |
| 13 | cross-audit | 治理 | REWRITE | 改写为 M-000 P1/P3/P5 与 M-005 §B/F 执行器 | 3 | 中 |
| 14 | cross-audit-consensus | 治理 | REWRITE | 删除多数票默认，改为分歧折叠 + 用户裁决接口 | 2 | 中 |
| 15 | data-export | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/features/data-export.md` | 2 | 低 |
| 16 | decision-closeout | 治理 | REWRITE | 改写为 P2 / M-005 §I 结构性决定闭环 | 3 | 中 |
| 17 | deep-linking | 工具 | MERGE | 合并到 `.agents/skills/deep-linking` | 3 | 中 |
| 18 | dependency-propagation | 治理 | PROMOTE_TO_STANDARDS | 升到 `docs/standards/dependency-propagation.md` 或并入 `DOC_DEPENDENCY_MAP.md` | 3 | 中 |
| 19 | dod-checklist | 治理 | PROMOTE_TO_STANDARDS | 升到 `docs/standards/execution-gates.md` | 3 | 高 |
| 20 | error-monitoring | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/observability/error-monitoring.md` | 2 | 低 |
| 21 | harness-recall | 治理 | REWRITE | 改写为 M-005 §G + M-003 skill/check 退役机制 | 2 | 低 |
| 22 | integration-test-scaffold | 工具 | MERGE | 合并到 `.agents/skills/integration-test-scaffold` | 3 | 中 |
| 23 | keyword-optimizer | 工具 | DELETE | 删除或归档；ASO 策略不应常驻触发 | 1 | 低 |
| 24 | knowledge-health | 治理 | REWRITE | 去固定文件数阈值，改为 M-000 §6 / §8 软信号 | 2 | 中 |
| 25 | liquid-glass | 工具 | MERGE | 合并到 `.agents/skills/liquid-glass` | 3 | 中 |
| 26 | localization-setup | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/ios/localization.md` | 2 | 低 |
| 27 | migration-patterns | 工具 | PROMOTE_TO_STANDARDS | 升到 `docs/standards/migration-patterns.md` | 3 | 中 |
| 28 | navigation-patterns | 工具 | MERGE | 合并到 `.agents/skills/navigation-patterns` | 3 | 中 |
| 29 | onboarding-generator | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/features/onboarding.md` | 2 | 低 |
| 30 | phase-closeout | 治理 | REWRITE | 改写为 current Boot/Action Gate 后的 checkpoint 模板 | 2 | 中 |
| 31 | post-merge | 治理 | REWRITE | 改写为显式授权后的 merge/postmerge 流程 | 2 | 中 |
| 32 | privacy-manifests | 工具 | MERGE | 合并到 `.agents/skills/privacy-manifests` | 3 | 中 |
| 33 | push-notifications | 工具 | MERGE | 合并到 `.agents/skills/push-notifications` | 3 | 低 |
| 34 | resume-from-handoff | 治理 | REWRITE | 按 #006 Boot=2 文件重写 | 1 | 高 |
| 35 | review-response-writer | 工具 | MERGE | 合并到 `.agents/skills/review-response-writer` | 3 | 低 |
| 36 | screenshot-planner | 工具 | MERGE | 合并到 `.agents/skills/screenshot-planner` | 3 | 低 |
| 37 | settings-screen | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/features/settings-screen.md` | 2 | 低 |
| 38 | snapshot-diff-review | 工具 | KEEP | 保留为二进制 baseline 人工判读执行器 | 4 | 低 |
| 39 | snapshot-testing | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/testing/snapshot-testing.md` | 2 | 低 |
| 40 | sprint-contract | 治理 | REWRITE | 改写为 M-001/M-005 对齐的开工契约 | 3 | 高 |
| 41 | swift-concurrency-pro | 工具 | MERGE | 合并到 `.agents/skills/swift-concurrency-pro` | 4 | 高 |
| 42 | swiftdata-pro | 工具 | MERGE | 合并到 `.agents/skills/swiftdata-pro` | 4 | 中 |
| 43 | swiftui-debugging | 工具 | MERGE | 合并到 `swiftui-pro` / performance reference | 3 | 中 |
| 44 | swiftui-pro | 工具 | MERGE | 合并到 `.agents/skills/swiftui-pro` | 4 | 高 |
| 45 | tdd-bug-fix | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/testing/tdd-bug-fix.md` | 2 | 中 |
| 46 | tdd-feature | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/testing/tdd-feature.md` | 2 | 中 |
| 47 | tdd-refactor-guard | 工具 | MERGE | 合并到 `characterization-test-generator` | 3 | 中 |
| 48 | test-contract | 工具 | MERGE | 合并到 `.agents/skills/test-contract` | 3 | 中 |
| 49 | tipkit-generator | 工具 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/features/tipkit.md` | 2 | 低 |
| 50 | ui-review | 工具 | MERGE | 合并到 `swiftui-pro` / design-accessibility references | 3 | 中 |
| 51 | verify-audit-report | 治理 | REWRITE | 改写为 M-005 §A/F 审计 finding 验证执行器 | 4 | 中 |
| 52 | xcode-review | 治理 | DOWNGRADE_TO_TEMPLATE | 移为 `docs/templates/review/xcode-review-prompt.md` | 2 | 中 |

## 2. Verdict 详情

### `accessibility-generator`

- **Verdict**: MERGE
- **可追溯实证**: 该文件声明自己只是 Claude adapter，真实来源是 `../../../.agents/skills/accessibility-generator/SKILL.md`（`.claude/skills/accessibility-generator/SKILL.md:3`, `.claude/skills/accessibility-generator/SKILL.md:9-13`）。#016 指出 `.claude/skills/` 与 `.agents/skills/` 16 个双份存在疑似同步漂移（`docs/meta/user-decision-log.md:238`）；M-000 §6 要求执行步骤/模板应下沉（P7/P5 相关）。
- **可验伪信号**: 若证明 Claude discovery 只能通过实体 adapter 文件工作，且 symlink/manifest 会导致该 skill 不可发现，则 MERGE 应改为 KEEP with adapter。
- **合并目标**: `.agents/skills/accessibility-generator`，合并后 skill 名保持 `accessibility-generator`，`.claude` 只保留机器生成发现入口。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `animation-patterns`

- **Verdict**: MERGE
- **可追溯实证**: 它定位为 SwiftUI animation reference（`.claude/skills/animation-patterns/SKILL.md:3`, `.claude/skills/animation-patterns/SKILL.md:9`），触发条件与 SwiftUI review/write 场景重叠（`.claude/skills/animation-patterns/SKILL.md:13-22`）；`swiftui-pro` 已覆盖 SwiftUI views/animations/performance review（`.claude/skills/swiftui-pro/SKILL.md:14-20`）。M-005 §A.3 要求能说明不能下沉；此处内容是 reference file decision tree，不需要独立常驻 trigger。
- **可验伪信号**: 若发现 animation 事故高频发生且 `swiftui-pro` 无法有效加载该 reference，导致独立 skill 显著减少错误，则 MERGE 可改 KEEP。
- **合并目标**: `swiftui-pro`，新增 `references/animations.md` 或等价 section。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `api-research`

- **Verdict**: REWRITE
- **可追溯实证**: 该 skill 是 F-017 执行器（`.claude/skills/api-research/SKILL.md:3`, `.claude/skills/api-research/SKILL.md:15`），目标与 #002 外部事实实时验证、M-005 §D 外部事实纪律一致；但 F 编号与旧 `feedback.md` 权威源仍写在 skill 内（`.claude/skills/api-research/SKILL.md:102`），应改为 M-005 §D / #002 / Apple 官方来源边界。M-000 P7 要求净化提示词，当前 trigger “加个按钮/改样式”过宽（`.claude/skills/api-research/SKILL.md:3`, `.claude/skills/api-research/SKILL.md:23-27`）。
- **可验伪信号**: 若 F-017 已在 current standards 中被明确保留为 active SSOT 且 M-005 §D 指向 F-017 skill，则可降为 KEEP。
- **重写要点**: 删除 “F-017 权威执行器” 和 `docs/memory/feedback.md` 权威源；改为 “M-005 §D / #002 外部事实验证执行器”。Trigger 改成“新增或修改可能受 Apple 平台版本影响的 API/组件”而不是所有 UI 样式动作。
- **元规则对齐分**: 4
- **使用频率估计**: 高

### `app-description-writer`

- **Verdict**: MERGE
- **可追溯实证**: 文件明确为 shared skill adapter，指向 `.agents/skills/app-description-writer`（`.claude/skills/app-description-writer/SKILL.md:3`, `.claude/skills/app-description-writer/SKILL.md:9-13`）。#016 将双份存在列为待解决结构问题；M-000 §6 反对重复权威定义。
- **可验伪信号**: 若 shared source 不含 Claude Code 所需执行细节，且 adapter 本身承载不可替代约束，则 MERGE 不成立。
- **合并目标**: `.agents/skills/app-description-writer`，保留单一 SSOT。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `app-icon-generator`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它生成 CoreGraphics app icon、写入 asset catalog（`.claude/skills/app-icon-generator/SKILL.md:3`, `.claude/skills/app-icon-generator/SKILL.md:9`），主体是项目探测、问题收集、脚本生成（`.claude/skills/app-icon-generator/SKILL.md:19-45`）。M-005 §A.3 规定纯操作步骤/模板/脚本应下沉。
- **可验伪信号**: 若后续证明 icon 生成必须结合品牌策略、多轮视觉评审和外部资产验证，且静态模板无法覆盖，则应改 REWRITE 或 KEEP。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `app-store-assets`

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: 内容是 App Store promotional artwork specs/checklist（`.claude/skills/app-store-assets/SKILL.md:3`, `.claude/skills/app-store-assets/SKILL.md:7-9`），且输出是按平台定制 checklist（`.claude/skills/app-store-assets/SKILL.md:21-44`）。它更像标准/规格索引而非需要独立 LLM trigger 的执行器。M-005 §A.3 要求规则和 checklist 下沉。
- **可验伪信号**: 若该 skill 内存在动态 App Store Connect API 查询、自动资产验证或上传流程，且不能由 standards 表达，则应改 REWRITE。
- **升级目标**: `docs/standards/app-store-assets.md`。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `app-store-rejection`

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: 它处理 App Review rejection 与 appeal（`.claude/skills/app-store-rejection/SKILL.md:3`, `.claude/skills/app-store-rejection/SKILL.md:7-9`），核心依赖 common rejection checklist（`.claude/skills/app-store-rejection/SKILL.md:23-33`）。App Review guideline 事实易变，M-005 §D 要求外部事实验证；常驻 skill 容易固化过期 guideline。
- **可验伪信号**: 若仓库有真实 rejection incident 要求逐案生成 Resolution Center 回复，且该 skill 保留最新官方链接刷新机制，则可改 KEEP。
- **升级目标**: `docs/standards/app-store-review.md`，仅保留流程和官方来源刷新要求。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `attributed-string`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared AttributedString adapter（`.claude/skills/attributed-string/SKILL.md:3`, `.claude/skills/attributed-string/SKILL.md:9-13`）。#016 明确双份存在是 skill 生态结构问题。
- **可验伪信号**: 若 `.agents` shared skill 缺少 Claude-specific tooling 权限或上下文加载规则，则合并目标需保留一个生成型 wrapper。
- **合并目标**: `.agents/skills/attributed-string`。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `background-processing`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它生成 BGTaskScheduler、background URLSession、silent push 基础设施（`.claude/skills/background-processing/SKILL.md:3`, `.claude/skills/background-processing/SKILL.md:7-9`），流程主要是预检查和模板化生成（`.claude/skills/background-processing/SKILL.md:22-45`）。M-000 §6 将操作步骤/模板列为应下沉对象。
- **可验伪信号**: 若 SnapDrill 产品路线确认需要后台处理且有复杂平台限制事故，模板不足以避免错误，则应改 PROMOTE_TO_STANDARDS 或 REWRITE。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `characterization-test-generator`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared characterization test generator adapter（`.claude/skills/characterization-test-generator/SKILL.md:3`, `.claude/skills/characterization-test-generator/SKILL.md:9-13`）。它与 `tdd-refactor-guard` 的“refactor 前生成 characterization tests”职责重叠（`.claude/skills/tdd-refactor-guard/SKILL.md:7-9`）。
- **可验伪信号**: 若 `tdd-refactor-guard` 需要独立 gate，而 shared generator 只负责代码片段，则合并应拆为标准 gate + generator。
- **合并目标**: `.agents/skills/characterization-test-generator`，并吸收 `tdd-refactor-guard` 的 refactor 前置判断。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `ci-cd-setup`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它生成 CI/CD config（`.claude/skills/ci-cd-setup/SKILL.md:3`, `.claude/skills/ci-cd-setup/SKILL.md:7-9`），主体是查 existing CI、项目结构、包管理器后生成模板（`.claude/skills/ci-cd-setup/SKILL.md:18-45`）。SnapDrill 已有执行门由 AGENTS/protocol 指向 `swiftlint` 与 `AllTests`，CI 生成不应常驻触发。
- **可验伪信号**: 若后续 CI 平台迁移需要多轮判断、凭证处理和远端状态验证，则模板不足，需 REWRITE 为 migration proposal。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `coding-best-practices`

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: 它是 Swift/iOS code review best-practices 集合（`.claude/skills/coding-best-practices/SKILL.md:3`, `.claude/skills/coding-best-practices/SKILL.md:29-37`），与 `swiftui-pro`、`swiftdata-pro`、`swift-concurrency-pro` domain skills 重叠。M-000 §6 说规则/检查脚本/例子应下沉；M-005 §A.3 要求说明不可下沉。
- **可验伪信号**: 若其中某些规则被证明只能在 LLM review 运行时动态组合且 standards 无法承载，则可拆为 KEEP 子 skill。
- **升级目标**: `docs/standards/engineering.md`，domain-specific 部分分别并入 SwiftUI/SwiftData/concurrency references。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `cross-audit`

- **Verdict**: REWRITE
- **可追溯实证**: 它强制 Claude+Codex+Gemini 三方审查（`.claude/skills/cross-audit/SKILL.md:3`, `.claude/skills/cross-audit/SKILL.md:38-45`），且以 F-008/F-011/F-012 为纪律（`.claude/skills/cross-audit/SKILL.md:24-28`）。M-000 P1/P3/P5 已把“相同完整任务、默认多方异源、物理隔离”提升为 PRIMARY；#016 又明确本次审计禁止用 cross-audit 审 skill（`docs/audits/skill-audit-task-definition.md:99-107`）。
- **可验伪信号**: 若 Stage 3 ratify 决定 F-008 等旧 F 规则仍是 active SSOT，且固定三方名单仍符合当前异源定义，则可降为 KEEP。
- **重写要点**: 删除固定 vendor 名单和 F-rule 权威表述；改为读取任务定义给定的独立方集合；把只读/完整任务/隔离/净化输入映射到 M-000 P1/P3/P5/P7 与 M-005 §B；明确“不得用于审计治理 skill 自身，除非任务定义显式允许”。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `cross-audit-consensus`

- **Verdict**: REWRITE
- **可追溯实证**: 它把三方输出折成共识/独有/冲突（`.claude/skills/cross-audit-consensus/SKILL.md:3`, `.claude/skills/cross-audit-consensus/SKILL.md:17-21`），但写有“2/3 共识默认采纳”（`.claude/skills/cross-audit-consensus/SKILL.md:45-48`）和硬 retry 分数（`.claude/skills/cross-audit-consensus/SKILL.md:64-68`）。M-000 §3 明确多方价值不在多数投票，M-000 P2 规定用户最高裁决权，M-005 §B.3 规定异源反对需按三要素判断。
- **可验伪信号**: 若用户在 #017 ratify 明确保留 2/3 majority 作为某类低风险任务自动采纳规则，则该 rewrite 边界需缩小。
- **重写要点**: 删除“2/3 默认采纳”和综合分硬合并；改为 Verdict matrix、证据强度、异源反对三要素、需用户裁决冲突清单。分数最多作为退化/覆盖率信号，不作裁决。
- **元规则对齐分**: 2
- **使用频率估计**: 中

### `data-export`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它生成 JSON/CSV/PDF export/import、GDPR data portability、share sheet 等基础设施（`.claude/skills/data-export/SKILL.md:3`），属于功能模板与代码 scaffolding。M-005 §A.3 将操作步骤、模板、例子列为下沉对象。
- **可验伪信号**: 若 SnapDrill 的数据导出涉及真实合规裁决、隐私承诺或跨 profile 风险，需升级为 product/architecture ADR 或 standards，而不是模板。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `decision-closeout`

- **Verdict**: REWRITE
- **可追溯实证**: 它处理产品决策变更后影响评估、ADR、Issue、STATUS（`.claude/skills/decision-closeout/SKILL.md:3`, `.claude/skills/decision-closeout/SKILL.md:18-22`）。但 M-005 §I 明确结构性决定必须用户批准（`docs/meta/M-005-quality-criteria.md:374-401`），#005 是未经批准归档路径的实证。该 skill 当前把传播和关闭 Issue 写成执行步骤（`.claude/skills/decision-closeout/SKILL.md:30-70`），未把 P2 批准权作为前置门。
- **可验伪信号**: 若 skill 后半已包含完整用户批准门与 append-only user-decision-log 写入要求，则可降为 KEEP；当前头部证据不足。
- **重写要点**: 开头先判定是否结构性决定；涉及归档、跨目录移动、批量 frontmatter、删除文件、ADR status 等必须引用用户裁决编号；Issue close/STATUS 更新只能在裁决落档后执行。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `deep-linking`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared deep-linking adapter（`.claude/skills/deep-linking/SKILL.md:3`, `.claude/skills/deep-linking/SKILL.md:9-13`）。#016 指出双份存在疑似同步漂移。
- **可验伪信号**: 若 `.claude` adapter 包含 `.agents` 无法表达的 Claude-only permission gate，则需保留 wrapper。
- **合并目标**: `.agents/skills/deep-linking`。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `dependency-propagation`

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: 它在文档/API/ADR 改动后按 `DOC_DEPENDENCY_MAP.md` 同步下游（`.claude/skills/dependency-propagation/SKILL.md:3`, `.claude/skills/dependency-propagation/SKILL.md:39-53`），本质是变更传播规则和 grep 方法（`.claude/skills/dependency-propagation/SKILL.md:55-70`）。M-000 §6 要求执行步骤/规则下沉；#016 暂停路径 C 期间级联引用更新（`docs/meta/user-decision-log.md:239-242`），说明自动触发应受上层流程控制。
- **可验伪信号**: 若有动态依赖图工具只能经 skill 执行，且 standards 无法保持可操作性，则可改 REWRITE。
- **升级目标**: `docs/standards/dependency-propagation.md` 或并入 `docs/DOC_DEPENDENCY_MAP.md` 的执行章节。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `dod-checklist`

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: 它逐项检查 Definition of Done（`.claude/skills/dod-checklist/SKILL.md:3`, `.claude/skills/dod-checklist/SKILL.md:16-28`），列出 `swiftlint`、`xcodebuild`、CI、review 留痕等静态门禁（`.claude/skills/dod-checklist/SKILL.md:30-65`）。DoD 属于标准与执行门，不应由 skill 成为权威定义；AGENTS 已列执行门命令。
- **可验伪信号**: 若 DoD 需要按 PR diff 动态计算且已有脚本无法承载，保留 skill 作为执行器有意义。
- **升级目标**: `docs/standards/execution-gates.md`，skill 可退化为命令索引或删除。
- **元规则对齐分**: 3
- **使用频率估计**: 高

### `error-monitoring`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它生成 crash/error monitoring provider infrastructure（`.claude/skills/error-monitoring/SKILL.md:3`），属于协议和 provider 模板。M-000 §6 将代码模板和检查脚本下沉。
- **可验伪信号**: 若生产事故要求特定监控策略裁决、隐私边界或 vendor 选择 ADR，则该内容应升级为 standards/ADR，而不是保留 generator skill。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `harness-recall`

- **Verdict**: REWRITE
- **可追溯实证**: 它扫描 handoff risks 与 anti-pattern 警报，同类问题 ≥3 次后 propose 新 F-0XX（`.claude/skills/harness-recall/SKILL.md:3`, `.claude/skills/harness-recall/SKILL.md:17-21`, `.claude/skills/harness-recall/SKILL.md:48-67`）。M-005 §G 已定义 check 升级/降级的真实事故、≥3 次审计运行、30 天、误报率 <20% 等条件（`docs/meta/M-005-quality-criteria.md:303-342`）；当前“三击即提 F-rule”过窄且旧 F 体系化。
- **可验伪信号**: 若 #017 裁决保留 F-rule 作为 active rule namespace 且 M-003 要求 recall skill 继续主动提规则，则可改 KEEP。
- **重写要点**: 改为提出 `proposed-check` / `proposed-standard` / `proposed-skill-change` 三类；不得自动写 F-0XX；必须包含误报率、消费端、退役条件和用户裁决位。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `integration-test-scaffold`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared integration test scaffold adapter（`.claude/skills/integration-test-scaffold/SKILL.md:3`, `.claude/skills/integration-test-scaffold/SKILL.md:9-13`）。重复入口违反 M-000 §6 的单一权威定义倾向。
- **可验伪信号**: 若 `.claude` adapter 是唯一能被 Claude Code 自动发现的形式且 symlink 不被支持，则需要保留生成型 adapter。
- **合并目标**: `.agents/skills/integration-test-scaffold`。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `keyword-optimizer`

- **Verdict**: DELETE
- **可追溯实证**: 它优化 App Store title/subtitle/keywords（`.claude/skills/keyword-optimizer/SKILL.md:3`），属于低频 ASO 策略，且 App Store 搜索排名、竞品、keyword 效果是高度外部实时事实，必须按 M-005 §D 走实时验证。它不对应 M-000 P1-P8 的协作治理，也不是 SnapDrill 工程必要能力。
- **可验伪信号**: 若产品发布流程已有真实 ASO 事故或用户明确要求建立 App Store growth 操作手册，则 DELETE 应改为 PROMOTE_TO_STANDARDS。
- **元规则对齐分**: 1
- **使用频率估计**: 低

### `knowledge-health`

- **Verdict**: REWRITE
- **可追溯实证**: 它跑 docaudit 并扫描 CI 不可见私有空间，只产 plan（`.claude/skills/knowledge-health/SKILL.md:3`, `.claude/skills/knowledge-health/SKILL.md:17-21`）。但它仍用固定文件数阈值（`.claude/skills/knowledge-health/SKILL.md:39-51`），与 M-000 §6 “不使用固定文件数量作为单一门槛”冲突（`docs/meta/M-000-meta-vision.md:78`）。M-000 §8 也限定 docaudit 只证明机械结构信号。
- **可验伪信号**: 若 `docs/KNOWLEDGE_MAP.md` 仍 active 地定义 45/50 为阻塞门且被用户 ratify，则固定阈值冲突可撤回。
- **重写要点**: 删除硬阈值颜色判断；改为 incoming refs、访问/修改频率、重复权威定义、维护成本、工具生成可能性等 M-000 §6 信号；输出应是候选列表，不是“必须退役”。
- **元规则对齐分**: 2
- **使用频率估计**: 中

### `liquid-glass`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared Liquid Glass adapter（`.claude/skills/liquid-glass/SKILL.md:3`, `.claude/skills/liquid-glass/SKILL.md:9-13`）。双份存在由 #016 点名为同步漂移风险。
- **可验伪信号**: 若 `.agents` shared skill 缺少项目 iOS 26 deployment target 约束，则合并前需补 shared source，而非保留双份。
- **合并目标**: `.agents/skills/liquid-glass`。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `localization-setup`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它生成 i18n/String Catalog/RTL 基础设施（`.claude/skills/localization-setup/SKILL.md:3`），属于可复用 setup 模板。M-005 §A.3 下沉证明要求把模板和操作步骤移出 skill。
- **可验伪信号**: 若 SnapDrill localization 有已 ratify 的多语言发布承诺、法律地区差异或术语治理事故，需升级为 standards。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `migration-patterns`

- **Verdict**: PROMOTE_TO_STANDARDS
- **可追溯实证**: 它包含 CoreData→SwiftData、UIKit→SwiftUI、ObservableObject→@Observable 等 migration guides（`.claude/skills/migration-patterns/SKILL.md:3`）。这是长期工程标准和迁移参考，不是单次执行器；M-000 §6 指出规则/例子应下沉。
- **可验伪信号**: 若 migration skill 包含动态代码扫描和逐项目迁移决策树，且 standards 无法承载，则可改 REWRITE。
- **升级目标**: `docs/standards/migration-patterns.md`。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `navigation-patterns`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared navigation architecture adapter（`.claude/skills/navigation-patterns/SKILL.md:3`, `.claude/skills/navigation-patterns/SKILL.md:9-13`）。它与 SwiftUI domain skills 有明显交集，但 shared source 已是当前迁移目标。
- **可验伪信号**: 若 navigation 在 SnapDrill 中有独立 architecture事故，不能并入 SwiftUI skill，则保留为 `.agents` 单独 shared skill。
- **合并目标**: `.agents/skills/navigation-patterns`。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `onboarding-generator`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它生成多步 onboarding flows（`.claude/skills/onboarding-generator/SKILL.md:3`），属于 feature scaffold。是否需要 onboarding 是产品决策，不应由常驻 skill trigger 暗示；实现细节可模板化。
- **可验伪信号**: 若产品文档明确 onboarding 为核心旅程且已有复杂状态/隐私约束，则应改为 PROMOTE_TO_STANDARDS 或 ADR。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `phase-closeout`

- **Verdict**: REWRITE
- **可追溯实证**: 它在长 phase 收官时写 `docs/memory/handoff.md`（`.claude/skills/phase-closeout/SKILL.md:3`, `.claude/skills/phase-closeout/SKILL.md:17-23`），模板使用 `layer: snapshot`（`.claude/skills/phase-closeout/SKILL.md:25-33`）。M-000 v2 layer 简化把 `snapshot` 映射为 archive 类迁移对象（`docs/meta/M-000-meta-vision.md:84-92`），#006 已把 Boot 改为 M-000 + decision log，handoff/STATUS 不再是 Boot 核心。
- **可验伪信号**: 若 M-001 后续明确保留 phase-closeout 写 handoff 的 active 机制，并定义 `snapshot` 兼容语义，则可改 KEEP。
- **重写要点**: 改成 current protocol 下的 checkpoint 生成器；frontmatter layer 使用当前兼容策略；不得自动触发 knowledge-health / harness-recall；引用 #006 Boot/Action Gate 而非旧 Phase Compaction。
- **元规则对齐分**: 2
- **使用频率估计**: 中

### `post-merge`

- **Verdict**: REWRITE
- **可追溯实证**: 它要求 PR 合并后检查 CI、更新 STATUS、推 develop（`.claude/skills/post-merge/SKILL.md:3`, `.claude/skills/post-merge/SKILL.md:28-69`），并引用 F-007（`.claude/skills/post-merge/SKILL.md:30`）。M-005 §I 把结构性变更和 PR 作废条件交给用户裁决链；M-000 P2 规定用户最高裁决权。当前 skill 写死 `git checkout develop && git pull` 和 push develop，越过本次“不可 merge develop”边界时风险高。
- **可验伪信号**: 若 post-merge 只在用户明确授权 merge 后触发，且 skill 新版已有不推 develop 的保护，则 rewrite 可收窄。
- **重写要点**: 前置“用户已授权 merge/push”检查；删除旧 F 编号；STATUS 更新改为 protocol-defined path；CI queued/failure 处理与 execution-gates 对齐；不得在未授权 worktree 操作 develop。
- **元规则对齐分**: 2
- **使用频率估计**: 中

### `privacy-manifests`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared privacy manifest adapter（`.claude/skills/privacy-manifests/SKILL.md:3`, `.claude/skills/privacy-manifests/SKILL.md:9-13`）。隐私 manifest 是 App Store 当前事实密集区，应在 shared source 中集中刷新，避免双份漂移。
- **可验伪信号**: 若 `.claude` 与 `.agents` 的 privacy manifest 内容并不一致且 `.claude` 版本更新，合并目标应先吸收 `.claude` 差异。
- **合并目标**: `.agents/skills/privacy-manifests`。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `push-notifications`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared push notification adapter（`.claude/skills/push-notifications/SKILL.md:3`, `.claude/skills/push-notifications/SKILL.md:9-13`）。#016 已将双份存在列为生态问题。
- **可验伪信号**: 若 APNs 权限、entitlements 或 SnapDrill server constraints 只写在 `.claude` adapter 中，则合并前需迁移这些约束。
- **合并目标**: `.agents/skills/push-notifications`。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `resume-from-handoff`

- **Verdict**: REWRITE
- **可追溯实证**: 它要求新会话 Tier 1 必读 `CLAUDE.md`、`STATUS.md`、`docs/memory/handoff.md`、`docs/memory/feedback.md`、`docs/standards/collaboration.md`（`.claude/skills/resume-from-handoff/SKILL.md:22-32`）。#006 已裁决 Boot 必读改为 M-000 + user-decision-log，`STATUS.md` 与 feedback 移出 Boot（`docs/meta/user-decision-log.md:89-99`）；AGENTS 当前也只列 2 个 Boot 文件。
- **可验伪信号**: 若 M-001 后续恢复 handoff/STATUS 为接手必读，并明确覆盖 #006，则可改 KEEP。
- **重写要点**: Tier 1 改为 `docs/meta/M-000-meta-vision.md` + `docs/meta/user-decision-log.md`；STATUS、feedback、handoff 改为 Context Map/任务相关按需；启动报告不得要求用户确认才能继续，除非任务不清。
- **元规则对齐分**: 1
- **使用频率估计**: 高

### `review-response-writer`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared App Store review response adapter（`.claude/skills/review-response-writer/SKILL.md:3`, `.claude/skills/review-response-writer/SKILL.md:9-13`）。双份存在风险同 #016。
- **可验伪信号**: 若 App Store 回复 tone/brand rules 只存在于 `.claude` adapter，则合并前需迁移。
- **合并目标**: `.agents/skills/review-response-writer`。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `screenshot-planner`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared App Store screenshot planning adapter（`.claude/skills/screenshot-planner/SKILL.md:3`, `.claude/skills/screenshot-planner/SKILL.md:9-13`）。这类 marketing template 低频，更应避免双份漂移。
- **可验伪信号**: 若 `.agents` 版本缺少 SnapDrill product positioning，而 `.claude` 包含，则合并时应把 positioning 移入 product docs，不保留 adapter 分叉。
- **合并目标**: `.agents/skills/screenshot-planner`。
- **元规则对齐分**: 3
- **使用频率估计**: 低

### `settings-screen`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它生成完整 settings screen（`.claude/skills/settings-screen/SKILL.md:3`），属于 UI feature scaffold。设置项本身应来自产品/隐私/entitlement 决策，SwiftUI 布局可模板化。
- **可验伪信号**: 若 settings screen 成为 SnapDrill 的核心配置架构且有跨模块状态风险，应升级为 standards 或 ADR。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `snapshot-diff-review`

- **Verdict**: KEEP
- **可追溯实证**: 它处理 snapshot baseline 图片变更，指出 binary diff 看不出内容，必须逐张确认视觉变化是否有意（`.claude/skills/snapshot-diff-review/SKILL.md:3`, `.claude/skills/snapshot-diff-review/SKILL.md:15-24`），并给出判断分支（`.claude/skills/snapshot-diff-review/SKILL.md:55-62`）。M-005 §A.2 要求可验伪 yes/no；baseline 是否有意不是纯脚本可判，需要人/LLM看图上下文。
- **可验伪信号**: 若仓库采用可重复像素差阈值 + PR 强制人工 review policy，且 skill 从未触发，则可降为 standards checklist。
- **下沉证明**: standards 可写“baseline 需审”，脚本可列文件，但“视觉变化是否符合本次 PR 意图”需要结合 diff、设计目标和用户语义判断，不能完全下沉到模板或机械 gate。
- **元规则对齐分**: 4
- **使用频率估计**: 低

### `snapshot-testing`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它设置 SwiftUI visual regression testing 和 CI config（`.claude/skills/snapshot-testing/SKILL.md:3`），属于 test boilerplate 与 package configuration。M-000 §6 把命令、模板、检查脚本列为下沉对象。
- **可验伪信号**: 若 snapshot testing adoption 需要产品级视觉质量标准和事故复盘，则应把质量标准 PROMOTE，模板仍不应常驻 skill。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `sprint-contract`

- **Verdict**: REWRITE
- **可追溯实证**: 它是 F-018 编码前契约执行器（`.claude/skills/sprint-contract/SKILL.md:3`, `.claude/skills/sprint-contract/SKILL.md:15-25`），字段化体例与 gate 脚本绑定（`.claude/skills/sprint-contract/SKILL.md:58-70`），但 #016 明确 M-005 起草用了 sprint-contract 且 skill 未经元规则审查（`docs/meta/user-decision-log.md:238-240`）。M-005 §A/H/I 已提供 scope、主笔、越权判据，旧 F-018 表述需要迁移。
- **可验伪信号**: 若 M-001 ratify 后明确保留该 skill 为开工唯一执行器，且当前字段体例全部被 standards 消费，则可改 KEEP。
- **重写要点**: 删除 F-018/F-013/F-014 权威源表述；contract 字段对齐 M-001 单方执行窗口和 M-005 §A；增加“用户明确窄 scope 覆盖默认 contract”与“结构性决定需用户批准”。
- **元规则对齐分**: 3
- **使用频率估计**: 高

### `swift-concurrency-pro`

- **Verdict**: MERGE
- **可追溯实证**: `.claude/skills/swift-concurrency-pro` 是指向 `.agents/skills/swift-concurrency-pro` 的 symlink，shared source 本身声明 review Swift concurrency（`.claude/skills/swift-concurrency-pro/SKILL.md:3`, `.claude/skills/swift-concurrency-pro/SKILL.md:23-38`）。这已接近正确 SSOT，但仍应在 audit matrix 中归为 `.agents` SSOT。
- **可验伪信号**: 若 Claude Code 不支持 symlink skill discovery，导致 symlink 形式不可用，则需要保留 adapter 或生成副本。
- **合并目标**: `.agents/skills/swift-concurrency-pro`，`.claude` 仅保留 symlink/manifest。
- **元规则对齐分**: 4
- **使用频率估计**: 高

### `swiftdata-pro`

- **Verdict**: MERGE
- **可追溯实证**: `.claude/skills/swiftdata-pro` 是 `.agents` symlink；shared skill 声明 SwiftData write/review（`.claude/skills/swiftdata-pro/SKILL.md:3`, `.claude/skills/swiftdata-pro/SKILL.md:12-20`）。SSOT 应保持 `.agents`。
- **可验伪信号**: 若 symlink 入口在某些工具中不会加载，则需要 discovery adapter 但不应复制内容。
- **合并目标**: `.agents/skills/swiftdata-pro`。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `swiftui-debugging`

- **Verdict**: MERGE
- **可追溯实证**: 它诊断 SwiftUI re-render、identity、performance（`.claude/skills/swiftui-debugging/SKILL.md:3`, `.claude/skills/swiftui-debugging/SKILL.md:11-23`），decision tree 指向 body/lazy/identity references（`.claude/skills/swiftui-debugging/SKILL.md:24-45`）。`swiftui-pro` 已覆盖 SwiftUI performance 和 references（`.claude/skills/swiftui-pro/SKILL.md:14-24`）。
- **可验伪信号**: 若 SwiftUI performance debugging 的 reference 体量和触发频率显著高于 general `swiftui-pro`，合并会导致检索失败，则应保留为 separate `.agents` skill。
- **合并目标**: `swiftui-pro`，新增 performance-debugging reference。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `swiftui-pro`

- **Verdict**: MERGE
- **可追溯实证**: `.claude/skills/swiftui-pro` 是 `.agents` symlink；shared source 覆盖 SwiftUI API、views、data、navigation、design、accessibility、performance（`.claude/skills/swiftui-pro/SKILL.md:3`, `.claude/skills/swiftui-pro/SKILL.md:12-24`）。它是多个 SwiftUI 小 skill 的自然合并目标。
- **可验伪信号**: 若 monolithic `swiftui-pro` 导致单次加载过重，且 M-003 后续定义按主题拆分更优，则应拆为 `.agents` 多个 portable skills，而非 `.claude` 私有副本。
- **合并目标**: `.agents/skills/swiftui-pro`。
- **元规则对齐分**: 4
- **使用频率估计**: 高

### `tdd-bug-fix`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它是 red-green-refactor bug fix 流程（`.claude/skills/tdd-bug-fix/SKILL.md:3`, `.claude/skills/tdd-bug-fix/SKILL.md:20-33`），过程阶段和问题清单高度模板化（`.claude/skills/tdd-bug-fix/SKILL.md:35-45`）。M-005 §A.3 要求此类操作步骤下沉。
- **可验伪信号**: 若 bug fix TDD 是强制 governance gate，且执行失败曾导致真实回归，应升 standards 而不是 template。
- **元规则对齐分**: 2
- **使用频率估计**: 中

### `tdd-feature`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它是 red-green-refactor feature scaffold（`.claude/skills/tdd-feature/SKILL.md:3`, `.claude/skills/tdd-feature/SKILL.md:20-31`），阶段化问题清单和 API sketch 是模板（`.claude/skills/tdd-feature/SKILL.md:33-45`）。M-000 §6 不让模板常驻为元入口。
- **可验伪信号**: 若用户裁决要求所有 feature 必须 test-first 且 CI/gate 消费该流程，则应 PROMOTE_TO_STANDARDS。
- **元规则对齐分**: 2
- **使用频率估计**: 中

### `tdd-refactor-guard`

- **Verdict**: MERGE
- **可追溯实证**: 它在 AI refactor 前检查 tests，不足时生成 characterization tests（`.claude/skills/tdd-refactor-guard/SKILL.md:3`, `.claude/skills/tdd-refactor-guard/SKILL.md:7-18`）。这与 `characterization-test-generator` shared skill 的安全网目标重叠。
- **可验伪信号**: 若 refactor guard 是开工 gate，而 characterization generator 只是测试生成器，则应拆为 standards gate + generator，而不是简单合并。
- **合并目标**: `characterization-test-generator`，保留“refactor 前 coverage 判定”作为 trigger 子场景。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `test-contract`

- **Verdict**: MERGE
- **可追溯实证**: 文件是 shared test contract adapter（`.claude/skills/test-contract/SKILL.md:3`, `.claude/skills/test-contract/SKILL.md:9-13`）。重复 wrapper 属于 #016 的双份存在问题。
- **可验伪信号**: 若 `.agents` source 缺失 SnapDrill protocol/interface conventions，则迁移补齐后再合并。
- **合并目标**: `.agents/skills/test-contract`。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `tipkit-generator`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它生成 TipKit infrastructure（`.claude/skills/tipkit-generator/SKILL.md:3`, `.claude/skills/tipkit-generator/SKILL.md:7-19`），包含 deployment/context/conflict checks 和配置问题（`.claude/skills/tipkit-generator/SKILL.md:21-45`）。这是 feature scaffold，不是元规则执行器。
- **可验伪信号**: 若产品愿景确认 TipKit 是关键引导机制且规则复杂，应升为 product standard 或 ADR。
- **元规则对齐分**: 2
- **使用频率估计**: 低

### `ui-review`

- **Verdict**: MERGE
- **可追溯实证**: 它 review SwiftUI HIG、font、Dynamic Type、accessibility（`.claude/skills/ui-review/SKILL.md:3`, `.claude/skills/ui-review/SKILL.md:21-39`）。`swiftui-pro` 已含 design/accessibility/performance references（`.claude/skills/swiftui-pro/SKILL.md:18-20`），`accessibility-generator` 也覆盖可访问性实现。
- **可验伪信号**: 若 UI review 必须独立调用 WebFetch 最新 HIG 且 `swiftui-pro` 不允许联网验证，则应 REWRITE 为 Apple HIG external-fact skill。
- **合并目标**: `swiftui-pro`，将 HIG/font/accessibility quick refs 迁入 design/accessibility references。
- **元规则对齐分**: 3
- **使用频率估计**: 中

### `verify-audit-report`

- **Verdict**: REWRITE
- **可追溯实证**: 它逐条 grep+Read 验证审计 finding（`.claude/skills/verify-audit-report/SKILL.md:3`, `.claude/skills/verify-audit-report/SKILL.md:18-27`），核心纪律“不是浅层 grep”“全量不抽查”与 M-005 §A 可追溯/可验伪一致（`.claude/skills/verify-audit-report/SKILL.md:30-41`）。但它仍引用 F-006/F-012，并把收到任何审计报告后自动触发写进 trigger（`.claude/skills/verify-audit-report/SKILL.md:24-26`），与 #016 禁止治理 skill 自审冲突。
- **可验伪信号**: 若 #017 裁决把 verify-audit-report ratify 为 Stage 3/4 统一验证执行器，且明确允许其用于 skill audit final，则可改 KEEP。
- **重写要点**: 删除旧 F 编号；映射到 M-005 §A/F；加“不得验证本次 skill audit 的同级产物，除非任务定义显式允许”；输出必须保留 source path:line 与覆盖 ledger。
- **元规则对齐分**: 4
- **使用频率估计**: 中

### `xcode-review`

- **Verdict**: DOWNGRADE_TO_TEMPLATE
- **可追溯实证**: 它是 Xcode Intelligence Review prompt writing guide（`.claude/skills/xcode-review/SKILL.md:3`, `.claude/skills/xcode-review/SKILL.md:15-21`），正文是 prompt 结构和固定收尾（`.claude/skills/xcode-review/SKILL.md:25-44`）。M-005 §A.3 说模板应下沉；这不是需要常驻 trigger 的 skill。
- **可验伪信号**: 若 Xcode Review 结果被 execution gate 强制消费，且 prompt 需要按 PR diff 动态生成不能模板化，则应 REWRITE。
- **元规则对齐分**: 2
- **使用频率估计**: 中

## 3. 元层级观察

1. **`.claude/skills` 同时承载治理入口与工程模板，导致 P7 净化提示词被 trigger 机制绕开。** `cross-audit`、`sprint-contract`、`verify-audit-report` 这类治理 skill 会在 keyword 命中后主动塑形任务，而 #016 本身要求审计过程不得使用这些 skill；这证明 skill trigger 是元规则执行层，必须由 M-003 约束，而不能只作为便利工具。
2. **旧 F-rule namespace 已成为最大漂移源。** 多个治理 skill 写着 “F-00X 权威执行器”，但当前 active 元规则已经是 M-000 v2.0 + M-005 v2；保留 F 编号会制造“旧反馈索引比 PRIMARY 更像规则”的错觉。
3. **16 个 `.agents` shared skill 应以 `.agents` 为 portable SSOT。** `.claude` adapter/symlink 可保留为发现入口，但不能再承载规则正文。否则 #016 指出的同步漂移会继续发生。
4. **工具 generator 大多不需要 skill trigger。** app icon、background processing、settings、TipKit、snapshot setup、TDD feature 等更适合 templates + standards；常驻 skill 会把“可生成”误导成“应该生成”。
5. **少数执行器值得保留，但要证明不可下沉。** `snapshot-diff-review` 是本轮唯一 KEEP，因为视觉 baseline 是否符合 PR 意图不能由静态模板或脚本完全判定；这种 KEEP 需要保留“人/LLM 判断为什么不可替代”的证明。
6. **M-005 §G 目前只覆盖 docaudit check，不覆盖 skill 升降级。** #016 预测的盲点成立：本轮需要对 skill 本身定义类似 “事故来源 / 触发频率 / 误触发率 / 消费端 / 退役条件” 的生命周期规则，建议 Stage 6 patch M-005 或在 M-003 中承接。

## 4. 统计

### Verdict 数量

| Verdict | 数量 |
|---|---:|
| KEEP | 1 |
| MERGE | 20 |
| DELETE | 1 |
| PROMOTE_TO_STANDARDS | 6 |
| DOWNGRADE_TO_TEMPLATE | 13 |
| REWRITE | 11 |
| **合计** | **52** |

### 元规则对齐分分布

| 分数 | 数量 | 说明 |
|---:|---:|---|
| 1 | 2 | 与 current Boot/元规则或目的关联明显脱节 |
| 2 | 18 | 有用但主要是模板、旧流程或过期规则 |
| 3 | 25 | 方向可用但存在重复、下沉不足或旧命名 |
| 4 | 7 | 价值清楚，需小幅合并/重写或已有 SSOT |
| 5 | 0 | 本轮未发现无需任何处置的完美对齐 skill |

### 治理 vs 工具比例

| 分类 | 数量 | 占比 |
|---|---:|---:|
| 治理 skill | 14 | 26.9% |
| 工具 skill | 38 | 73.1% |
| **合计** | **52** | **100%** |

治理 skill 主要风险是旧 F-rule 与自动 trigger 越过 M-000/M-005；工具 skill 主要风险是 generator/template 常驻化，导致可下沉内容占据 skill 生态入口。
