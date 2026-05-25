# AGENTS.md — SnapDrill 项目入口

SnapDrill：练习题数字化效率工具；SwiftUI / SwiftData / iOS 26.0+ / Swift 6.3。

> 路由文件，不是知识库。项目知识在 docs/。

## Boot

1. 读 `docs/meta/M-000-meta-vision.md` — 最高协作宪法。
2. 读 `docs/meta/user-decision-log.md` — 已生效用户裁决与 Overrule。

## Action Gate

触发改代码、改文档、提 PR、merge、push、跑 lint/test 前，读 `docs/protocol.md`，按阶段进入对应 skill 或文档。

## Context Map

| 需要 | 去读 |
|---|---|
| standards | `docs/standards/` |
| feedback / F 规则索引 | `docs/memory/feedback.md` |
| SSOT 注册表 | `docs/meta/M-000-meta-vision.md` §11 |
| 变更传播 | `docs/DOC_DEPENDENCY_MAP.md` |
| 元规则入口 | `docs/meta/README.md` |
| M-001~M-006 backlog | `docs/meta/M-001-to-M-006-followup-backlog.md` |
| 状态 stub | `STATUS.md` |
| 起草模板 | `docs/meta/M-000-input-prompt.md`、`docs/meta/M-000-round2-input.md`、`docs/meta/M-000-final-prompt.md`、`docs/meta/M-000-round3-review-prompt.md` |

## 执行门

```bash
swiftlint --strict        # 0 violations
xcodebuild build-for-testing \
  -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests        # 0 errors
```

测试用 `AllTests` scheme + `AllTests` testPlan；`SnapDrill` scheme 不含 SPM 包测试。完整 DoD 入口见 `docs/protocol.md`。

<!-- nwc: 993 -->
