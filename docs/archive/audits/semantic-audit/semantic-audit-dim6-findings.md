---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---

# SnapDrill 文档体系语义层审计报告 — 维度 6：Skill Description ↔ Body 一致性

> **审计状态**：`snapshot` 验证进行中
> **执行模型**：Antigravity
> **验证日期**：2026-05-21

---

## 1. 审计概述 (Audit Overview)

本报告针对 SnapDrill 文档体系中全部 52 个 Distinct Skill 的 Frontmatter `description` 与其 `body` 实质内容的一致性进行了全量独立审计。

本次审计遵循以下核心纪律与原则：
1. **控制变量法纪律 (F-008)**：100% 完整覆盖全量 52 个 Skill 文件，不做任何挑选、分工或切片。
2. **严禁终态标记**：不作任何“已收官/已结案”等终态定义，保持 `snapshot` 迭代验证状态。
3. **中文规范**：报告与回复完全使用简体中文撰写。

---

## 2. 52 个 Distinct Skill 全量一致性审计大表

以下为 52 个 Skill 的全量审计结论。除 A072 (`app-store-rejection`) 与 A083 (`snapshot-testing`) 在结构层 audit-ledger 中已标为 `VALID_WITH_GAP` 从而在此处豁免重复审计外，其余 50 个均进行了深度对齐审计。

