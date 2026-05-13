# CODEX.md — Codex 入口

> 路由文件，不是知识库。项目知识在 docs/。

## Boot

1. 读 `STATUS.md` — 当前工作上下文
2. 读 `docs/workflow.md` — 流程、DoD、Review 规范
3. 读 `docs/standards/README.md` — 项目标准与约束索引
4. 读 `docs/memory/feedback.md` — 项目纪律（所有智能体共遵）

## Context Map

| 需要 | 去读 |
|---|---|
| 项目标准 | `docs/standards/` |
| 项目反馈与纪律 | `docs/memory/feedback.md` |
| 产品文档 | `docs/product/` |
| 技术文档 | `docs/tech/` |
| 项目记忆 | `docs/memory/` |
| 流程与 DoD | `docs/workflow.md` |
| 知识地图 | `docs/KNOWLEDGE_MAP.md` |
| 架构决策 | `docs/decisions/ADR-*.md` |

## 执行门

```bash
swiftlint --strict        # 0 violations
xcodebuild build-for-testing \
  -scheme SnapDrill \
  -destination 'platform=iOS Simulator,name=iPhone 17'  # 0 errors
```

完整 DoD 见 `docs/workflow.md`。

## 项目一句话

SnapDrill：练习题数字化效率工具。SwiftUI / SwiftData / iOS 26.0+ / Swift 6.3 / defaultIsolation(MainActor)。
