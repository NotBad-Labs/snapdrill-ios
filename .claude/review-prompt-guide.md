# Antigravity Review 提示词写作规范

> **上游依赖**：`workflow.md`（Code Review 铁律、操作手册）
>
> 每次为 PR 撰写 Antigravity review 提示词时，参照此规范。
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
- 如涉及用户旅程变更，明确引用 product-journeys.md 中的旅程编号
- 如涉及新 API，要求检查与 infrastructure.md 的一致性

### 4. 固定收尾

每次提示词末尾固定附加以下两段：

```
项目约束见 CLAUDE.md 和 .claude/ 目录。除上述重点外，请同时关注：
- Swift 6 strict concurrency 合规（@MainActor、Task 句柄、Sendable）
- 是否有更原生的 Apple API 可替代自定义实现
- 与 infrastructure.md 公开接口清单的一致性（新增/修改的 public API 是否已同步）
- 内存与性能影响（尤其图片加载、大列表、频繁 I/O 场景）
```

```
输出格式：按严重程度分类——
- 🔴 必须修复（编译错误、逻辑缺陷、并发安全、数据丢失风险）
- 🟡 建议改进（命名不一致、可优化但不影响正确性）
- 🟢 信息提示（风格建议、未来改进方向）

请将 Review 结果以 comment 形式发布到 GitHub PR #N。
```

---

## 风格约束

- **简洁自然语言**，不使用过度层级嵌套
- **不重复架构全貌**——Antigravity 拥有全量代码上下文
- **审查重点中按需引用文件**，不单独罗列文件清单
- **总长度不超过 25 行**——提示词过长反而稀释重点

---

## 示例

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
- 与 infrastructure.md 公开接口清单的一致性（新增/修改的 public API 是否已同步）
- 内存与性能影响（尤其图片加载、大列表、频繁 I/O 场景）

输出格式：按严重程度分类——
- 🔴 必须修复（编译错误、逻辑缺陷、并发安全、数据丢失风险）
- 🟡 建议改进（命名不一致、可优化但不影响正确性）
- 🟢 信息提示（风格建议、未来改进方向）

请将 Review 结果以 comment 形式发布到 GitHub PR #232。
```