| 序号 | Skill 目录名 | 分类 | 主要定义位置 | 状态 | 关键校验说明 |
|---|---|---|---|---|---|
| 1 | `accessibility-generator` | Shared | `.agents/skills` | **VALID** | Adapter 格式及 Allowed-tools 严格符合规范，无实质漂移。 |
| 2 | `animation-patterns` | Claude-only | `.claude/skills` | **VALID** | Description 的动画模式完全覆盖 body API 分类与 Decision Tree。 |
| 3 | `api-research` | Governance | `.claude/skills` | **VALID** | Description 中 F-017 执行职责与 body 工作流与触发场景完全匹配。 |
| 4 | `app-description-writer` | Shared | `.agents/skills` | **VALID** | Adapter 与 Shared 源文件完全对齐，Allowed-tools 符合沙箱规范。 |
| 5 | `app-icon-generator` | Claude-only | `.claude/skills` | **VALID** | Description 生成机制与 body 中 CoreGraphics 运行步骤一致。 |
| 6 | `app-store-assets` | Claude-only | `.claude/skills` | **VALID** | 描述内容与 body 中各类艺术资产规格（尺寸、预览等）对齐。 |
| 7 | `app-store-rejection` | Claude-only | `.claude/skills` | *H.EXEMPT* | 结构层 A072 豁免，在此做记录。 |
| 8 | `attributed-string` | Shared | `.agents/skills` | **VALID** | 描述的 styled text 和 SwiftUI 整合在 body 中有清晰对应的 Checklist。 |
| 9 | `background-processing` | Claude-only | `.claude/skills` | **VALID** | Description 与 body 触发机制一致，Allowed-tools 合理。 |
| 10 | `characterization-test-generator` | Shared | `.agents/skills` | **VALID** | 描述的 refactoring 保护机制在 body 的 Process 章节有完整的动作链。 |
| 11 | `ci-cd-setup` | Claude-only | `.claude/skills` | **VALID** | 动作链 `automated builds → test → distribution` 匹配 body 步骤。 |
| 12 | `coding-best-practices` | Claude-only | `.claude/skills` | **VALID** | 描述的 adherence checking 与 body 详实 Review Checklist 吻合。 |
| 13 | `cross-audit` | Governance | `.claude/skills` | **VALID** | 描述中 F-008 强制性纪律在 body 必须遵守的纪律章节有完整硬核校验。 |
| 14 | `cross-audit-consensus` | Governance | `.claude/skills` | **VALID** | 共识汇总裁决表功能与 body 强制性输出格式对齐。 |
| 15 | `data-export` | Claude-only | `.claude/skills` | **VALID** | JSON/CSV/PDF 多格式导入导出及 GDPR 顺应性在 body 中完美落地。 |
| 16 | `decision-closeout` | Governance | `.claude/skills` | **VALID** | 描述中变更链 `评估 → 同步 → ADR → Issue → STATUS` 在 body 对应 Step 1-5。 |
| 17 | `deep-linking` | Shared | `.agents/skills` | **VALID** | URL schemes/Universal Links/App Intents 与 body 章节大纲完全一致。 |
| 18 | `dependency-propagation` | Governance | `.claude/skills` | **VALID** | 下游同步执行场景与 body 变更传播工作流对齐。 |
| 19 | `dod-checklist` | Governance | `.claude/skills` | **VALID** | 针对 PR DoD 检查职责与 body 动作完全一致。 |
| 20 | `error-monitoring` | Claude-only | `.claude/skills` | **VALID** | 协议化多 Provider 接入描述在 body 的 Generated Code Patterns 中完整呈现。 |
| 21 | `harness-recall` | Governance | `.claude/skills` | **DISCREPANCY** | `C6.2` 步骤失效/漂移。Body 指向了上游已废弃的 `## Risks` 章节。 |
| 22 | `integration-test-scaffold` | Shared | `.agents/skills` | **VALID** | 描述的 cross-module 测试脚手架在 body 文件结构中正确阐述。 |
| 23 | `keyword-optimizer` | Claude-only | `.claude/skills` | **VALID** | Discoverability 关键词分析在 body 中有详细 Character limits 对照。 |
| 24 | `knowledge-health` | Governance | `.claude/skills` | **VALID** | 体检范围与 body 执行步骤（CI-visible 与 CI-invisible）高度一致。 |
| 25 | `liquid-glass` | Shared | `.agents/skills` | **VALID** | 描述中 API 的应用框架（SwiftUI/AppKit等）与 body 多个 H2 小节对齐。 |
| 26 | `localization-setup` | Claude-only | `.claude/skills` | **VALID** | xcstrings 方案生成在 body 中包含明确的 Integration Steps。 |
| 27 | `migration-patterns` | Claude-only | `.claude/skills` | **VALID** | 框架迁移路线描述完全覆盖 body 中的 6 类具体框架指导。 |
| 28 | `navigation-patterns` | Shared | `.agents/skills` | **VALID** | SwiftUI 现代导航结构与 body 导航范式对齐。 |
| 29 | `onboarding-generator` | Claude-only | `.claude/skills` | **VALID** | 多步骤引导与持久化配置在 body 的 Generation Process 中清晰展开。 |
| 30 | `phase-closeout` | Governance | `.claude/skills` | **VALID** | Handoff 长任务总结在 body 具有强约束的标准输出模板。 |
| 31 | `post-merge` | Governance | `.claude/skills` | **VALID** | PR 合并收尾清单与 body 合并后 30 秒执行流对齐。 |
| 32 | `privacy-manifests` | Shared | `.agents/skills` | **VALID** | 合规要求的 required reason 在 body 有极其详实的数据和触发参考。 |
| 33 | `push-notifications` | Shared | `.agents/skills` | **VALID** | APNs 注册及 rich notifications 在 body 包含明确集成大纲与代码。 |
| 34 | `resume-from-handoff` | Governance | `.claude/skills` | **VALID** | 最小上下文引导职责与 body 加载顺序高度契合。 |
| 35 | `review-response-writer` | Shared | `.agents/skills` | **VALID** | 撰写同理心回复职责与 body 多套 Response Templates 对齐。 |
| 36 | `screenshot-planner` | Shared | `.agents/skills` | **VALID** | 截图分镜与 Caption 的写作策略在 body 有完整 Storyboard Template。 |
| 37 | `settings-screen` | Claude-only | `.claude/skills` | **VALID** | 通用 Settings Screen 生成与 body 平台差异化代码模式完全一致。 |
| 38 | `snapshot-diff-review` | Governance | `.claude/skills` | **VALID** | Baseline 人工比对职责在 body 中有精确的操作步骤和注意事项。 |
| 39 | `snapshot-testing` | Claude-only | `.claude/skills` | *H.EXEMPT* | 结构层 A083 豁免，在此做记录。 |
| 40 | `sprint-contract` | Governance | `.claude/skills` | **VALID** | 编码前契约流程在 body 对应强约束的 Sprint Contract 格式。 |
| 41 | `swift-concurrency-pro` | Shared | `.agents/skills` | **DISCREPANCY** | `C6.3` H1 标题缺失。导致与 name 及文件夹名的一致性断裂。 |
| 42 | `swiftdata-pro` | Shared | `.agents/skills` | **DISCREPANCY** | `C6.4` H1 标题缺失。导致与 name 及文件夹名的一致性断裂。 |
| 43 | `swiftui-debugging` | Claude-only | `.claude/skills` | **VALID** | SwiftUI 调试流程与 body 中 re-renders 和 view identity 等步骤完全对应。 |
| 44 | `swiftui-pro` | Shared | `.agents/skills` | **DISCREPANCY** | `C6.5` H1 标题缺失。导致与 name 及文件夹名的一致性断裂。 |
| 45 | `tdd-bug-fix` | Claude-only | `.claude/skills` | **VALID** | 描述的 RGR 流程在 body 中有高度特化的 Bug Fix 格式与 TDD 动作。 |
| 46 | `tdd-feature` | Claude-only | `.claude/skills` | **VALID** | RGR 脚手架在 body 包含详细的 TDD Rhythm 及 3 阶段工作流。 |
| 47 | `tdd-refactor-guard` | Claude-only | `.claude/skills` | **VALID** | 描述的重构安全门禁在 body 对应 PROCEED/NEEDS TESTS/STOP 的明确分支。 |
| 48 | `test-contract` | Shared | `.agents/skills` | **VALID** | 描述中行为契约机制在 body 的 Process 章节有完整的实践策略。 |
| 49 | `tipkit-generator` | Claude-only | `.claude/skills` | **VALID** | Inline/Popover 提示生成在 body 中包含完整的配置问题和 GOTCHAS。 |
| 50 | `ui-review` | Claude-only | `.claude/skills` | **VALID** | HIG 规范审查机制与 body 的 Review Process 匹配。 |
| 51 | `verify-audit-report` | Governance | `.claude/skills` | **VALID** | 审计真伪复查动作与 body 接收、逐条核实、统计的动作链完全对齐。 |
| 52 | `xcode-review` | Governance | `.claude/skills` | **DISCREPANCY** | `C6.1` 范围窄于 body。描述中遗漏了 body 中定义的“外部 Reviewer / Antigravity 验收”双轨模式。 |

