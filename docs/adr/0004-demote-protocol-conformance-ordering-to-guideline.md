# ADR 0004: 将协议声明顺序从“强制红线”降级为“推荐指南”

**日期**: 2026-02-25
**状态**: ✅ Accepted

## 1. 背景 (Context)

在 `swift6_rules_full.md` 中，第 7 条规定了一套记忆口诀为 `"Send Case Code Hash ID"` (`Sendable, CaseIterable, Codable, Hashable, Identifiable`) 的严格协议遵循排列顺序。虽然它致力于保持代码库外观的高度一致，但将它作为“AI 约束铁律”会在实际操作中导致过多的冗余打回（而且对于 Swift 编译器本身并无任何内存或执行期优化意义）。

## 2. 决策 (Decision)

**将“统一协议顺序”从违规立刻报错的禁令（Rule）降级为最佳实践指导（Guideline）**。
我们鼓励开发者和 Copilot 继续以此为美观标准，但不允许静态检查（Lint）或代码审查仅仅因为打乱了这个次序而拒绝合并 PR。

## 3. 后果 (Consequences)

- 减轻了初级学徒和 AI 工具不必要的心智压力和生成失败率。
- 修改 `swift6_rules_full.md` 中的语序，去除“铁血要求”字眼，改为“推荐使用”。
