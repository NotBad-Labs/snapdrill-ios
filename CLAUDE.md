# CLAUDE.md

SnapDrill 项目的 AI Agent 操作系统。定义启动流程、上下文加载、执行铁律和协作模式。

---

## 启动（Boot）

**回复用户第一条消息前，必须执行：**

1. 读取 `STATUS.md` — 恢复当前工作上下文（在做什么、优先级、外部阻塞）
2. **决策导航** — 基于 STATUS.md 当前状态，主动向用户建议下一步优先事项：
   - 按 `docs/workflow.md` 的 S0-S3 严重度排序：有 S0/S1 未解决 → 最高优先
   - 按 WIP 限制：有待 Review PR 未合并 → 先 Review 再开新任务
   - 按价值链：采集 > 管理 > 导出/打印 > 复习（见 `product-design.md`）
   - 按外部阻塞：被阻塞的事项跳过，标注阻塞原因
   - 输出格式："**建议优先做 X**，原因：Y。备选：Z。"

对话记录由 Auto Memory 自动管理（`~/.claude/projects/` 下的 MEMORY.md），无需手动加载。

## 全局上下文（每次对话强制加载）

**开始解决问题前，必须主动读取：**

- `docs/workflow.md` — 开发闭环（看板 + Git + Review + 优先级 + 交叉审计）

编码规范、API 踩坑、Apple 能力边界、工程哲学、Apple 原生模式、测试策略、协作模式均已迁移到 `.claude/rules/`，碰到相关文件时自动加载，无需手动读取。

## 按需上下文（涉及时读取）

- 产品：`docs/product/` 下 vision / design / requirements / journeys / business / cases / glossary
- 技术：`docs/tech/` 下 architecture / api-reference / compliance / deployment / non-functional-requirements

**铁律**：修改任何代码前，必须先读取相关的产品文档确认需求。不碰产品文档就写代码是方法论缺陷。

## 项目概要

SnapDrill：练习题数字化存档 + 间隔重复复习 App。
技术栈：SwiftUI · SwiftData · iOS 26.0+
包结构和依赖方向见各 `Packages/*/Package.swift`。
架构决策（Domain 层/UseCase 层/Repository 协议已删除、SwiftData、DI Container + @Environment）不得在未经用户批准的情况下推翻。

## 执行铁律

每次修改代码后必须通过 `swiftlint --strict` + `xcodebuild build-for-testing`（0 errors + 0 violations）。
完整命令、参数和陷阱清单见 `.claude/rules/coding.md`。

## 记忆固化（State Write-back）

**以下时机必须主动更新：**

- PR 合并后 → 更新 `STATUS.md`（允许直推 develop，不需要 PR）
- 产品决策变更时 → 同一回复中 Grep 影响范围 → 创建执行 Issue
