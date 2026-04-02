# CLAUDE.md

SnapDrill 项目的 AI Agent 操作系统。定义启动流程、上下文加载、执行铁律和协作模式。

---

## 启动（Boot）

**回复用户第一条消息前，必须执行：**

1. 读取 `STATUS.md` — 恢复当前工作上下文（在做什么、优先级、外部阻塞）
2. **决策导航** — 基于 STATUS.md 当前状态，主动向用户建议下一步优先事项：
   - 按 `docs/workflow.md` 的 S0-S3 严重度排序：有 S0/S1 未解决 → 最高优先
   - 按 WIP 限制：有待 Review PR 未合并 → 先 Review 再开新任务
   - 按价值链：录入 > 管理 > 导出 > 复习（见 `product-design.md`）
   - 按外部阻塞：被阻塞的事项跳过，标注阻塞原因
   - 输出格式："**建议优先做 X**，原因：Y。备选：Z。"

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
| `docs/product/product-cases.md` | 写 Issue 验收标准、审查异常路径、QA 回归时 |
| `docs/tech/architecture.md` | 讨论架构、模块边界、DI、新开发者入门时 |
| `docs/tech/api-reference.md` | 查询 Protocol 定义、Repository/Service 公开方法时 |
| `docs/tech/compliance.md` | 讨论隐私合规、App Store 审核、数据处理时 |
| `docs/tech/deployment.md` | 讨论发布流程、CI/CD、版本管理时 |
| `docs/tech/non-functional-requirements.md` | 讨论性能指标、内存限制、存储基准时 |

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

终端和 Xcode 中是**同一个 Claude（claude-opus-4-6）**，区别是入口和工具集：

| 入口 | 上下文 | 独有能力 | 适合场景 |
|---|---|---|---|
| **终端（Max 订阅）** | 1M token | 大上下文全局分析 | 规划、重构、文档审计、研究 |
| **Xcode** | 200K token | 19 个 MCP（Preview、DocumentationSearch、实时诊断） | SwiftUI 开发、Apple API、编译修复 |

两者共享：Bash、Git/gh、WebSearch、Auto Memory、文件读写。
选择原则：**需要大上下文 → 终端。需要看 UI 或查 Apple 文档 → Xcode。**
交流方式：GitHub Issue comment（两个入口都能读写）。

## 开发闭环（详见 docs/workflow.md）

```
Shaped → Building (WIP≤2) → Reviewing → Done
```

- 每个 Issue 有 appetite（S/M/L）+ 验收标准 + no-go
- Build 中发现范围外问题 → 立即建新 Issue，不在当前 PR 处理
- 固定时间可变范围，不是做完才发
