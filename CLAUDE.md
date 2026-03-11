# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@.claude/product.md
@.claude/principles.md
@.claude/architecture.md
@.claude/refactoring-plan.md
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

## 编写代码前强制研究声明

详见 `.claude/principles.md`「决策前研究铁律」（含研究流程、判断框架、输出格式）。
用户质量检查触发词：「铁律？」

## API 使用强制规则

详见 `.claude/infrastructure.md` 顶部「使用规则」。
修改任何代码前必须先确认 API 真实存在，禁止凭名称推测。
新增 API 时：写完后同步更新 `.claude/infrastructure.md`。

## Key Conventions

详见 `.claude/principles.md` 以下章节：
- **并发规则** — Swift 6 strict concurrency、ViewModel 模式、Task 句柄
- **编码规范** — 日志、错误处理、MARK 顺序、文件头、注释语言、孤儿功能禁止
- **禁止事项** — `@unchecked Sendable`、force unwrap、`any` existentials 例外等