---

## 3. 维度 6 详细 Findings 清单

### Finding C6.1: `xcode-review` 适用范围漂移
- **Skill 锚点**：`.claude/skills/xcode-review/SKILL.md`
- **Frontmatter 引用**：`description: Xcode Intelligence Review 提示词撰写指南。当用户说"写 Xcode 提示词/Xcode Review/提交 Xcode 审查"或 PR 涉及 UI 改动需要 Xcode 审查时触发。`
- **不一致点**：Description 只提到了 `Xcode Intelligence Review` 提示词，而 Body 却明确规定该规范“适用于：**外部 Reviewer**（如 Antigravity 等全量代码上下文工具，可选）和 **Xcode Intelligence Review**（项目内上下文）”，且 body 中有专门针对 Antigravity 验收的后续 Review 示例。这导致 description 声明的适用范围窄于 body。
- **严重度**：LOW
- **类型**：范围窄于 body
- **推荐处理**：修改 description，将适用范围拓展为“手动 Reviewer 与 Xcode Intelligence 双轨提示词指南”。

### Finding C6.2: `harness-recall` 引用已废弃的 handoff 章节 (与 S-D5-004 同源)
- **Skill 锚点**：`.claude/skills/harness-recall/SKILL.md`
- **Frontmatter 引用**：`description: 自进化闭环执行器。扫描 handoff.md Risks 段 + anti-pattern-scan 警报，检查重复问题模式。同类问题 ≥3 次 → propose 新 F-0XX 规则。...`
- **不一致点**：Body 在 `Step 1: 收集信号` 中声明通过运行 `grep -A 50 '^## Risks' docs/memory/handoff.md` 来回溯风险。但由于上游 handoff 规范（如 ADR-005 或最新 standards）在物理文件 `handoff.md` 中已经废弃并移除了 `## Risks` 这一 H2 标题（代之以其他结构），该执行步骤无法匹配当前的物理文档模型，导致“步骤失效”。
- **严重度**：MEDIUM
- **类型**：步骤失效/漂移
- **推荐处理**：同步两者，重构 `harness-recall` 的步骤，使其对齐最新 `handoff.md` 的演进结构（如 Risks/Opportunities 段）。

