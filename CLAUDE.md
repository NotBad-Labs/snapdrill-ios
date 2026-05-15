# CLAUDE.md — Claude Code 入口

> 路由文件，不是知识库。项目知识在 docs/。

## Boot

1. 读 `STATUS.md` — 当前工作上下文
2. 读 `docs/workflow.md` — 流程、DoD、Review 规范
3. `docs/standards/*.md` 由 `.claude/rules/` 自动路由加载（碰到相关文件时触发）
4. 读 `docs/memory/feedback.md` — 项目纪律（所有智能体共遵）

## Context Map

| 需要 | 去读 |
|---|---|
| 项目原则 | `docs/standards/`（`.claude/rules/` 自动路由） |
| 项目反馈与纪律 | `docs/memory/feedback.md` |
| 产品文档 | `docs/product/` |
| 技术文档 | `docs/tech/` |
| 项目记忆 | `docs/memory/` |
| 流程与 DoD | `docs/workflow.md` |
| 知识地图 | `docs/KNOWLEDGE_MAP.md` |
| 架构决策 | `docs/decisions/ADR-*.md` |
| 权限模型 | `docs/standards/permission-model.md` |

## 执行门

```bash
swiftlint --strict        # 0 violations
xcodebuild build-for-testing \
  -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests        # 0 errors
```

测试用 `AllTests` scheme + `AllTests` testPlan（SnapDrill scheme 不含 SPM 包测试）。完整 DoD 见 `docs/workflow.md`。

## 项目一句话

SnapDrill：练习题数字化效率工具。SwiftUI / SwiftData / iOS 26.0+ / Swift 6.3 / defaultIsolation(MainActor)。
