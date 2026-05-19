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

> **上游依赖**：`docs/workflow.md`（Code Review）
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
项目约束见 CLAUDE.md 和 .claude/ 目录。除上述重点外，请同时关注：
- Swift 6 strict concurrency 合规（@MainActor、Task 句柄、Sendable）
- 是否有更原生的 Apple API 可替代自定义实现
- 与 docs/tech/api-pitfalls.md 常见错误防范表的一致性（新增/修改的 public API 是否遵循已知陷阱）
- 内存与性能影响（尤其图片加载、大列表、频繁 I/O 场景）
```

```
输出格式：按严重程度分类——
- 🔴 必须修复（编译错误、逻辑缺陷、并发安全、数据丢失风险）
- 🟡 建议改进（命名不一致、可优化但不影响正确性）
- 🟢 信息提示（风格建议、未来改进方向）

请在回复末尾附加一行水印，格式如下（替换为你实际使用的 IDE/载体 和模型名称）：
> 由 {IDE/载体名} 自动生成（模型：{模型名称和版本}）。合并前请人工确认。

水印必须同时声明**载体**（运行环境）和**模型**（AI 模型），以便区分同一模型在不同载体上的 review：
- Claude Code CLI（终端）：`由 Claude Code CLI 自动生成（模型：Claude Opus 4.7）`
- Xcode Intelligence：`由 Xcode Intelligence 自动生成（模型：Claude Opus 4.7）`

请通过 `gh pr comment N --body "..."` 将 Review 结果发布到 GitHub PR #N（注意：使用 pr comment，不是 pr review）。
```

---

## 后续 Review（二次/三次验收）

### 核心原则

**首次 review 同一提示词（控制变量），后续 review 按 reviewer 分别写提示词（验收各自的 finding）。**

原因：首次 review 两个 reviewer 收到相同输入，但输出不同（模型差异）。修复是针对特定 reviewer 的特定 finding，验收必须让同一 reviewer 确认"我提的问题是否被正确解决"。

### 何时需要后续 review

参照 `docs/workflow.md` Code Review 纪律：
- **需要**：fix 引入新业务逻辑、新跨模块依赖、新文件
- **不需要**：纯结构性修复（重命名、访问控制、import 调整）

### 结构

```
请对 PR #N 的 fix commit（{commit hash}）进行验收 Review。
这是对你上一轮 review 发现的 {N} 个问题的修复，请验证实现是否符合你的意图。

上轮发现与本次修复对照：
1. **{原 finding 摘要}** → {修复方式一句话}
2. ...

请重点验收：
- {针对该 reviewer 的具体验收问题}
- ...

{固定收尾（同首次 review）}
```

### 与首次 review 的差异

| 维度 | 首次 review | 后续 review |
|---|---|---|
| 提示词 | Antigravity = Xcode（控制变量） | 按 reviewer 分别写（验收各自 finding） |
| 重点 | 通用风险扫描 | 特定 finding 的修复验收 |
| 变更概要 | 描述 PR 整体改动 | 只描述 fix commit 改了什么 |
| 触发对象 | 两个 reviewer 都触发 | 只触发提出问题的 reviewer |

---

## 风格约束

- **简洁自然语言**，不使用过度层级嵌套
- **不重复架构全貌**——reviewer 拥有代码上下文
- **审查重点中按需引用文件**，不单独罗列文件清单
- **总长度不超过 25 行**——提示词过长反而稀释重点
- **首次 review**：如使用多个 reviewer，可使用相同提示词（控制变量），差异来自模型本身
- **后续 review 分别写**：针对各 reviewer 的特定 finding 撰写验收提示词

---

## 示例（首次 review）

> **虚构示例**：以下 PR #232 与 `FieldSelectionOnboardingView` 是为说明 prompt 结构而构造的，**不对应仓库内真实类型/PR**。实际写 review prompt 时请替换为真实 PR 号与代码类型。

```
请对 PR #232（branch: feat/issue-195-onboarding-field-selection）进行全量 Code Review，
在 Onboarding 流程末尾增加字段选择步骤。

变更：
- OnboardingView.swift 新增 FieldSelectionOnboardingView 作为第 5 页
- 使用 @AppStorage 写入与 Settings 相同的 captureField* key
- TabView 页数从 pages.count 改为 totalPages（含字段选择页）

请重点关注：
- FieldSelectionOnboardingView 的 @AppStorage 默认值是否与 SettingsView 一致
- TabView 分页逻辑（totalPages / fieldSelectionIndex）是否正确处理边界
- 字段选择页的布局在小屏（iPhone SE）上是否会溢出
- 「跳过」按钮是否正确跳过字段选择（不写入任何值，保持默认）

项目约束见 CLAUDE.md 和 .claude/ 目录。除上述重点外，请同时关注：
- Swift 6 strict concurrency 合规（@MainActor、Task 句柄、Sendable）
- 是否有更原生的 Apple API 可替代自定义实现
- 与 docs/tech/api-pitfalls.md 常见错误防范表的一致性（新增/修改的 public API 是否遵循已知陷阱）
- 内存与性能影响（尤其图片加载、大列表、频繁 I/O 场景）

输出格式：按严重程度分类——
- 🔴 必须修复（编译错误、逻辑缺陷、并发安全、数据丢失风险）
- 🟡 建议改进（命名不一致、可优化但不影响正确性）
- 🟢 信息提示（风格建议、未来改进方向）

请在回复末尾附加一行水印，格式如下（替换为你实际使用的 IDE/载体 和模型名称）：
> 由 {IDE/载体名} 自动生成（模型：{模型名称和版本}）。合并前请人工确认。

水印必须同时声明**载体**（运行环境）和**模型**（AI 模型），以便区分同一模型在不同载体上的 review：
- Claude Code CLI（终端）：`由 Claude Code CLI 自动生成（模型：Claude Opus 4.7）`
- Xcode Intelligence：`由 Xcode Intelligence 自动生成（模型：Claude Opus 4.7）`

请通过 `gh pr comment 232 --body "..."` 将 Review 结果发布到 GitHub PR #232（注意：使用 pr comment，不是 pr review）。
```

## 示例（后续 review — Antigravity 验收）

```
请对 PR #339 的 fix commit（7b68de5）进行验收 Review。
这是对你上一轮 review 发现的两个 🔴 问题的修复，请验证实现是否符合你的意图。

上轮发现与本次修复对照：
1. **autoreleasepool 作用域错误** → 在 PDFExportService 的 for chunk 循环内补加 try autoreleasepool
2. **.task 无 id 导致编辑后图片不刷新** → 改为 .task(id: item.imagePath)，nil 时显式清空

请重点验收：
- try autoreleasepool 的位置是否正确覆盖了 draw(in:) 临时对象？
- .task(id:) 能否正确响应编辑后的路径变更？

{固定收尾}

请通过 `gh pr comment 339 --body "..."` 将 Review 结果发布到 GitHub PR #339（注意：使用 pr comment，不是 pr review）。
```

注意：这份只发给 Antigravity（提出问题的 reviewer）。如果 Xcode Intelligence 首次 review 也提出了不同的问题并被修复，则单独给 Xcode 写一份验收提示词。
