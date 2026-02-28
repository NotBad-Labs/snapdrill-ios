# ADR 0003: 统一项目的 iOS 目标版本下限为 iOS 17.0

> [!CAUTION]
> **已废弃 (Superseded)**: 此决策已由 [ADR 0005](file:///Users/yiming/Developer/snapdrill-ios/docs/adr/0005-unify-minimum-ios-version-to-18-0.md) 取代，最低部署目标已提升至 iOS 18.0。

**日期**: 2026-02-25
**状态**: ~~Accepted~~ → **Superseded by [ADR 0005](0005-unify-minimum-ios-version-to-18-0.md)**

## 1. 背景 (Context)

经审计，项目的全局配置文件中，iOS 支持版本宣示存在多处矛盾：

- `.github/copilot-instructions.md` 要求最低版本：iOS 18.0
- `copilot_rules_full.md` 要求最低 UI 框架：SwiftUI (仅限 iOS 17.0+)

这种“法理打架”会导致 Copilot 或 AI Agent 在调用最新平台 API 时产生幻觉和编译失败。由于本项目极度依赖 Swift 5.9 配合 iOS 17.0 推出的宏技术（特别是 `@Observable` 以及 SwiftData），iOS 17 是业务运作的绝对物理底线。

## 2. 决策 (Decision)

将所有文件中关于项目基础版本的描述**统一降级/对齐为 iOS 17.0**。
虽然 iOS 18 具有更好的过渡动画等特性，但为了兼顾潜在的商业下沉市场，17.0 是目前拥有 `@Observable` 等现代框架的最佳下限平衡点。

## 3. 后果 (Consequences)

- 修改 `.github/copilot-instructions.md` 中的版本号要求。
- 未来的 API 使用必须首先考虑其在 iOS 17 的兼容性，必要时通过 `#available(iOS 18.0, *)` 进行包装，而不能直接抛弃 iOS 17 用户。
