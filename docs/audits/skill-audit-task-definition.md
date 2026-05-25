---
last_verified: 2026-05-25
layer: contract
scope: drafting-task
freshness:
  max_age_days: 30
  decay_trigger: [skill_audit_ratified]
---

# Skill 生态第一性原理审计任务定义书（路径 C Stage 2）

> 净化版任务定义书。4 家（Claude / Codex / DeepSeek / Gemini）独立承接，物理隔离执行。**禁止参考其他家产出**，禁止使用任何治理 skill（cross-audit / sprint-contract / verify-audit-report 等）辅助本次审计——审计 skill 不能用 skill 审。

## 启动裁决

[user-decision-log #016](../meta/user-decision-log.md#016-路径-c-启动--skill-生态第一性原理审计彻底解决自举循环)：路径 C 激进路径，第一性原理审计 skill 生态，彻底解决自举循环。

## 一句话目标

对 52 个项目 skill（`.claude/skills/`）逐个产出 Verdict（KEEP / MERGE / DELETE / PROMOTE_TO_STANDARDS / DOWNGRADE_TO_TEMPLATE / REWRITE），每个 Verdict 必须含可追溯实证 + 可验伪信号（按 M-005 §A 判据）。

## 自举循环背景

Skill 在元规则体系中三重角色：
1. **元规则的下沉去向**（M-000 v2.0 §6 显式列出）
2. **元规则的执行器**（cross-audit skill 实施 M-005 §B / sprint-contract 实施 F-018）
3. **元规则起草过程本身的工具**（M-005 起草用了 sprint-contract + cross-audit，但 skill 未受当前元规则审查）

本次审计必须打破这个循环：**审计过程不允许调用任何治理 skill**。审计依据是 M-000 v2.0 PRIMARY 内核 + M-005 v2 §A 判据 + 第一性原理论证，不依赖"skill 之前怎么做"的惯性。

## 必读输入

1. **M-000 v2.0 原文**：`docs/meta/M-000-meta-vision.md`（特别 §2 P1-P8 + §6 下沉原则 + §11 派生表）
2. **M-005 v2 原文**：`docs/meta/M-005-quality-criteria.md`（特别 §A 4 项判据 + §G docaudit check 设计原则 + §J 字数原则）
3. **user-decision-log 全集**：`docs/meta/user-decision-log.md` #001~#016
4. **52 个 skill 的 SKILL.md 摘要**：本任务书 §Skill 摘要 inline，已含每个 skill 的 frontmatter + 前 35 行正文

## Verdict 体系

每个 skill 必须给一个 Verdict，外加可选 secondary tag：

| Verdict | 含义 | 触发信号 |
|---|---|---|
| **KEEP** | 治理价值清晰、与 M-000/M-005 对齐、不可下沉 | 实施某条元规则、有真实事故来源、不能机械化 |
| **MERGE** | 与另一 skill 功能重叠，应合并（指明合并目标） | 多个 skill 描述同一动作、Trigger 重叠 |
| **DELETE** | 装饰性 / 过时 / 形式合规但实质空洞 / 未触发过 | 描述抽象、无具体动作、与现 SDK/API 不符 |
| **PROMOTE_TO_STANDARDS** | 内容应升 `docs/standards/`，不应是 skill | 内容是规则/约束/规范，不是动作模板 |
| **DOWNGRADE_TO_TEMPLATE** | 内容是纯模板/代码片段，应剥离 trigger 改静态 | 纯代码生成、无判断逻辑、不需 LLM 介入 |
| **REWRITE** | 方向正确但措辞与 M-000/M-005 不一致，需重写 | 引用 v1.2 / 宪法 / 硬字数上限 / 5 phases 等失效表述 |

## Verdict 必备字段

每个 skill 的 Verdict 必须含：

```markdown
### `<skill-name>`

- **Verdict**: KEEP | MERGE | DELETE | PROMOTE_TO_STANDARDS | DOWNGRADE_TO_TEMPLATE | REWRITE
- **可追溯实证**: 该 Verdict 基于什么证据？引用 user-decision-log #编号 / M-000 P 编号 / M-005 §章节 / 具体 skill 文本 line
- **可验伪信号**: 什么样的反例会推翻该 Verdict？（如 KEEP 的反例 = 找到该 skill 没被任何元规则消费的证据；DELETE 的反例 = 找到该 skill 实际触发过真实问题修复）
- **下沉证明**（仅 KEEP）：为什么不能下沉到 standards / 工具 / 静态模板
- **合并目标**（仅 MERGE）：合并到哪个 skill，merge 后的新 skill 名
- **升级目标**（仅 PROMOTE_TO_STANDARDS）：移到 docs/standards/ 的哪个文件
- **重写要点**（仅 REWRITE）：需要修改的具体段落 + 替换为什么
- **元规则对齐分**：1-5 分。1=完全脱节，5=完全对齐 M-000/M-005
- **使用频率估计**：高 / 中 / 低 / 未知（基于 trigger 描述判断）
```

## 必须涵盖的关键判断

1. **治理 skill vs 工具 skill 分类**：哪些是元规则的执行器（治理），哪些是 iOS 工程模板（工具）？两类应不应该混在同一目录？
2. **重复识别**：`.claude/skills/` 和 `.agents/skills/` 双份存在的 16 个 skill 应该如何处理？SSOT 哪个？
3. **元规则隐性依赖**：M-005 起草用了哪些 skill？这些 skill 文本与 M-005 是否一致？识别隐性绑架点。
4. **trigger 净化**：哪些 skill 的 trigger（描述里的 "Use when..."）违反 M-000 P7 净化提示词？
5. **过期 skill**：哪些 skill 引用 v1.2 / 宪法 / 硬字数上限 / 5 phases / iOS 25 等失效表述？

## 输出格式

每家落 `docs/audits/skill-audit-<vendor>.md`：

```yaml
---
last_verified: 2026-05-25
layer: snapshot
scope: skill-audit
freshness:
  max_age_days: 30
  decay_trigger: [skill_audit_ratified]
override_rationale: "<密度证明>"
---
```

正文结构：
1. **总结表**：52 行 × Verdict 列，一眼看完
2. **Verdict 详情**：52 个 skill 各自展开（按 Verdict 必备字段）
3. **元层级观察**：审计过程发现的元规则盲点 / skill 生态结构性问题
4. **统计**：每类 Verdict 数量、元规则对齐分分布、治理 vs 工具 skill 比例

## 硬约束

- ❌ 禁止使用任何治理 skill 辅助本次审计（sprint-contract / cross-audit / verify-audit-report / dod-checklist / decision-closeout / phase-closeout / post-merge / dependency-propagation / resume-from-handoff / knowledge-health / harness-recall）
- ❌ 禁止参考其他 3 家审计产出
- ❌ 禁止"按惯例" / "经验上" / "通常这样" 等模糊指代
- ❌ 不预设字数上限（按密度起草，override_rationale 是密度证明）
- ✅ 引用历史裁决用具体编号（#001~#016）
- ✅ 引用 skill 文本用具体行号或片段引用
- ✅ 中文输出，技术术语保留英文

## 物理隔离纪律

| 家 | 工作目录 | 运行方式 |
|---|---|---|
| Claude 主分支 | `/Users/yiming/Developer/snapdrill-ios` | 本会话直接产出，落 `docs/audits/skill-audit-claude.md` |
| Codex | `../snapdrill-ios-codex` worktree 切新分支 `audit/skills-codex` | `codex exec --sandbox workspace-write` 后台 |
| DeepSeek reasoner | API 沙箱 | 直接 API（Scripts/...）落 `docs/audits/skill-audit-deepseek.md` |
| Gemini 3.5 Flash GA | API 沙箱 | 直接 API（Scripts/gemini_utils.py）落 `docs/audits/skill-audit-gemini.md` |

纪律：
- Codex worktree 新分支独立 commit + push（不合并 develop）
- DeepSeek / Gemini 沙箱产物由 Claude 主分支统一 commit

## 验收路径

4 家产物聚齐后进入 Stage 3：
1. Claude 中立主笔产 `docs/audits/skill-audit-consensus.md` Verdict 矩阵 + 共识 / 分歧
2. 帅哥裁决分歧 skill（落 user-decision-log）
3. DeepSeek 主笔产 `docs/audits/skill-audit-final.md`
4. 3 家 sign-off（DeepSeek 不下场）
5. 帅哥 ratify（预编号 #017）
6. Stage 5 批量执行（DELETE → archive / MERGE / PROMOTE / DOWNGRADE / REWRITE / KEEP）

---

## §Skill 摘要（52 个 SKILL.md 头部）

下方 inline 全部 52 个 skill 的 frontmatter + 前 35 行正文。审计依据此摘要 + 必要时各家自行 read 完整 SKILL.md（Claude/Codex 有文件访问能力，DeepSeek/Gemini 仅能基于本摘要判断，未把握的 skill 给 Verdict "UNKNOWN" 并说明需深审）。

---

### `accessibility-generator` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/accessibility-generator/SKILL.md`

```
---
name: accessibility-generator
description: Claude Code adapter for the shared accessibility generator skill. Use when improving app accessibility, adding accessibility labels and hints, or auditing compliance.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Accessibility Generator Skill Adapter

Shared skill source:

`../../../.agents/skills/accessibility-generator/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `animation-patterns` 

路径: `.claude/skills/animation-patterns/SKILL.md`

```
---
name: animation-patterns
description: SwiftUI animation patterns including springs, transitions, PhaseAnimator, KeyframeAnimator, and SF Symbol effects. Use when implementing, reviewing, or fixing animation code on iOS/macOS.
allowed-tools: [Read, Glob, Grep]
---

# Animation Patterns

Correct API shapes and patterns for SwiftUI animations. Prevents the most common mistakes: mixed spring parameter generations, wrong PhaseAnimator/KeyframeAnimator closure signatures, and using matchedGeometryEffect where matchedTransitionSource is needed.

## When This Skill Activates

Use this skill when the user:
- Asks to add, fix, or review **animation** code
- Mentions **spring**, **bounce**, or **snappy** animations
- Wants **view transitions** (insertion/removal, hero, zoom)
- Asks about **PhaseAnimator** or **KeyframeAnimator**
- Wants **SF Symbol effects** (bounce, pulse, wiggle, breathe)
- Mentions **matchedGeometryEffect** or **matchedTransitionSource**
- Asks about **reduce motion** / animation accessibility
- Wants to sequence or chain animations
- Mentions **withAnimation**, **animation completions**, or **Transaction**

## Decision Tree

Choose the right reference file based on what the user needs:

```
What are you animating?
│
├─ A state change (opacity, position, color)
│  └─ → core-animations.md
│     ├─ withAnimation { } — explicit animation
│     ├─ .animation(_:value:) — implicit animation
│     └─ Spring configuration — .spring, .bouncy, .snappy, .smooth
│
├─ A multi-step / sequenced animation
│  └─ → phase-keyframe-animators.md (PhaseAnimator)
│     └─ Cycles through discrete phases automatically or on trigger
│
```

---
### `api-research` 

路径: `.claude/skills/api-research/SKILL.md`

```
---
name: api-research
description: F-017 强制执行器。新增/修改 UI 组件或引入新 SDK API 前，必须先查 Apple 最新文档确认没有更合适的新方案。当用户说"加个按钮/改样式/新 API/用这个组件"或涉及 SwiftUI/UIKit/Vision/AVFoundation 等框架时触发。
allowed-tools:
  - Bash
  - Read
  - WebSearch
  - WebFetch
  - Grep
context: fork
disable-model-invocation: false
user-invocable: true
---

# /api-research — Apple 最新 API 研究（F-017 执行器）

## 一句话

iOS 26 每年新增大量 API。Claude 的训练数据不覆盖最新版本。编码前必须先查 Apple 最新文档。

## 触发场景

- 新增 SwiftUI View 组件
- 修改视觉样式（材质、动画、布局）
- 引入新框架 API（Vision、AVFoundation、Charts 等）
- 不确定某个 API 是否为最新版本
- 用户说："用 Apple 原生方案 / 查最新 API / 有没有新 API 替代"

## 工作流

### Step 1：确认目标 iOS 版本

```bash
grep "IPHONEOS_DEPLOYMENT_TARGET" Configs/Shared.xcconfig
```

以项目部署目标为准（当前 iOS 26.0+），查对应版本的 API。

### Step 2：查项目内部知识库

先搜项目内已有知识，避免舍近求远：

```bash
# 查已知的 Apple API 陷阱
grep -i "关键词" docs/tech/api-pitfalls.md

# 查 Apple 平台边界
grep -i "关键词" docs/tech/apple-limits.md
```

---
### `app-description-writer` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/app-description-writer/SKILL.md`

```
---
name: app-description-writer
description: Claude Code adapter for the shared App Store description writer skill. Use when writing initial descriptions, improving existing copy, or drafting promotional text and What's New for a major update.
allowed-tools: [Read, Glob, Grep]
---

# App Description Writer Adapter

Shared skill source:

`../../../.agents/skills/app-description-writer/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `app-icon-generator` 

路径: `.claude/skills/app-icon-generator/SKILL.md`

```
---
name: app-icon-generator
description: Generates app icons programmatically using CoreGraphics following Apple HIG. Use when user wants to create, generate, or design an app icon for macOS or iOS.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# App Icon Generator

Generate production-quality app icons programmatically using a CoreGraphics Swift script. Produces all required sizes and installs into the Xcode asset catalog.

## When This Skill Activates

Use this skill when the user:
- Asks to "generate an app icon" or "create an icon"
- Wants a "placeholder icon" or "app icon design"
- Mentions "icon for my app" or "need an app icon"
- Asks to "update the app icon"

## Pre-Generation Checks

### 1. Project Context Detection

```
Glob: **/Assets.xcassets/AppIcon.appiconset/Contents.json
```

- Identify platform: macOS, iOS, or universal
- Check for existing icon files (warn before overwriting)
- Read `Contents.json` to understand required sizes

### 2. App Context Detection

Gather app information to customize the icon:

```
Read: .planning/APP.md          (if exists — app definition)
Read: .planning/CODEBASE.md     (if exists — app description)
Grep: "CFBundleName" or app name in project files
```

```

---
### `app-store-assets` 

路径: `.claude/skills/app-store-assets/SKILL.md`

```
---
name: app-store-assets
description: Comprehensive App Store asset specifications and guidelines for all promotional artwork — app icons, screenshots, app previews, event cards, subscription images, and featuring artwork. Use when preparing assets for App Store Connect upload.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# App Store Assets Generator

Generate complete asset specifications, design guidelines, and checklists for all App Store Connect promotional artwork and media.

## When This Skill Activates

Use this skill when the user:
- Asks about "App Store asset specs" or "screenshot sizes"
- Mentions "app preview" video requirements
- Wants to know "what images do I need" for App Store
- Preparing assets for submission or update
- Asks about "featuring artwork" or "subscription images"
- Needs a comprehensive asset checklist

## Configuration Questions

Ask user via AskUserQuestion:

1. **Which platforms?** (multi-select)
   - iPhone
   - iPad
   - Mac
   - Apple Watch
   - Apple TV
   - Apple Vision Pro

2. **What assets do you need?**
   - App icon
   - Screenshots
   - App preview video
   - In-App Event card images
   - Subscription promotional images
   - Custom Product Page assets
   - All of the above
```

---
### `app-store-rejection` 

路径: `.claude/skills/app-store-rejection/SKILL.md`

```
---
name: rejection-handler
description: Handle App Store rejections, prepare submissions to avoid common rejection reasons, write Resolution Center responses, and navigate the appeal process. Use when user's app was rejected, is preparing for submission, or needs help with App Review.
allowed-tools: [Read, Glob, Grep, AskUserQuestion]
---

# App Store Rejection Handler

Guide developers through handling App Store rejections — from understanding why the rejection happened, to crafting effective responses, to escalating when appropriate.

## When This Skill Activates

Use this skill when the user:
- Says their app was rejected by App Review
- Asks for help understanding a rejection notice
- Wants to prepare a submission to minimize rejection risk
- Needs help writing a response in Resolution Center
- Wants to appeal a rejection decision
- Asks about common App Store rejection reasons
- Mentions "App Review", "guideline violation", or "rejection"
- Wants a pre-submission audit for guideline compliance

## Reference Files

Before handling a rejection, load:

| File | Purpose |
|------|---------|
| **common-rejections.md** | Top 20 rejection reasons with fixes and response templates |

## Pre-Submission Audit Checklist

Run through this before submitting to avoid the most common rejections. Each item maps to a specific App Store Review Guideline.

### App Completeness (Guideline 2.1)

- [ ] App launches without crashing on all supported devices
- [ ] All features described in metadata are functional
- [ ] No placeholder content (lorem ipsum, test data, TODO screens)
- [ ] No broken links or dead-end navigation
```

---
### `attributed-string` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/attributed-string/SKILL.md`

```
---
name: attributed-string
description: Claude Code adapter for the shared AttributedString skill. Use when working with styled text, text editing, or AttributedString APIs.
allowed-tools: [Read, Glob, Grep]
---

# AttributedString Skill Adapter

Shared skill source:

`../../../.agents/skills/attributed-string/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `background-processing` 

路径: `.claude/skills/background-processing/SKILL.md`

```
---
name: background-processing
description: Generates background processing infrastructure with BGTaskScheduler, background refresh, background downloads, and silent push handling. Use when user needs background tasks, periodic refresh, background URLSession downloads, or silent push notification processing.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Background Processing Generator

Generate production background processing infrastructure -- BGTaskScheduler for periodic refresh and long-running tasks, background URLSession for downloads/uploads that survive app termination, and silent push handling for server-triggered updates.

## When This Skill Activates

Use this skill when the user:
- Asks to "add background processing" or "background tasks"
- Mentions "BGTaskScheduler" or "BGAppRefreshTask" or "BGProcessingTask"
- Wants "background refresh" or "periodic background updates"
- Asks about "background downloads" or "background uploads"
- Mentions "silent push" or "content-available push notifications"
- Wants data to sync or update while the app is in the background
- Asks about "background fetch" or "background execution"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (BGTaskScheduler requires iOS 13+)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Existing Background Task Detection
Search for existing background task code:
```
Glob: **/*BackgroundTask*.swift, **/*BGTask*.swift, **/*BackgroundDownload*.swift
Grep: "BGTaskScheduler" or "BGAppRefreshTask" or "BGProcessingTask" or "backgroundSession"
```

If existing background code found:
- Ask if user wants to replace or augment it
- If augmenting, identify what is missing and generate only those pieces

```

---
### `characterization-test-generator` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/characterization-test-generator/SKILL.md`

```
---
name: characterization-test-generator
description: Claude Code adapter for the shared characterization test generator skill. Use when you need a safety net before AI-assisted refactoring or modifying legacy code.
allowed-tools: [Read, Glob, Grep]
---

# Characterization Test Generator Adapter

Shared skill source:

`../../../.agents/skills/characterization-test-generator/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `ci-cd-setup` 

路径: `.claude/skills/ci-cd-setup/SKILL.md`

```
---
name: ci-cd-setup
description: Generate CI/CD configuration for automated builds, tests, and distribution of iOS/macOS apps. Use when setting up GitHub Actions, Xcode Cloud, or fastlane for continuous integration, TestFlight, or App Store deployment.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# CI/CD Setup Generator

Generate CI/CD configuration for automated builds, tests, and distribution of iOS/macOS apps.

## When This Skill Activates

- User wants to automate their build and test process
- User mentions GitHub Actions, Xcode Cloud, or fastlane
- User wants to set up TestFlight or App Store deployment
- User asks about continuous integration for their app

## Pre-Generation Checks

Before generating, verify:

1. **Existing CI Configuration**
   ```bash
   # Check for existing CI files
   ls -la .github/workflows/ 2>/dev/null
   ls -la ci_scripts/ 2>/dev/null
   ls -la fastlane/ 2>/dev/null
   ```

2. **Project Structure**
   ```bash
   # Find Xcode project/workspace
   find . -name "*.xcodeproj" -o -name "*.xcworkspace" | head -5
   ```

3. **Package Manager**
   ```bash
   # Check for SPM vs CocoaPods
   ls Package.swift 2>/dev/null
   ls Podfile 2>/dev/null
```

---
### `coding-best-practices` 

路径: `.claude/skills/coding-best-practices/SKILL.md`

```
---
name: coding-best-practices
description: Reviews Swift/iOS code for adherence to modern Swift idioms, Apple platform best practices, architecture patterns, and code quality standards. Use when user mentions best practices, code review, clean code, refactoring, or wants to improve code quality.
allowed-tools: [Read, Glob, Grep]
---

# Coding Best Practices Skill

Reviews Swift/iOS code for adherence to modern Swift idioms, Apple platform best practices, architecture patterns, and code quality standards.

## When This Skill Activates

Use this skill when the user:
- Asks for code review or code quality check
- Mentions "best practices", "clean code", or "refactoring"
- Wants to improve existing code
- Requests architecture or design pattern review
- Asks about Swift idioms or modern patterns
- Wants performance optimization suggestions

## Review Process

### 1. Identify Scope

- If user specifies files/classes, review those
- Otherwise, ask which areas to focus on or review recent changes
- Prioritize ViewModels, business logic, and data layer over simple views

### 2. Load Reference Patterns

Before starting the review, familiarize yourself with the reference patterns by reading the following files in `.claude/skills/coding-best-practices/`:

- **swift-patterns.md** - Optionals, type safety, collections, error handling, naming
- **swiftui-patterns.md** - State management, view composition, performance
- **architecture-patterns.md** - MVVM, code organization, memory management, security
- **coredata-patterns.md** - Core Data best practices, fetching, saving, relationships

### 3. Review Categories

Apply these review categories based on the code type:
```

---
### `cross-audit` 

路径: `.claude/skills/cross-audit/SKILL.md`

```
---
name: cross-audit
description: 三方对抗性审查工作流（Claude + Codex + Gemini）。强制 F-008「相同完整任务、不分工」纪律。当用户要求"三方审计/对抗性审查/独立审计/cross-audit"，或 PR 合并前需对抗性 review 时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Agent
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /cross-audit — 三方对抗性审查工作流

## 触发场景

- 用户说："三方审计 / 对抗性审查 / 独立审计 / cross-audit"
- PR 合并前需对抗性 review（DoD 要求 F-005）
- 大型重构 / 文档系统性变更前

## 必须遵守的纪律（F-008 + F-011 + F-012）

1. **F-008 相同完整任务**：三家审同**同一批文件**完整集合，**不分工**。冗余是刻意的——通过"你发现了我没发现的"暴露盲区
2. **F-011 被审范围只读**：三方启动后不得修改被审文件；`Write` 只允许落审计报告，等汇总后统一修复
3. **F-012 不偷懒**：禁止抽查后声称"基本准确"，必须全量

## 启动前 checklist

- [ ] 已读取 `docs/standards/codex-delegation.md`（默认 effort high for 审计/Review）
- [ ] 已读取 `docs/standards/gemini-delegation.md`（不加 sandbox，防 7 分钟卡死）
- [ ] 已读取 `docs/standards/shared-constraints.md`（必须内联到 prompt）
- [ ] 审计目标和文件清单已明确（写下来，不要口头默认）
- [ ] 审计报告落盘路径已明确；所有委派 prompt 已写明"不得修改被审文件"

## 三方启动模板

### 给 Claude（主线程）
```
你审 [审计目标]，范围 [完整文件清单]，五维度（DRY/YAGNI/Skill 化/一致性/时效性）。
不分工，独立完成全部。
PR 审查场景必须补 4 维评分：Scope Fidelity / Code Quality / Test Coverage /
Architecture Fit（0-10 分，整数），见 cross-audit-consensus §2.5。
```

### 给 Codex（Agent 委派或 codex exec）
```
```

---
### `cross-audit-consensus` 

路径: `.claude/skills/cross-audit-consensus/SKILL.md`

```
---
name: cross-audit-consensus
description: 把 Claude/Codex/Gemini 三方独立审计/研究输出，折成"共识 / 单家独有 / 冲突"裁决表。当用户要求汇总三方对抗结果，或 cross-audit skill 已产出三方报告需要比对时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /cross-audit-consensus — 三方对抗结果汇总

## 触发场景

- 用户说："汇总三方 / 比对三方 / 出共识表"
- `cross-audit` skill 已产出三方独立报告，需要 Claude 充当 reviewer 折叠
- Hermes 研究、文档审计等三方完成后

## 输出格式（强制）

### 1. 三方完成度速览

```markdown
| 方 | 状态 | 字数 | 关键发现数 |
|---|---|---|---|
| Claude | ✅ 完整 | ~4000 | 8 |
| Codex | ✅ 完整 | ~4500 | 11 |
| Gemini | ❌ 失败/偏短 | 1.3KB | 0 实质 |
```

如有方失败，必须**显式标注**（参考 `feedback_gemini_adversarial.md`：Gemini 在某些场景偏短/幻觉，不得静默忽略）。

### 2. 共识表

```markdown
| 发现/方案 | Claude | Codex | Gemini | 共识 | 证据 |
|---|---|---|---|---|---|
| [简短描述] | Critical | Critical | — | 2/3 ✅ | 文件:行号 / URL |
```

**裁决原则**：
- 2/3 共识默认采纳
- 1/3 独有发现进 `docs/memory/decisions.md` 备忘（不采纳但不丢）
- 0 共识 / 严重冲突 → 用户裁决（不缝合方案）
```

---
### `data-export` 

路径: `.claude/skills/data-export/SKILL.md`

```
---
name: data-export
description: Generates data export/import infrastructure for JSON, CSV, PDF formats with GDPR data portability, share sheet integration, and file import. Use when user wants data export functionality, CSV/JSON/PDF export, GDPR compliance data portability, import from files, or share sheet for data.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Data Export Generator

Generate production data export and import infrastructure -- JSON export via Codable, CSV generation with proper escaping, PDF report rendering with UIGraphicsPDFRenderer, GDPR-compliant full data export, file import with UTType-based picker, and share sheet integration. No third-party dependencies.

## When This Skill Activates

Use this skill when the user:
- Asks to "add data export" or "export user data"
- Wants "CSV export" or "JSON export" or "PDF export"
- Mentions "GDPR data portability" or "right to data portability"
- Asks about "exporting all user data" for compliance
- Wants to "import data" from files or competitor apps
- Mentions "share sheet" for exporting data
- Asks about "data backup" or "data download"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Identify data model layer (SwiftData, Core Data, custom structs)
- [ ] Identify source file locations

### 2. Existing Export Detection
Search for existing export code:
```
Glob: **/*Export*.swift, **/*Import*.swift, **/*CSV*.swift, **/*PDF*.swift
Grep: "UIGraphicsPDFRenderer" or "CSVExport" or "UIActivityViewController" or "ShareLink" or "fileExporter"
```

If existing export code found:
- Ask if user wants to replace or add additional formats
- Identify which formats are already supported

```

---
### `decision-closeout` 

路径: `.claude/skills/decision-closeout/SKILL.md`

```
---
name: decision-closeout
description: 产品决策变更后闭环收尾。影响评估 → 下游同步 → ADR 更新 → Issue 关闭 → STATUS.md。当用户说"决策变更/决定改了/更新决策/decision closeout"或产品文档变更涉及决策变化时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /decision-closeout — 决策变更收尾闭环

## 一句话

产品决策变更不是改完文档就完了。必须沿依赖链传播，确保所有下游文档与决策一致。

> 权威源：`docs/protocol.md` § 决策变更收尾。本 skill 为执行器。

## 触发场景

- 产品决策变更（vision/design/requirements/ADR 修改）
- 用户说："决策变更 / 决定改了 / 更新决策 / decision closeout"
- PR 涉及 `docs/product/` 或 `docs/decisions/` 的实质性变更

## 执行步骤

### Step 1: 影响评估

```bash
# 用 dependency-propagation skill 或手动 grep
grep -r "<变更关键词>" docs/ --include="*.md" -l
```

参考 `docs/DOC_DEPENDENCY_MAP.md` 变更传播规则，列出所有受影响的文档。

### Step 2: 同步更新

对每个受影响的下游文档（按 `docs/DOC_DEPENDENCY_MAP.md` §2 主链分组）：

**产品主链**：
- `product-requirements.md` / `product-design.md` / `product-cases.md` — 功能规格同步
- `product-glossary.md` — 术语一致性
- `product-business.md` — 商业模式影响

```

---
### `deep-linking` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/deep-linking/SKILL.md`

```
---
name: deep-linking
description: Claude Code adapter for the shared deep linking skill. Use when handling custom URL schemes, Universal Links/Associated Domains, or routing to specific content from external sources.
allowed-tools: [Read, Glob, Grep]
---

# Deep Linking Skill Adapter

Shared skill source:

`../../../.agents/skills/deep-linking/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `dependency-propagation` 

路径: `.claude/skills/dependency-propagation/SKILL.md`

```
---
name: dependency-propagation
description: 文档变更后传播同步。当改了任何文档/API/ADR 后，按 DOC_DEPENDENCY_MAP.md 找到所有下游文件，grep 具体引用并同步更新。当用户说"同步下游/传播变更/propagate/更新下游文档"或改完文档后自动触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /dependency-propagation — 文档变更传播

## 一句话

改了一个文档后，不能只改这一个。依赖图里的所有下游文件必须检查并同步。

## 触发场景

- 改了任何产品/技术/标准文档后
- 改了 public API 后
- 新建/更新 ADR 后
- 用户说："同步下游 / 传播变更 / propagate / 更新下游文档"
- PR 合并后发现下游不一致（修复场景）

## 工作流

### Step 1：确定变更源

明确刚才改了什么：
- **文件路径**：改的是哪个文档
- **变更类型**：新增事实 / 修改已有事实 / 删除 / 重命名
- **变更内容**：一句话描述改了什么

### Step 2：查依赖图找下游

读 `docs/DOC_DEPENDENCY_MAP.md` §2 变更传播规则表，找到该文件的下游清单：

```
改动源头 → 最少同步清单
product-vision.md → design + requirements + business + cases + glossary + compliance
ADR-* → 相关 product/tech 文档 + 实现代码与测试
product-design.md / product-requirements.md → cases + business
compliance.md / NFR.md → deployment
代码 public 接口 → api-reference.md
```

---
### `dod-checklist` 

路径: `.claude/skills/dod-checklist/SKILL.md`

```
---
name: dod-checklist
description: PR 完成前逐项检查 Definition of Done。当用户说"检查 DoD/自检/验收/准备合并"或 PR 即将提交 Review 时触发。按改动类型（代码/文档/UI）加载对应子集。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
context: fork
disable-model-invocation: false
user-invocable: true
---

# /dod-checklist — PR 完成前 DoD 自检

## 一句话

逐项检查当前 PR 是否满足 Definition of Done。按改动类型自动筛选相关检查项。

## 触发场景

- 用户说："检查 DoD / 自检 / 验收 / 准备合并"
- 代码写完准备提交 Review 前
- sprint-contract 完成后，push 前

## 检查项

> 权威源：`docs/protocol.md` § Definition of Done。本 skill 为执行器。

### 代码质量（所有 PR）

- [ ] `swiftlint --strict` 0 violations
- [ ] `xcodebuild build-for-testing -scheme AllTests -testPlan AllTests` 0 errors
- [ ] CI test 通过（已有测试不得回归）
- [ ] 改接口签名后 grep 测试同步
- [ ] 涉及新 API/新交互时 PR 描述留有研究证据
- [ ] 新增抽象有明确必要性（原则 2：删掉比添加好）
- [ ] 功能不超出 Issue scope（原则 3：不为假设需求写代码）
- [ ] 跨模块边界有明确的契约定义（原则 5）
- [ ] 复杂业务状态由 ViewModel 集中编排（原则 6）
- [ ] 不可逆决策有记录（原则 7）—— 重大走 ADR，小决策在 PR 描述说明
- [ ] Codex 对抗性审查通过
- [ ] Xcode Review 核实通过（UI 改动必须）
- [ ] AI 反模式检查通过

### 功能完整性（feature/chore）

```

---
### `error-monitoring` 

路径: `.claude/skills/error-monitoring/SKILL.md`

```
---
name: error-monitoring
description: Generates protocol-based error/crash monitoring with swappable providers (Sentry, Crashlytics). Use when user wants to add crash reporting, error tracking, or production monitoring.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Error Monitoring Generator

Generates a production-ready error monitoring infrastructure with protocol-based architecture for easy provider swapping.

## When This Skill Activates

- User asks to "add crash reporting" or "error monitoring"
- User mentions "Sentry", "Crashlytics", or "crash analytics"
- User wants to "track errors in production"
- User asks about "debugging production issues"

## Pre-Generation Checks (CRITICAL)

### 1. Project Context Detection

Before generating, ALWAYS check:

```bash
# Check for existing crash reporting
rg -l "Sentry|Crashlytics|CrashReporter" --type swift

# Check Package.swift for existing SDKs
cat Package.swift | grep -i "sentry\|firebase\|crashlytics"

# Check for existing error handling patterns
rg "captureError|recordError|logError" --type swift | head -5
```

### 2. Conflict Detection

If existing crash reporting found:
- Ask: Replace, wrap existing, or create parallel system?

## Configuration Questions
```

---
### `harness-recall` 

路径: `.claude/skills/harness-recall/SKILL.md`

```
---
name: harness-recall
description: 自进化闭环执行器。扫描 handoff.md Risks 段 + anti-pattern-scan 警报，检查重复问题模式。同类问题 ≥3 次 → propose 新 F-0XX 规则。当 phase-closeout / 接手新会话 / 用户说"体检/harness recall/自检重复问题"时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /harness-recall — 自进化闭环（错误→永久修复）

## 一句话

扫描 `docs/memory/handoff.md` 的 Risks 段和 anti-pattern-scan 警报，检查重复模式。同类问题出现 ≥3 次 → 主动 propose 新 F-0XX 规则供用户裁决。

> 权威源：`docs/standards/harness-recall.md`。本 skill 为执行器。

## 触发时机

1. **phase-closeout**：更新 handoff.md 前，扫描现有 Risks 段
2. **接手新会话**：读 `docs/memory/handoff.md` 后
3. **用户说 "体检 / 知识体系审计 / harness recall / 自检重复问题"**

## 执行步骤

### Step 1: 收集信号

```bash
# handoff.md 的 Risks 段
grep -A 50 '^## Risks' docs/memory/handoff.md

# 检查重复关键词
grep -n '重复\|recur\|again\|再次\|又出现' docs/memory/handoff.md

# anti-pattern-scan
bash Scripts/anti-pattern-scan.sh
```

### Step 2: 归类去重

将信号按问题类别归并（"test evasion"、"scope creep"、"concurrency 违规"、"文档过期"等），统计每类出现次数。

### Step 3: 三击判断（F-019 升级版）
```

---
### `integration-test-scaffold` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/integration-test-scaffold/SKILL.md`

```
---
name: integration-test-scaffold
description: Claude Code adapter for the shared integration test scaffold skill. Use when testing networking + persistence + business logic together.
allowed-tools: [Read, Glob, Grep]
---

# Integration Test Scaffold Adapter

Shared skill source:

`../../../.agents/skills/integration-test-scaffold/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `keyword-optimizer` 

路径: `.claude/skills/keyword-optimizer/SKILL.md`

```
---
name: keyword-optimizer
description: Optimize app title, subtitle, and keywords for maximum App Store discoverability. Use when launching a new app, improving search rankings, entering new markets/languages, or safely optimizing ASO for an app with existing traffic.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, WebSearch]
---

# Keyword Optimizer

Optimize app title, subtitle, and keywords for maximum App Store discoverability.

## When This Skill Activates

- User is launching a new app
- User wants to improve search rankings
- User asks about ASO (App Store Optimization)
- User is entering new markets/languages
- User wants to analyze keyword opportunities
- User needs safe optimization for existing apps

## Reference Files

Before optimizing, load these reference materials:

| File | Purpose |
|------|---------|
| **keyword-criteria.md** | Popularity/Difficulty sweet spots, opportunity scoring |
| **advanced-tactics.md** | Cross-localization, screenshot indexing, velocity boost |
| **existing-app-strategy.md** | Safe optimization for apps with existing traffic |

## Information Gathering

Before optimizing, ask about:

1. **App Identity**
   - What does the app do in one sentence?
   - What category is it in?
   - What's the current app name (if exists)?

2. **Target Keywords**
   - What would users search to find this app?
```

---
### `knowledge-health` 

路径: `.claude/skills/knowledge-health/SKILL.md`

```
---
name: knowledge-health
description: 知识体系体检。跑 docaudit all + 扫描 CI 看不到的私有空间（~/.claude/plans/、~/.claude/projects/.../memory/），产出分层修复计划到 ~/.claude/plans/knowledge-health-YYYY-MM-DD.md。不改任何文件，只产 plan。触发时机：用户说"体检 / 知识体系审计 / /knowledge-health"，或 /phase-closeout 收官末尾。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /knowledge-health — 知识体系体检

## 设计原则

- **只产 plan，不改任何文件**：所有修复动作写到 plan 文件，由用户或后续 PR 执行。可逆性 + 幂等性基线。
- **覆盖 CI 盲区**：`docaudit` 只扫 workspace（CI 可见部分）；skill 补扫 Claude 私有空间（CI 不可见）。
- **分层报告**：CI-visible（docaudit 原始输出）+ CI-invisible（Claude 本地视角）清晰分段。

## 触发场景

- 用户说："体检 / 知识体系审计 / `/knowledge-health`"
- `/phase-closeout` 末尾建议跑一次（phase 合并 ≥ 3 PR 后）
- 接手新 session 发现 STATUS.md 过期 / 有待办积压时

## 执行步骤

### 1. 跑 docaudit 全量扫描

```bash
python3 Scripts/audit/docaudit.py all --verbose
python3 Scripts/audit/docaudit.py all --baseline --verbose  # baseline 视角对比
python3 Scripts/audit/docaudit.py all --report --baseline   # 落盘 TSV
```

### 2a. 软上限触线检查

`docs/KNOWLEDGE_MAP.md` 声明活跃知识文件软上限 ~50（超过 ~45 优先合并/退役，超过 ~50 必须先退役才能新增）。

```bash
COUNT=$(find docs/ -name "*.md" -not -path "*/archive/*" -not -path "*/reference/*" | wc -l | tr -d ' ')
if [ "$COUNT" -gt 50 ]; then
  echo "🔴 $COUNT/50 已超硬触线 — 必须退役才能新增"
elif [ "$COUNT" -gt 45 ]; then
  echo "🟡 $COUNT/50 已过软触线 — 新增前必须先列退役/合并候选"
```

---
### `liquid-glass` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/liquid-glass/SKILL.md`

```
---
name: liquid-glass
description: Claude Code adapter for the shared Liquid Glass design skill. Use when creating modern glass-based UI effects.
allowed-tools: [Read, Glob, Grep]
---

# Liquid Glass Design Adapter

Shared skill source:

`../../../.agents/skills/liquid-glass/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `localization-setup` 

路径: `.claude/skills/localization-setup/SKILL.md`

```
---
name: localization-setup
description: Generate internationalization (i18n) infrastructure for multi-language support in iOS/macOS apps. Use when localizing for multiple languages, adopting String Catalogs (xcstrings), or supporting RTL languages.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Localization Setup Generator

Generate internationalization (i18n) infrastructure for multi-language support in iOS/macOS apps.

## When This Skill Activates

- User wants to localize their app for multiple languages
- User mentions i18n, internationalization, or localization
- User asks about String Catalogs or .strings files
- User wants to support RTL (right-to-left) languages

## Pre-Generation Checks

Before generating, verify:

1. **Existing Localization**
   ```bash
   # Check for existing localization files
   find . -name "*.xcstrings" -o -name "Localizable.strings" 2>/dev/null | head -5
   find . -name "*.lproj" -type d 2>/dev/null | head -5
   ```

2. **Deployment Target**
   ```bash
   # String Catalogs require iOS 16+ / macOS 13+
   grep -r "IPHONEOS_DEPLOYMENT_TARGET\|MACOSX_DEPLOYMENT_TARGET" *.xcodeproj 2>/dev/null
   ```

3. **Project Structure**
   ```bash
   # Find project for adding localization
   find . -name "*.xcodeproj" | head -1
   ```

```

---
### `migration-patterns` 

路径: `.claude/skills/migration-patterns/SKILL.md`

```
---
name: migration-patterns
description: Migration guides for CoreData to SwiftData, UIKit to SwiftUI, ObservableObject to @Observable, XCTest to Swift Testing, Objective-C to Swift, and StoreKit 1 to StoreKit 2. Use when migrating between Apple framework generations.
allowed-tools: [Read, Glob, Grep]
---

# Migration Patterns

Comprehensive guides for migrating between Apple framework generations. Each guide covers the full before/after mapping, coexistence strategies, and common pitfalls.

## When This Skill Activates

- User asks how to migrate from CoreData to SwiftData
- User is moving UIKit code to SwiftUI (or embedding one in the other)
- User needs to update from ObservableObject/Combine to @Observable/AsyncSequence
- User is converting XCTest tests to Swift Testing
- User asks about coexistence strategies (running old and new frameworks side by side)
- User wants to know whether a migration is worth doing for their situation
- User is migrating Objective-C code to Swift (bridging headers, incremental migration)
- User is migrating from StoreKit 1 to StoreKit 2 (in-app purchases, subscriptions)
- User encounters errors during a framework migration

## Decision Tree

```
What are you migrating?
|
+-- Data persistence layer
|   +-- CoreData --> SwiftData
|   |   See coredata-to-swiftdata.md
|   |   Min: iOS 17 / macOS 14
|   |
|   +-- Still need CoreData features SwiftData lacks?
|       Stay on CoreData or use coexistence mode
|
+-- UI framework
|   +-- UIKit --> SwiftUI
|   |   See uikit-to-swiftui.md
|   |   Min: iOS 13 (basic), iOS 16+ (modern navigation)
|   |
```

---
### `navigation-patterns` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/navigation-patterns/SKILL.md`

```
---
name: navigation-patterns
description: Claude Code adapter for the shared SwiftUI navigation architecture skill. Use when reviewing or building navigation, fixing navigation bugs, or architecting app flow.
allowed-tools: [Read, Glob, Grep]
---

# Navigation Patterns Skill Adapter

Shared skill source:

`../../../.agents/skills/navigation-patterns/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `onboarding-generator` 

路径: `.claude/skills/onboarding-generator/SKILL.md`

```
---
name: onboarding-generator
description: Generates multi-step onboarding flows with persistence for iOS/macOS apps. Use when user wants to add onboarding, welcome screens, or first-launch experience.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Onboarding Generator

Generate a complete, customizable onboarding flow with persistence, animations, and accessibility support.

## When This Skill Activates

Use this skill when the user:
- Asks to "add onboarding" or "create onboarding"
- Mentions "welcome screens" or "first launch"
- Wants to "show intro on first launch"
- Asks about "onboarding flow" or "tutorial screens"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing onboarding implementations
- [ ] Identify if SwiftUI or UIKit project
- [ ] Find App entry point location
- [ ] Check deployment target (TabView paging requires iOS 14+)

### 2. Conflict Detection
Search for existing onboarding:
```
Glob: **/*Onboarding*.swift, **/*Welcome*.swift
Grep: "hasCompletedOnboarding" or "isFirstLaunch"
```

If found, ask user:
- Replace existing onboarding?
- Keep existing, add new flow?

## Configuration Questions

Ask user via AskUserQuestion:
```

---
### `phase-closeout` 

路径: `.claude/skills/phase-closeout/SKILL.md`

```
---
name: phase-closeout
description: 长任务（多 PR / 跨多天的 phase）收官时，将阶段状态写入 docs/memory/handoff.md。当用户说"收官 / 阶段总结 / 写 checkpoint"或单个 phase 合并 ≥ 3 PR 时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /phase-closeout — 长任务 checkpoint 生成

## 触发场景

- 用户说："phase 结束 / 收官 / 写 checkpoint / 阶段总结"
- 单个 phase / sprint 合并 ≥ 3 PR 后（参考 `docs/protocol.md` Phase Compaction 规则）
- 接手前发现 STATUS.md 落后多个 PR

## 标准输出

```markdown
---
last_verified: <YYYY-MM-DD>
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint <YYYY-MM-DD> <主题>

## Goal
本 phase 想解决的问题（一句话；引用 Issue/ADR）

## Done
- PR #N <主题>（关键改动 + 受影响 layer + 测试增量）
- ...

## Open
- 待合并 PR
- 待解决子任务（指针到 Issue）

## Decisions
- 关键技术/产品决策（指针到 ADR / discussion / 三方研究）
- 拒绝的方案 + 理由
```

---
### `post-merge` 

路径: `.claude/skills/post-merge/SKILL.md`

```
---
name: post-merge
description: PR 合并后必做清单。CI post-merge 检查 → STATUS.md 更新 → anti-pattern-scan → 文档同步检查。当用户说"合并了/post-merge/合并后/收尾"或 PR 刚合并后自动触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /post-merge — PR 合并后收尾

## 一句话

PR 合并不是终点。合并后有 4 个必做步骤，少一个都会让项目状态漂移。

## 触发场景

- PR 刚合并（`gh pr merge` 完成后）
- 用户说："合并了 / post-merge / 合并后 / 收尾 / cleanup"
- CI 跑完后确认 develop 分支状态

## 工作流

### Step 1：Post-merge CI 检查（F-007 时点 2）

合并后等 30 秒让 CI 触发，然后检查：

```bash
sleep 30
gh run list --branch develop --limit 3
```

如果有 failure：
- **立即停下手头所有工作**
- 排查 failure 原因
- 修复后推新的 fix commit
- CI 不绿不推进下一个 PR

如果 CI 仍在 QUEUED（Mac mini 排队中），等 runner 分配到自己。

### Step 2：更新 STATUS.md

```bash
```

---
### `privacy-manifests` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/privacy-manifests/SKILL.md`

```
---
name: privacy-manifests
description: Claude Code adapter for the shared privacy manifest skill. Use when preparing apps for App Store privacy requirements.
allowed-tools: [Read, Glob, Grep]
---

# Privacy Manifests Skill Adapter

Shared skill source:

`../../../.agents/skills/privacy-manifests/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `push-notifications` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/push-notifications/SKILL.md`

```
---
name: push-notifications
description: Claude Code adapter for the shared push notifications skill. Use when adding push notifications, configuring APNs, notification categories/actions, or rich notifications with images and custom UI.
allowed-tools: [Read, Glob, Grep]
---

# Push Notifications Skill Adapter

Shared skill source:

`../../../.agents/skills/push-notifications/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `resume-from-handoff` 

路径: `.claude/skills/resume-from-handoff/SKILL.md`

```
---
name: resume-from-handoff
description: 新 Claude 会话接手项目时，按最小上下文加载顺序读取，避免强吃长 transcript。当会话开始或用户说"接手 / 续上次工作 / resume / handoff"时触发。
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
context: fork
disable-model-invocation: false
user-invocable: true
---

# /resume-from-handoff — 接手时最小上下文加载

## 触发场景

- 新会话第一次工作于 SnapDrill 项目
- 用户说："接手 / 续上次工作 / resume / 你看看现状 / 我们到哪了"
- 长会话 compact 后需要重建上下文

## 加载顺序（严格按序，少即是多）

按 Hermes "less context, more retrieval" 思想（参考 `docs/archive/research/hermes-agent-study-20260418.md`）。

### Tier 1：必读（5 文件，约 800 行）
1. `CLAUDE.md` —— 项目入口（已自动加载）
2. `STATUS.md` —— 当前快照
3. `docs/memory/handoff.md` —— 接手状态、待合并 PR、阻塞
4. `docs/memory/feedback.md` —— 项目纪律（F-001~F-N）
5. `docs/standards/collaboration.md` —— 三方协作架构（如即将做对抗审查）

### Tier 2：按需（用户描述任务后再读）
6. 任务相关的 `docs/standards/<rule>.md`（如改代码 → coding.md）
8. 任务相关的 `docs/product/<file>.md`（如改产品文档 → 对应文件）
9. 当前 git 状态：`git status` + `git log --oneline -10` + `gh pr list --state open --author '@me'`

### Tier 3：避免（除非明确需要）
- ❌ 全部 `docs/memory/decisions.md`（除非要写新 ADR）
- ❌ 全部 `~/.claude/plans/*`（旧三方对抗汇总，仅相关任务时按需）
- ❌ 全部 STATUS.md 历史段（看头部"当前状态"段即可）

## 不加载长 transcript

- 不强吃"上次会话的全部对话"
- 不读完整 ADR 历史
- 不展开所有 docs/product/ 内容
```

---
### `review-response-writer` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/review-response-writer/SKILL.md`

```
---
name: review-response-writer
description: Claude Code adapter for the shared App Store review response skill. Use when responding to negative reviews, drafting templates, or improving review management strategy.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# Review Response Writer Skill Adapter

Shared skill source:

`../../../.agents/skills/review-response-writer/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `screenshot-planner` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/screenshot-planner/SKILL.md`

```
---
name: screenshot-planner
description: Claude Code adapter for the shared App Store screenshot planning skill. Use when preparing App Store assets, improving screenshot conversion, or drafting screenshot captions.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# Screenshot Planner Skill Adapter

Shared skill source:

`../../../.agents/skills/screenshot-planner/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `settings-screen` 

路径: `.claude/skills/settings-screen/SKILL.md`

```
---
name: settings-screen
description: Generates a complete settings screen for iOS/macOS apps with common sections. Use when user wants to add settings, preferences, or configuration UI.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Settings Screen Generator

Generates a production-ready settings screen with modular sections for iOS and macOS apps.

## When This Skill Activates

- User asks to "add settings" or "create settings screen"
- User mentions "preferences", "app settings", or "configuration UI"
- User wants to add dark mode toggle, notifications settings, or about screen

## Pre-Generation Checks (CRITICAL)

### 1. Project Context Detection

Before generating, ALWAYS check:

```
# Find existing settings implementations
rg -l "SettingsView|PreferencesView|SettingsScreen" --type swift

# Check deployment target
cat Package.swift | grep -i "platform"
# Or check project.pbxproj for deployment target

# Detect architecture pattern
rg -l "Observable|ObservableObject|@EnvironmentObject" --type swift | head -5

# Check platform (iOS vs macOS)
rg "UIKit|UIApplication" --type swift | head -1  # iOS
rg "AppKit|NSApplication" --type swift | head -1  # macOS
```

### 2. Conflict Detection

```

---
### `snapshot-diff-review` 

路径: `.claude/skills/snapshot-diff-review/SKILL.md`

```
---
name: snapshot-diff-review
description: Snapshot 测试 baseline 变更审查。当 snapshot 测试产生新的 baseline 或 baseline 变更时，git diff 图片确认视觉变化是有意的再提交。当用户说"snapshot 变了/baseline 更新/快照测试/snapshot test/record snapshots"时触发。
allowed-tools:
  - Bash
  - Read
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /snapshot-diff-review — Snapshot Baseline 审查

## 一句话

Snapshot baseline 变更是二进制图片，git diff 看不出内容。必须逐张确认视觉变化是有意为之，再提交。

## 触发场景

- 运行 snapshot 测试后 baseline 发生变化
- `SNAPSHOT_TESTING_RECORD=1` 模式录制了新 baseline
- 用户说："snapshot 变了 / baseline 更新 / 快照测试 / record snapshots"
- CI 报告 snapshot 测试失败（baseline mismatch）

## 工作流

### Step 1：确认变更范围

```bash
# 查看哪些 baseline 文件变更了
git diff --name-only | grep -i "snapshot\|baseline\|Snapshots"

# 或查看所有未提交的 baseline 变更
git status | grep -i "snapshot\|baseline"
```

### Step 2：逐张 diff

对每个变更的 baseline 图片：

```bash
# 查看图片 diff（如果 git 支持）
git diff <path-to-baseline-image>

# 或者用 Finder 预览新旧对比
```

---
### `snapshot-testing` 

路径: `.claude/skills/snapshot-testing/SKILL.md`

```
---
name: snapshot-test-setup
description: Set up SwiftUI visual regression testing with swift-snapshot-testing. Generates snapshot test boilerplate and CI configuration. Use for UI regression prevention.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Snapshot Test Setup

Generate SwiftUI snapshot/visual regression tests using Point-Free's swift-snapshot-testing library. Catches unintended UI changes by comparing rendered views against reference images.

## When This Skill Activates

Use this skill when the user:
- Wants "snapshot tests" or "visual regression tests"
- Says "I want to catch UI regressions"
- Asks about "screenshot testing" or "preview testing"
- Wants to verify SwiftUI views don't change unexpectedly
- Mentions "swift-snapshot-testing" or "Point-Free"

## Why Snapshot Tests

```
Without snapshots:        With snapshots:
Change a modifier         Change a modifier
  → Looks fine locally      → Snapshot test fails
  → Push to main            → Shows exact visual diff
  → User reports UI bug     → Fix before merging
  → Embarrassing             → Confidence in UI changes
```

## Pre-Setup Checks

### 1. Project Context

```
Glob: **/Package.swift or **/*.xcodeproj
Grep: "swift-snapshot-testing" (already added?)
Grep: "SnapshotTesting" in test files
```

```

---
### `sprint-contract` 

路径: `.claude/skills/sprint-contract/SKILL.md`

```
---
name: sprint-contract
description: 编码前契约强制执行（F-018）。feature Issue 动代码前，先研究代码库确定 Touches/No-Touch/Interface Delta/Test Additions/DoD 最小集，贴 Sprint Contract comment 到 Issue。当用户说"开工/开始编码/做这个 Issue/贴 contract/sprint contract"或 Issue 进入 Building 状态时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /sprint-contract — 编码前契约

## 一句话

动第一行代码前，必须在 Issue 贴 Sprint Contract。编码中 contract 变更必须先改 comment 再改代码。

## 触发条件

- feature 类 Issue（`enhancement` label）进入 Building
- chore Appetite >= Medium
- 用户说："开工 / 开始编码 / 做这个 Issue / 贴 contract / sprint contract"

## 豁免

- bug_report 类（scope 天然小）
- trivial 改动（单行 typo/注释/日志，不改行为/接口/测试）
- Small Appetite 的 chore（可简化为 Touches / No-Touch / DoD 最小集三条）

## 工作流

### Step 1：读 Issue 确认范围

```bash
gh issue view <number>
```

提取：Scope、No-Go、验收标准（Given-When-Then）、MoSCoW、Appetite。

### Step 2：研究代码库

在动代码前先研究，确定实际会碰哪些文件：

```bash
# 搜相关代码
```

---
### `swift-concurrency-pro` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/swift-concurrency-pro/SKILL.md`

```
---
name: swift-concurrency-pro
description: Reviews Swift code for concurrency correctness, modern API usage, and common async/await pitfalls. Use when reading, writing, or reviewing Swift concurrency code.
license: MIT
metadata:
  author: Paul Hudson
  version: "1.0"
---

Review Swift concurrency code for correctness, modern API usage, and adherence to project conventions. Report only genuine problems - do not nitpick or invent issues.

Review process:

1. Scan for known-dangerous patterns using `references/hotspots.md` to prioritize what to inspect.
1. Check for recent Swift 6.2 concurrency behavior using `references/new-features.md`.
1. Validate actor usage for reentrancy and isolation correctness using `references/actors.md`.
1. Ensure structured concurrency is preferred over unstructured where appropriate using `references/structured.md`.
1. Check unstructured task usage for correctness using `references/unstructured.md`.
1. Verify cancellation is handled correctly using `references/cancellation.md`.
1. Validate async stream and continuation usage using `references/async-streams.md`.
1. Check bridging code between sync and async worlds using `references/bridging.md`.
1. Review any legacy concurrency migrations using `references/interop.md`.
1. Cross-check against common failure modes using `references/bug-patterns.md`.
1. If the project has strict-concurrency errors, map diagnostics to fixes using `references/diagnostics.md`.
1. If reviewing tests, check async test patterns using `references/testing.md`.

If doing a partial review, load only the relevant reference files.


## Core Instructions

- Target Swift 6.2 or later with strict concurrency checking.
- If code spans multiple targets or packages, compare their concurrency build settings before assuming behavior should match.
- Prefer structured concurrency (task groups) over unstructured (`Task {}`).
- Prefer Swift concurrency over Grand Central Dispatch for new code. GCD is still acceptable in low-level code, framework interop, or performance-critical synchronous work where queues and locks are the right tool – don't flag these as errors.
- If an API offers both `async`/`await` and closure-based variants, always prefer `async`/`await`.
- Do not introduce third-party concurrency frameworks without asking first.
- Do not suggest `@unchecked Sendable` to fix compiler errors. It silences the diagnostic without fixing the underlying race. Prefer actors, value types, or `sending` parameters instead. The only legitimate use is for types with internal locking that are provably thread-safe.


## Output Format

Organize findings by file. For each issue:
```

---
### `swiftdata-pro` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/swiftdata-pro/SKILL.md`

```
---
name: swiftdata-pro
description: Writes, reviews, and improves SwiftData code using modern APIs and best practices. Use when reading, writing, or reviewing projects that use SwiftData.
license: MIT
metadata:
  author: Paul Hudson
  version: "1.0"
---

Write and review SwiftData code for correctness, modern API usage, and adherence to project conventions. Report only genuine problems - do not nitpick or invent issues.

Review process:

1. Check for core SwiftData issues using `references/core-rules.md`.
1. Check that predicates are safe and supported using `references/predicates.md`.
1. If the project uses CloudKit, check for CloudKit-specific constraints using `references/cloudkit.md`.
1. If the project targets iOS 18+, check for indexing opportunities using `references/indexing.md`.
1. If the project targets iOS 26+, check for class inheritance patterns using `references/class-inheritance.md`.

If doing partial work, load only the relevant reference files.


## Core Instructions

- Target Swift 6.2 or later, using modern Swift concurrency.
- The user strongly prefers to use SwiftData across the board. Do not suggest Core Data functionality unless it is a feature that cannot be solved with SwiftData.
- Do not introduce third-party frameworks without asking first.
- Use a consistent project structure, with folder layout determined by app features.


## Output Format

If the user asks for a review, organize findings by file. For each issue:

1. State the file and relevant line(s).
2. Name the rule being violated.
3. Show a brief before/after code fix.

Skip files with no issues. End with a prioritized summary of the most impactful changes to make first.

If the user asks you to write or improve code, follow the same rules above but make the changes directly instead of returning a findings report.

Example output:
```

---
### `swiftui-debugging` 

路径: `.claude/skills/swiftui-debugging/SKILL.md`

```
---
name: swiftui-debugging
description: Diagnose SwiftUI performance issues including unnecessary re-renders, view identity problems, and slow body evaluations. Use when SwiftUI views are slow, janky, or re-rendering too often.
allowed-tools: [Read, Glob, Grep]
---

# SwiftUI Performance Debugging

Systematic guide for diagnosing and fixing SwiftUI performance problems: unnecessary view re-evaluations, identity issues, expensive body computations, and lazy loading mistakes.

## When This Skill Activates

Use this skill when the user:
- Reports slow or janky SwiftUI views
- Sees excessive view re-renders or body re-evaluations
- Asks about `Self._printChanges()` or view debugging
- Has scrolling performance issues with lists or grids
- Asks why a view keeps updating when nothing changed
- Mentions `@Observable` or `ObservableObject` performance differences
- Wants to understand SwiftUI view identity or diffing
- Uses `AnyView` and asks about performance implications
- Has a hang or stutter traced to SwiftUI rendering

## Decision Tree

```
What SwiftUI performance problem are you seeing?
|
+- Views re-render when they should not
|  +- Read body-reevaluation.md
|     +- Self._printChanges() to identify which property changed
|     +- @Observable vs ObservableObject observation differences
|     +- Splitting views to narrow observation scope
|
+- Scrolling is slow / choppy (lists, grids)
|  +- Read lazy-loading.md
|     +- VStack vs LazyVStack, ForEach without lazy container
|     +- List prefetching, grid cell reuse
|
+- Views lose state unexpectedly / animate when they should not
```

---
### `swiftui-pro` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/swiftui-pro/SKILL.md`

```
---
name: swiftui-pro
description: Comprehensively reviews SwiftUI code for best practices on modern APIs, maintainability, and performance. Use when reading, writing, or reviewing SwiftUI projects.
license: MIT
metadata:
  author: Paul Hudson
  version: "1.1"
---

Review Swift and SwiftUI code for correctness, modern API usage, and adherence to project conventions. Report only genuine problems - do not nitpick or invent issues.

Review process:

1. Check for deprecated API using `references/api.md`.
1. Check that views, modifiers, and animations have been written optimally using `references/views.md`.
1. Validate that data flow is configured correctly using `references/data.md`.
1. Ensure navigation is updated and performant using `references/navigation.md`.
1. Ensure the code uses designs that are accessible and compliant with Apple’s Human Interface Guidelines using `references/design.md`.
1. Validate accessibility compliance including Dynamic Type, VoiceOver, and Reduce Motion using `references/accessibility.md`.
1. Ensure the code is able to run efficiently using `references/performance.md`.
1. Quick validation of Swift code using `references/swift.md`.
1. Final code hygiene check using `references/hygiene.md`.

If doing a partial review, load only the relevant reference files.


## Core Instructions

- iOS 26 exists, and is the default deployment target for new apps.
- Target Swift 6.2 or later, using modern Swift concurrency.
- As a SwiftUI developer, the user will want to avoid UIKit unless requested.
- Do not introduce third-party frameworks without asking first.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Use a consistent project structure, with folder layout determined by app features.


## Output Format

Organize findings by file. For each issue:

1. State the file and relevant line(s).
2. Name the rule being violated (e.g., "Use `foregroundStyle()` instead of `foregroundColor()`").
3. Show a brief before/after code fix.
```

---
### `tdd-bug-fix` 

路径: `.claude/skills/tdd-bug-fix/SKILL.md`

```
---
name: tdd-bug-fix
description: Fix bugs using red-green-refactor — reproduce the bug as a failing test first, then fix it. Use when fixing bugs to ensure they never regress.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# TDD Bug Fix

Fix bugs the right way: reproduce first, fix second, verify always. Especially critical when using AI to generate fixes — the test ensures the AI actually solved the problem.

## When This Skill Activates

Use this skill when the user:
- Reports a bug and wants it fixed
- Says "this is broken" or "this doesn't work"
- Asks to "fix and add a test" or "fix with TDD"
- Wants to ensure a bug doesn't come back
- Is skeptical of AI-generated fixes ("how do I know it's actually fixed?")

## Why TDD for Bug Fixes

```
Without TDD:           With TDD:
Bug reported           Bug reported
  → AI generates fix     → Write failing test (RED)
  → Deploy               → AI generates fix (GREEN)
  → Hope it works        → Test passes — confirmed fixed
  → Bug returns later    → Test prevents regression forever
```

## Process

### Phase 1: Understand the Bug

Gather information:

1. **What's the expected behavior?**
2. **What's the actual behavior?**
3. **Steps to reproduce?**
4. **Which code is involved?**
```

---
### `tdd-feature` 

路径: `.claude/skills/tdd-feature/SKILL.md`

```
---
name: tdd-feature
description: Red-green-refactor scaffold for building new features with TDD. Write failing tests first, then implement to pass. Use when building new features test-first.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# TDD Feature

Build new features using the red-green-refactor cycle. Tests define the spec, AI generates the implementation, tests verify correctness.

## When This Skill Activates

Use this skill when the user:
- Wants to "TDD a new feature" or "build test-first"
- Says "I want tests before code"
- Asks for "red-green-refactor" workflow
- Wants AI to generate code that's provably correct
- Is building a new module, service, or feature from scratch

## Why TDD for New Features with AI

```
Traditional:     AI generates code → You hope it's correct → Ship → Find bugs
TDD with AI:     You write tests (spec) → AI generates code to pass → Proven correct
```

The test is your **acceptance criteria in code form**. AI excels at going from failing test to passing implementation — it's a concrete, unambiguous target.

## Process

### Phase 1: Define the Feature

Before writing any code or tests, understand:

1. **What does this feature do?** (user story or requirement)
2. **What are the inputs?** (parameters, user actions, data)
3. **What are the outputs?** (return values, state changes, UI updates)
4. **What are the edge cases?** (empty, nil, error, boundary)
5. **What dependencies does it need?** (network, storage, other services)

```

---
### `tdd-refactor-guard` 

路径: `.claude/skills/tdd-refactor-guard/SKILL.md`

```
---
name: tdd-refactor-guard
description: Pre-refactor safety checklist. Verifies test coverage exists before AI modifies existing code. Use before asking AI to refactor anything.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# TDD Refactor Guard

A safety gate that runs before any AI-assisted refactoring. Ensures tests exist to catch regressions. If coverage is insufficient, generates characterization tests first.

## When This Skill Activates

Use this skill when the user:
- Says "refactor this" or "clean this up"
- Wants AI to "restructure" or "reorganize" code
- Asks to "extract", "inline", "rename", or "simplify" existing code
- Plans to migrate between patterns (e.g., MVC → MVVM, CoreData → SwiftData)
- Wants AI to "improve" or "modernize" existing code

## Why This Guard Exists

```
Without guard:               With guard:
"Claude, refactor this"      "Claude, refactor this"
  → AI rewrites code           → Guard checks for tests
  → Something breaks           → Tests missing → generate them
  → You don't know what        → Tests pass → proceed with refactor
  → Debugging nightmare         → Tests fail → exact regression found
```

## Process

### Step 1: Identify Scope

What code is being refactored?

```
Ask user: "Which files/classes are you planning to refactor?"
```

```

---
### `test-contract` ✓ (双份存在 .agents/skills/)

路径: `.claude/skills/test-contract/SKILL.md`

```
---
name: test-contract
description: Claude Code adapter for the shared test contract skill. Use when designing protocols or swapping implementations.
allowed-tools: [Read, Glob, Grep]
---

# Test Contract Adapter

Shared skill source:

`../../../.agents/skills/test-contract/SKILL.md`

When this skill activates, read and follow the shared skill source. This file exists only to preserve Claude Code discovery while the project migrates portable skills to `.agents/skills/`.

```

---
### `tipkit-generator` 

路径: `.claude/skills/tipkit-generator/SKILL.md`

```
---
name: tipkit-generator
description: Generate TipKit infrastructure with inline/popover tips, rules, display frequency, and testing utilities. Use when adding contextual tips or feature discovery to an iOS/macOS app.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# TipKit Generator

Generate a complete TipKit setup for contextual tips and feature discovery, including tip definitions, rules, display frequency, inline and popover presentation, and testing utilities.

## When This Skill Activates

Use this skill when the user:
- Asks to "add tips" or "add TipKit"
- Mentions "contextual tips" or "feature discovery"
- Wants "popover tips" or "inline tips"
- Asks about "coach marks" or "user education"
- Mentions "onboarding hints" or "tip prompts"
- Wants to "highlight new features" or "guide users"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (TipKit requires iOS 17+ / macOS 14+)
- [ ] Identify if SwiftUI or UIKit project
- [ ] Find App entry point location for Tips.configure()
- [ ] Check for existing TipKit implementations

### 2. Conflict Detection
Search for existing TipKit usage:
```
Glob: **/*Tip*.swift
Grep: "import TipKit" or "Tips.configure"
```

If found, ask user:
- Extend existing tip infrastructure?
- Replace existing tips?

## Configuration Questions
```

---
### `ui-review` 

路径: `.claude/skills/ui-review/SKILL.md`

```
---
name: ui-review
description: Review SwiftUI code for iOS/watchOS Human Interface Guidelines compliance, font usage, Dynamic Type support, and accessibility. Use when user mentions UI review, HIG, accessibility audit, font checks, or wants to verify interface design against Apple standards.
allowed-tools: [Read, Glob, Grep, WebFetch]
---

# UI Review Skill

Performs comprehensive UI/UX review of SwiftUI code against Apple's Human Interface Guidelines, font best practices, and accessibility standards for iOS and watchOS.

## When This Skill Activates

Use this skill when the user:
- Asks to review UI/UX code
- Mentions HIG compliance or Apple guidelines
- Requests accessibility audit
- Wants font usage checked
- Asks about Dynamic Type support
- Requests design review against Apple standards

## Review Process

### 1. Identify Files to Review

- If user specifies files/views, review those
- Otherwise, ask which views to review or scan recent SwiftUI files
- Prioritize user-facing views over components

### 2. Load Reference Materials

Before starting the review, familiarize yourself with the reference materials by reading the following files in `.claude/skills/ui-review/`:

- **hig-checklist.md** - Comprehensive HIG compliance checklist for iOS and watchOS
- **font-guidelines.md** - Font usage, Dynamic Type, and typography best practices
- **accessibility-quick-ref.md** - Quick reference for accessibility implementation

You may also reference the official Apple guidelines using WebFetch when needed:
- **iOS HIG**: https://developer.apple.com/design/human-interface-guidelines/designing-for-ios
- **watchOS HIG**: https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos

```

---
### `verify-audit-report` 

路径: `.claude/skills/verify-audit-report/SKILL.md`

```
---
name: verify-audit-report
description: 审计报告真伪验证。接收任何审计报告（Codex/Gemini/baseline/cross-audit）后，逐条 grep + Read 源码确认 finding 真实性，输出验证报告。当用户说"核实审计/验证报告/verify audit/查证 finding"或收到审计报告后自动触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
---

# /verify-audit-report — 审计报告真伪验证

## 一句话

审计报告里的 finding 不能直接信。每个 finding 必须用源码验证后才算数。

## 触发场景

- 收到任何审计报告后（Codex / Gemini / 基线审计 / cross-audit）
- 用户说："核实审计 / 验证报告 / verify audit / 查证 finding"
- cross-audit 三方报告到位后，汇总前（F-006 + F-012 强制）

## 核心纪律

### F-006：深度验证，不是浅层 grep

每个 finding 必须回答"代码具体怎么做的"，不只是"代码里有没有这个名字"。
- grep 找到符号后，Read 源码至少 **10-20 行上下文** 确认行为一致
- 对 "X 功能缺失" 类 finding，搜索备选实现路径（可能用不同 API 实现了相同功能）
- 验证深度标准：能向用户解释代码的实际执行路径

### F-012：全量做，不抽查

- 报告中每条 finding 逐一验证，禁止抽样后声称"基本准确"
- 超过 20 条 finding 时可分批，但必须明确告知覆盖范围
- 大量机械性检查写脚本自动化，不逐条手工

### Gemini 特别纪律

Gemini 对"功能是否实现"和"文档是否匹配"的判断不可信（已知幻觉模式）：
- Gemini 的 Critical/Warning 必须交叉验证（已知 2/2 Critical 误判历史）
- Gemini 声称"X 缺失"时，搜索是否用其他命名/路径实现了
- Gemini 声称"文档说 Y"时，在文档源文件中逐字找原文（Gemini 会编造章节号）

```

---
### `xcode-review` 

路径: `.claude/skills/xcode-review/SKILL.md`

```
---
name: xcode-review
description: Xcode Intelligence Review 提示词撰写指南。当用户说"写 Xcode 提示词/Xcode Review/提交 Xcode 审查"或 PR 涉及 UI 改动需要 Xcode 审查时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
context: fork
disable-model-invocation: false
user-invocable: true
last_verified: 2026-05-19
layer: pattern
---

# 手动 Review 提示词写作规范

> **上游依赖**：`docs/protocol.md`（Code Review）
>
> 每次为 PR 撰写手动 review 提示词时，参照此规范。
> 适用于：**外部 Reviewer**（如 Antigravity 等全量代码上下文工具，可选）和 **Xcode Intelligence Review**（项目内上下文）。
> 目标：风格统一、关注点完整、简洁自然语言、聚焦本次变更的特有风险。

---

## 结构（按顺序）

### 1. 开头（一句话）

`请对 PR #N（branch: xxx）进行全量 Code Review，` + 一句话概括本次变更的目的。

### 2. 变更概要

用 bullet list 说明改了什么、涉及哪些模块。每个 bullet 一句话，说清"改了什么"而非"怎么改的"。
不需要列全部文件路径，按模块粒度即可。

### 3. 本次审查重点

3-5 条针对本次变更的特有风险点，用"请重点关注"引出。这是每次提示词唯一需要定制的部分。

写法原则：
- 聚焦本次变更引入的新风险，不重复通用检查项
- 用提问句式引导审查方向（如"xxx 是否会导致 yyy"）
- 如涉及用户旅程变更，明确引用 docs/product/product-journeys.md「旅程」中的旅程编号
- 如涉及新 API，要求检查与 docs/tech/api-pitfalls.md 的一致性

### 4. 固定收尾

每次提示词末尾固定附加以下两段：
```
