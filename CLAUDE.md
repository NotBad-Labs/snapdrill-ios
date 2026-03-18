# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 启动时强制加载（每次对话第一步，无例外）

**必须**在回复用户第一条消息前，按顺序读取以下文件恢复上下文：
1. `STATUS.md` — 项目当前状态快照（什么在进行中、下一步是什么）
2. `.claude/session-log.md` — 最近 3 条工作日志（上次做了什么、决策了什么、下次接续什么）

读完后向用户简要确认当前状态，再开始工作。跳过此步骤 = 失忆 = 重复劳动。

@.claude/product-vision.md
@.claude/product-requirements.md
@.claude/product-journeys.md
@.claude/product-business.md
@.claude/principles.md
@.claude/architecture.md
@.claude/workflow.md
@.claude/conventions.md
@.claude/infrastructure.md

## Commands

**Build & Run**
Open `SnapDrill.xcodeproj` in Xcode 26.0+ (current env: Xcode 26.3), select the `SnapDrill` scheme, and run on an iOS 26 simulator or physical device (primary test device: iPhone 17).

**Lint**
```bash
swiftlint --strict             # Run from repo root; config is .swiftlint.yml
bash Scripts/lint.sh          # Wrapper that checks if swiftlint is installed first
```

**Test (all — main app targets only)**
```bash
xcodebuild test -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17'
```

**Test (SPM package — macOS, no UIKit)**
```bash
# 在各包目录下运行，不依赖 Xcode
cd Packages/SnapDrillCore && swift test   # UIKit 测试自动跳过
cd Packages/SnapDrillData && swift test   # SwiftData Predicate 测试跳过（需 Xcode）
```

**Test (UIKit 依赖 / SnapDrillFeatures)**
必须通过 Xcode GUI 运行（`swift test` 不支持 UIKit 依赖，`-only-testing:SnapDrillFeaturesTests` 命令无效）。

**注意**：`xcodebuild build` 不编译测试 target，测试编译错误须通过 `swift test` 或 Xcode 才能发现。

**Install SwiftLint (required)**
```bash
brew install swiftlint
```

## Architecture

SnapDrill is a question archiving and spaced-repetition review app for students and parents, built with Swift 6.2 + SwiftUI + SwiftData, targeting iOS 26.0+.

详见 `.claude/architecture.md`（包结构、依赖图、DI 链路、Feature 结构、数据流）。

## Architecture Decision Records

修改架构前必须先查 `.claude/decisions/` 目录，确认是否有相关 ADR。已记录的决策经过深思熟虑，不得在未经用户批准的情况下推翻。

**何时创建新 ADR**：
- 新增或删除 SPM 包
- 引入或移除第三方依赖
- 改变数据流方向（如新增跨包依赖）
- 改变 DI 模式或测试策略
- 选择或替换核心框架（持久化、网络、AI 等）

新增架构决策时须同步创建 ADR，并更新 `decisions/README.md` 索引。

## 编写代码前强制研究声明

详见 `.claude/principles.md`「决策前研究铁律」（含研究流程、判断框架、输出格式）。
用户质量检查触发词：「铁律？」

## Glossary（术语对照表）

核心概念、协议职责边界、算法术语见 `.claude/glossary.md`。
概念的含义和职责看术语表，API 签名和调用方式看 `infrastructure.md`。

## API 使用强制规则

详见 `.claude/infrastructure.md` 顶部「使用规则」。
修改任何代码前必须先确认 API 真实存在，禁止凭名称推测。
新增 API 时：写完后同步更新 `.claude/infrastructure.md`。

## Key Conventions

详见 `.claude/conventions.md`（并发规则、View 层约束、日志/错误处理/MARK 顺序/文件头/注释、禁止事项）。

## Technical Debt Ledger

架构级技术债汇总见 `.claude/technical-debt-ledger.md`。
日常技术债用 GitHub Issue + `tech-debt` label 追踪。
引入有决策上下文的临时方案时，须同步更新 Ledger。

## Definition of Done

PR 合并前必须对照 `.claude/definition-of-done.md` 逐项自检。涉及用户可见功能的 PR 还需满足功能级 DoD。

## Workflow

详见 `.claude/workflow.md`（Git 工作流、Code Review 三方流程、工作优先级框架 S0-S3、角色换帽制度）。