### Finding C6.3: `swift-concurrency-pro` 缺失 H1 标题
- **Skill 锚点**：`.agents/skills/swift-concurrency-pro/SKILL.md` (Shared Source)
- **Frontmatter 引用**：`name: swift-concurrency-pro`
- **不一致点**：作为 distinct skill 物理源文件，该 Markdown 整个 body 物理上缺失 `# Swift Concurrency Pro` 类 H1 标题，直接在 frontmatter 结束后便跳入正文段落。这违背了 H1 标题规范，阻断了 `name` 与 H1 的映射关系。
- **严重度**：MEDIUM
- **类型**：name 漂移
- **推荐处理**：修 body，在 frontmatter 之后增加 `# Swift Concurrency Pro`。

### Finding C6.4: `swiftdata-pro` 缺失 H1 标题
- **Skill 锚点**：`.agents/skills/swiftdata-pro/SKILL.md` (Shared Source)
- **Frontmatter 引用**：`name: swiftdata-pro`
- **不一致点**：该物理文件缺失 H1 标题，正文直接由段落起始。这违背了 H1 标题规范，阻断了 `name` 与 H1 的映射关系。
- **严重度**：MEDIUM
- **类型**：name 漂移
- **推荐处理**：修 body，在 frontmatter 之后增加 `# SwiftData Pro`。

### Finding C6.5: `swiftui-pro` 缺失 H1 标题
- **Skill 锚点**：`.agents/skills/swiftui-pro/SKILL.md` (Shared Source)
- **Frontmatter 引用**：`name: swiftui-pro`
- **不一致点**：该物理文件缺失 H1 标题，正文直接由段落起始。这违背了 H1 标题规范，阻断了 `name` 与 H1 的映射关系。
- **严重度**：MEDIUM
- **类型**：name 漂移
- **推荐处理**：修 body，在 frontmatter 之后增加 `# SwiftUI Pro`。

---

## 4. Shared Adapter 规范性审计

对 13 个 shared pointer adapter 的物理内容（`.claude/skills/{name}/SKILL.md`）进行了核对，审计结论如下：

1. **结构完全规范**：13 个 adapter 在物理上均极其规范，文件行数严格为 13 行。
2. **格式完全对齐**：统一包含 `name`、`description`（均带有 `Claude Code adapter for ...` 前缀并保留了 trigger 部分的 `Use when ...`）、`allowed-tools` 声明，以及明确指向对应的 `.agents/skills` 文件的 `Shared skill source:` 指针。
3. **无溢出与杂质**：物理 adapter 文件内没有塞入任何实质性步骤、指令或与源文件不同的逻辑，没有发生“adapter 私货漂移”。
4. **权限映射差异**：所有 13 个物理 adapter 在 Claude 端的 `allowed-tools` 根据 runtime 权限进行了安全限制（如限制在 `Read, Glob, Grep` 或 `Read, Write, Edit, Glob, Grep, AskUserQuestion`），而在 `.agents/skills` 中的源文件出于 portable 设计将其设为 `None`。此设计符合 iOS 架构安全边界，不属于非预期的漂移。

---
**Antigravity 独立审计声明**：本报告仅供后续三方审计共识机制裁决参考，当前维度 6 处于 `snapshot` 验证中，不代表终态结案。
