# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 启动时强制加载

**必须**在回复用户第一条消息前，读取 `STATUS.md` 恢复当前工作上下文。

## 自动注入（每次对话都需要的）

@.claude/architecture.md
@.claude/conventions.md
@.claude/infrastructure.md

## 按需读取（涉及时再读）

| 文件 | 何时读取 |
|---|---|
| `.claude/product-vision.md` | 讨论产品方向、新功能、用户画像时 |
| `.claude/product-requirements.md` | 讨论具体功能需求、版本路线图时 |
| `.claude/product-journeys.md` | 验证用户体验、审查 UI 流程时 |
| `.claude/product-business.md` | 讨论商业化、隐私策略、竞品时 |
| `.claude/principles.md` | 做架构决策、技术选型时 |
| `.claude/workflow.md` | 创建 PR、Code Review、Issue 管理时 |
| `.claude/glossary.md` | 需要理解项目术语时 |
| `.claude/session-log.md` | 需要回顾上次对话做了什么时 |

## Commands

```bash
swiftlint --strict                    # Lint（从项目根目录运行）
xcodebuild test -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17'  # 测试
```

SPM 包仅声明 iOS 平台，`swift test` 不可用，须通过 Xcode Simulator 运行测试。
`xcodebuild build` 不编译测试 target，测试编译错误须通过 Xcode 才能发现。

## Architecture

SnapDrill：练习题数字化存档 + 间隔重复复习 App。Swift 6.2 + SwiftUI + SwiftData，iOS 26.0+。
详见 `architecture.md`（包结构、依赖图、DI 链路）。

## 架构决策

记录在 `architecture.md`（关键设计决策表）和 `principles.md`（决策理由和重新评估条件）。
已记录的决策不得在未经用户批准的情况下推翻。
