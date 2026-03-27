# CLAUDE.md

SnapDrill 项目的 AI Agent 操作系统。定义启动流程、上下文加载、执行铁律和协作模式。

---

## 启动（Boot）

**回复用户第一条消息前，必须执行：**

1. 读取 `STATUS.md` — 恢复当前工作上下文（在做什么、优先级、外部阻塞）

对话记录由 Auto Memory 自动管理（`~/.claude/projects/` 下的 MEMORY.md），无需手动加载。

## 全局上下文（每次对话强制加载）

**开始解决问题前，必须主动读取：**

- `docs/workflow.md` — 开发闭环（看板 + Git + Review + 优先级）

编码规范、API 踩坑、Apple 能力边界、工程哲学、Apple 原生模式、测试策略均已迁移到 `.claude/rules/`，碰到相关文件时自动加载，无需手动读取。

## 按需上下文（涉及时读取）

| 文件 | 何时读取 |
|---|---|
| `docs/product/product-vision.md` | 讨论产品方向、新功能、用户画像时 |
| `docs/product/product-design.md` | 涉及 UI/UX 设计决策、交互铁律时 |
| `docs/product/product-requirements.md` | 讨论功能规格、版本路线图时 |
| `docs/product/product-journeys.md` | 验证用户体验、审查 UI 流程时 |
| `docs/product/product-business.md` | 讨论商业化、隐私策略、竞品时 |

**铁律**：修改任何代码前，必须先读取相关的产品文档确认需求。不碰产品文档就写代码是方法论缺陷。

## 项目概要

SnapDrill：练习题数字化存档 + 间隔重复复习 App。
技术栈：SwiftUI · SwiftData · iOS 26.0+
包结构和依赖方向见各 `Packages/*/Package.swift`。
架构决策（Domain 层/UseCase 层/Repository 协议已删除、SwiftData、DI Container + @Environment）不得在未经用户批准的情况下推翻。

## 执行铁律

### 每次修改代码后必须验证

```bash
swiftlint --strict
# 编译验证（含测试 target，比 xcodebuild build 更严格）
xcodebuild build-for-testing \
  -scheme SnapDrill \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

**只有 0 errors + 0 violations 才能向用户回复"完成"或提交代码。**

### 关键陷阱

- `swift test` 不可用 — SPM 包仅声明 iOS 平台，必须通过 Xcode Simulator 运行
- `xcodebuild build` 不编译测试 target — 必须用 `build-for-testing` 才能发现测试编译错误
- 改接口签名后必须 `grep -rn "TypeName(" Tests/` 检查所有测试文件是否同步

## 记忆固化（State Write-back）

**以下时机必须主动更新：**

- PR 合并后 → 更新 `STATUS.md`（允许直推 develop，不需要 PR）
- 产品决策变更时 → 同一回复中 Grep 影响范围 → 创建执行 Issue

对话记录由 Auto Memory 自动管理，无需手动维护。

## 协作模式

| 角色 | 职责 | 优势 |
|---|---|---|
| **产品负责人（用户）** | Shape Issue、Pull 任务、最终验收 | 产品判断 |
| **Claude Code（本文件的执行者）** | 主 agent：规划、复核、统筹全局 | 1M 上下文、跨模块分析 |
| **Xcode Intelligence** | 主力执行：代码实现、Apple 文档查询 | Apple 生态 MCP |

交流方式：GitHub Issue comment（Xcode 可直接读写，无需用户复制粘贴）。

## 开发闭环（详见 docs/workflow.md）

```
Shaped → Building (WIP≤2) → Reviewing → Done
```

- 每个 Issue 有 appetite（S/M/L）+ 验收标准 + no-go
- Build 中发现范围外问题 → 立即建新 Issue，不在当前 PR 处理
- 固定时间可变范围，不是做完才发
